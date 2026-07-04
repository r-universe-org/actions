#!/bin/bash
set -e

# Uploads the package file to the Cloudflare R2 and then reports the public
# download URL to r-universe.
R2_PUBLIC_URL="https://r2.ropensci.org"
R2_ENDPOINT="https://3fcdf4a2e34a7a2e74fc8686b68acea1.r2.cloudflarestorage.com"
R2_BUCKET="r-universe-cdn"

# R2 credentials are read from envvars by the aws cli
export AWS_DEFAULT_REGION="auto" # required by s3 client
if [ "${#AWS_SECRET_ACCESS_KEY}" != "64" ]; then
	echo "ERROR: missing R2 AWS credentials"; exit 1
fi

# Skip re-uploading of binaries more than 3 days old
#CUTDATE=$(date -d "2 days ago" '+%Y%m%d')
#if [ "${TARGET}" != "source" ] && [ "$STOREDATE" -lt "$CUTDATE" ]; then
#	echo "Skipping redeploy of old binary"; exit 0
#fi

if [ -z "$COMMITINFO" ]; then
	echo "Missing COMMITINFO"; exit 1
fi
if [ -z "$MAINTAINERINFO" ]; then
	echo "Missing MAINTAINERINFO"; exit 1
fi
if [ -z "$UNIVERSE" ]; then
	echo "Missing UNIVERSE"; exit 1
fi

# What are we deploying
case "${TARGET}" in
"source")
	PKGTYPE="src"
	;;
"win"*)
	PKGTYPE="win"
	;;
"mac"*)
	PKGTYPE="mac"
	;;
"linux"*)
	PKGTYPE="linux"
	;;
"wasm")
	PKGTYPE="wasm"
	;;
"failure")
	PKGTYPE="failure"
	;;
*)
	echo "Unexpected target: $TARGET"
	exit 1
	;;
esac

# Add jobs metadata to source/fail deploys
if [ "$PKGTYPE" = "src" ] || [ "$PKGTYPE" = "failure" ]; then
BIOCDATA="$BIOC_CHECKS"
JOBSDATA=$(cat ../jobsdata.txt)
fi

SERVERURL="https://${UNIVERSE}.r-universe.dev/api/packages/${PACKAGE}/${VERSION}/${PKGTYPE}"

#FORCE_SERVER_IP="--resolve *:443:165.227.211.221"

# Build failures carry no file, so they are always posted to the server directly.
if [ "$PKGTYPE" == "failure" ]; then
  echo "Posting a build-failure for $PACKAGE to the package server!"
  echo "MAINTAINERINFO: $MAINTAINERINFO"
	curl $FORCE_SERVER_IP --max-time 60 --retry 3 -vL --fail-with-body -u "${CRANLIKEPWD}" \
		--data-urlencode "Builder-Upstream=${UPSTREAM}" \
		--data-urlencode "Builder-Registered=${REGISTERED}" \
		--data-urlencode "Builder-Commit=${COMMITINFO}" \
		--data-urlencode "Builder-Maintainer=${MAINTAINERINFO}" \
		--data-urlencode "Builder-Distro=${DISTRO}" \
		--data-urlencode "Builder-Jobs=${JOBSDATA}" \
		--data-urlencode "Builder-Host=GitHub-Actions" \
		--data-urlencode "Builder-Buildurl=https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" \
		"${SERVERURL}"
	echo "DEPLOY=OK" >> pkgdata.txt
	exit 0;
fi

if [ -f "$FILE" ]; then
	SHASUM=$(openssl dgst -sha256 $FILE | awk '{print $2}')
	DOWNLOADURL="${R2_PUBLIC_URL}/${SHASUM}"
	echo "Deploying: $FILE with sha: $SHASUM"
else
	echo "ERROR: file $FILE not found!"
	exit 1
fi

# We only use zip/tgz for now
case "$FILE" in
	*.zst) CONTENT_TYPE="application/zstd" ;;
	*.zip) CONTENT_TYPE="application/zip" ;;
	*)     CONTENT_TYPE="application/gzip" ;;
esac

# Upload the file to the R2 bucket, unless an object with this key already
# exists (e.g. on a rerun). The object key is the sha256 so the public URL
# becomes ${R2_PUBLIC_URL}/${SHASUM}. Returns non-zero on failure so the retry
# loop below can try again after a transient R2/network error.
upload_to_r2(){
	if R2_RESPONSE=$(aws s3api head-object \
		--endpoint-url "${R2_ENDPOINT}" \
		--bucket "${R2_BUCKET}" \
		--key "${SHASUM}" \
		--output json 2>/dev/null); then
		echo "Object ${SHASUM} already exists in R2, skipping upload"
	else
		echo "Uploading ${FILE} to R2 bucket '${R2_BUCKET}' with key ${SHASUM}"
		R2_RESPONSE=$(aws s3api put-object \
			--endpoint-url "${R2_ENDPOINT}" \
			--bucket "${R2_BUCKET}" \
			--key "${SHASUM}" \
			--body "${FILE}" \
			--content-type "${CONTENT_TYPE}" \
			--content-disposition "attachment; filename=\"${FILE}\"" \
			--cache-control "public, max-age=31536000, immutable" \
			--metadata "universe=${UNIVERSE},pkgtype=${PKGTYPE},file=${FILE},runid=${GITHUB_RUN_ID}" \
			--output json) || { echo "ERROR: failed to upload ${FILE} to R2"; return 1; }
		echo "Uploaded to CDN: ${SHASUM}"
		sleep 1
	fi

	# Both head-object and put-object return the lifecycle expiration (if any) in
	# the 'Expiration' field as: expiry-date="<rfc1123 date>", rule-id="<id>".
	# Extract just the date string (e.g. "Thu, 08 Oct 2026 12:44:32 GMT") and
	# report it to the r-universe server; the actual date is parsed on that end.
	EXPIRATION=$(echo "$R2_RESPONSE" | jq -r '.Expiration // empty' | sed -n 's/.*expiry-date="\([^"]*\)".*/\1/p')
	if [ -z "$EXPIRATION" ]; then
		echo "Upload OK but failed to get expiration. Something wrong."
		exit 1
	fi

	# VERIFY that file public now
	# R2 sometimes gives HTTP 520 while it is processing a fresh upload.
	SHACDN=$(curl --no-progress-meter --max-time 30 --retry 3 --retry-delay 5 --retry-all-errors --fail-with-body "$DOWNLOADURL" | openssl dgst -sha256 |  awk '{print $2}')
	if [ "$SHACDN" = "$SHASUM" ]; then
		echo "CDN file OK: $DOWNLOADURL"
	else
		echo "File not (yet) found on $DOWNLOADURL"
		return 1
	fi
}

upload_package_file(){
	echo "Submitting ${SERVERURL}/${SHASUM}"
	echo "Expires: $EXPIRATION"
	curl $FORCE_SERVER_IP --max-time 60 --retry 3 --retry-delay 30 -L --fail-with-body -u "${CRANLIKEPWD}" \
		-X PUT --data-urlencode "downloadurl=${DOWNLOADURL}" --data-urlencode "expires=${EXPIRATION}" \
		-H "Builder-Upstream: ${UPSTREAM}" \
		-H "Builder-Registered: ${REGISTERED}" \
		-H "Builder-Commit: ${COMMITINFO}" \
		-H "Builder-Maintainer: ${MAINTAINERINFO}" \
		-H "Builder-Distro: ${DISTRO}" \
		-H "Builder-Jobs: ${JOBSDATA}" \
		-H "Builder-Bioccheck: ${BIOCDATA}" \
		-H "Builder-Host: GitHub-Actions" \
		-H "Builder-Status: ${JOB_STATUS}" \
		-H "Builder-Check: ${CHECKSTATUS}" \
		-H "Builder-Buildurl: https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" \
		-H 'Expect:' \
		"${SERVERURL}/${SHASUM}" &&\
  echo " === Complete! === " &&\
  echo "DEPLOY=OK" >> pkgdata.txt &&\
  exit 0
}

# Sometimes the R2 upload or the server deploy randomly drops a connection
# (server restart?). Retry a few times (curl --retry does not always work).
# upload_to_r2 skips the upload when the object is already present, so retries
# after a partial failure are cheap.
for x in 30 60 150 0; do
	upload_to_r2 && upload_package_file || echo "Something went wrong. Waiting $x seconds to retry..."
	sleep $x
done

echo "Package deploy failed"
echo "DEPLOY=FAIL" >> pkgdata.txt
exit 1
