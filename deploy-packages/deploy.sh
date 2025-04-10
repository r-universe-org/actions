#!/bin/bash
set -e

# Temporary solution to not reupload old source packges
# TODO: actually compare $STOREDATE to date here
if [ -z "$STOREDATE" ]; then
	echo "Skipping redeploy of old file"; exit 0
fi

if [ -z "$COMMITINFO" ]; then
	echo "Missing COMMITINFO"; exit 1
fi
if [ -z "$MAINTAINERINFO" ]; then
	echo "Missing MAINTAINERINFO"; exit 1
fi
if [ -z "$UNIVERSE_NAME" ]; then
	echo "Missing UNIVERSE_NAME"; exit 1
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

SERVERURL="https://${UNIVERSE_NAME}.r-universe.dev/api/packages/${PACKAGE}/${VERSION}/${PKGTYPE}"

#FORCE_SERVER_IP="--resolve *:443:68.183.102.165"

if [ "$PKGTYPE" == "failure" ]; then
  echo "Posting a build-failure for $PACKAGE to the package server!"
  echo "MAINTAINERINFO: $MAINTAINERINFO"
	curl $FORCE_SERVER_IP --max-time 60 --retry 3 -vL --fail-with-body -u "${CRANLIKEPWD}" \
		-d "Builder-Upstream=${REPO_URL}" \
		-d "Builder-Registered=${REPO_REGISTERED}" \
		-d "Builder-Commit=${COMMITINFO}" \
		-d "Builder-Maintainer=${MAINTAINERINFO}" \
		-d "Builder-Distro=${DISTRO}" \
		-d "Builder-Host=GitHub-Actions" \
		-d "Builder-Buildurl=https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" \
		"${SERVERURL}"
	exit 0;
fi

if [ -f "$FILE" ]; then
	SHASUM=$(openssl dgst -sha256 $FILE | awk '{print $2}')
	echo "Deploying: $FILE with sha: $SHASUM"
else
	echo "ERROR: file $FILE not found!"
	exit 1
fi

# Add status for binaries to source deploy
if [ "$PKGTYPE" == "src" ]; then

if [ -d "../package-macos-release" ]; then
MACOS_BINARY_STATUS=$(cd ../package-macos-release; (source pkgdata.txt; echo "$JOB_STATUS")) # no longer used
elif [ -d "../package-macos-release-arm64" ]; then
MACOS_BINARY_STATUS=$(cd ../package-macos-release-arm64; (source pkgdata.txt; echo "$JOB_STATUS"))
elif [ -d "../package-macos-release-x86_64" ]; then
MACOS_BINARY_STATUS="arm64-failure"
elif [ "$SKIP_BINARIES" ]; then
MACOS_BINARY_STATUS="skipped"
else
MACOS_BINARY_STATUS="none"
fi

if [ -d "../package-windows-devel" ]; then
WINDOWS_DEVEL_STATUS=$(cd ../package-windows-devel; (source pkgdata.txt; echo "$JOB_STATUS"))
elif [ "$SKIP_BINARIES" ]; then
WINDOWS_DEVEL_STATUS="skipped"
else
WINDOWS_DEVEL_STATUS="none"
fi

if [ -d "../package-windows-release" ]; then
WINDOWS_BINARY_STATUS=$(cd ../package-windows-release; (source pkgdata.txt; echo "$JOB_STATUS"))
elif [ "$SKIP_BINARIES" ]; then
WINDOWS_BINARY_STATUS="skipped"
else
WINDOWS_BINARY_STATUS="none"
fi

if [ -d "../package-linux-devel" ]; then
LINUX_DEVEL_STATUS=$(cd ../package-linux-devel; (source pkgdata.txt; echo "$JOB_STATUS"))
else
LINUX_DEVEL_STATUS="none"
fi

if [ -d "../package-wasm-release" ]; then
WASM_BINARY_STATUS=$(cd ../package-wasm-release; (source pkgdata.txt; echo "$JOB_STATUS"))
else
WASM_BINARY_STATUS="none"
fi

fi

upload_package_file(){
	echo "Submitting ${SERVERURL}/${SHASUM}"
	curl $FORCE_SERVER_IP --max-time 60 --retry 3 -L --upload-file "${FILE}" --fail-with-body -u "${CRANLIKEPWD}" \
		-H "Builder-Upstream: ${REPO_URL}" \
		-H "Builder-Registered: ${REPO_REGISTERED}" \
		-H "Builder-Commit: ${COMMITINFO}" \
		-H "Builder-Maintainer: ${MAINTAINERINFO}" \
		-H "Builder-Distro: ${DISTRO}" \
		-H "Builder-Host: GitHub-Actions" \
		-H "Builder-Status: ${JOB_STATUS}" \
		-H "Builder-Check: ${CHECKSTATUS}" \
		-H "Builder-Pkgdocs: ${PKGDOCS}" \
		-H "Builder-Srconly: ${SKIP_BINARIES}" \
		-H "Builder-Winbinary: ${WINDOWS_BINARY_STATUS}" \
		-H "Builder-Macbinary: ${MACOS_BINARY_STATUS}" \
		-H "Builder-Wasmbinary: ${WASM_BINARY_STATUS}" \
		-H "Builder-Linuxdevel: ${LINUX_DEVEL_STATUS}" \
		-H "Builder-Windevel: ${WINDOWS_DEVEL_STATUS}" \
		-H "Builder-Buildurl: https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" \
		-H 'Expect:' \
		"${SERVERURL}/${SHASUM}" &&\
  echo " === Complete! === " &&\
  exit 0
}

# Sometimes deploys randomly drop a connection (server restart?)
# Retry 3 times (curl --retry does not always work)
for x in 1 2 3; do
	upload_package_file || echo "Something went wrong. Waiting 10 seconds to retry..."
	sleep 10
done

echo "Package deploy failed"
exit 1
