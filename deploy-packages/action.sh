#!/bin/bash
set -e
ls -lR

# trap 'catch $? $LINENO' EXIT
# catch() {
#   local SLACKAPI="https://ropensci.slack.com/api/chat.postMessage"
#   local RUNURL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"
#   if [ "$1" != "0" ]; then
#     local STATUS=FAIL
#   else
#     local STATUS=OK
#     return # only post failures now
#   fi
#   echo "::group::Post status to slack"
#   curl -sS $SLACKAPI -d "text=Deploy $STATUS: $RUNURL" -d "channel=deployments" -H "Authorization: Bearer $SLACK_TOKEN"
#   echo "::endgroup::"
# }

# Submit system failures as well, such that they get retried
if [ ! -d "package-source" ]; then
echo "No source package exists? Could be a systsem failure in GitHub Actions."
TARGET=failure ${GITHUB_ACTION_PATH}/deploy.sh
exit 1
fi

# Upload source first
mv package-source package-00source

for dir in package-*; do
  echo "::group::DEPLOYING ${dir}"
  (cd "${dir}"; eval $(cat pkgdata.txt) ${GITHUB_ACTION_PATH}/deploy.sh) || FAILURE=1
  echo "::endgroup::"
done

mv package-00source package-source

DEPLOYED_PACKAGES=$(echo package-*)
echo "DEPLOYED_PACKAGES: ${DEPLOYED_PACKAGES}"
echo "deployed_packages=${DEPLOYED_PACKAGES}" >> $GITHUB_OUTPUT

if [ "$FAILURE" ]; then
  exit 1
else
  exit 0
fi
