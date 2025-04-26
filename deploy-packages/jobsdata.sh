#!/bin/bash

# Script should error when any of these steps fails
set -euo pipefail

# We get some info from the API about build/check matrix jobs
# The jq query will probably fail if the GH API changes at some point.
# The most important information to keep is job config and check result.
echo "::group::getting jobs info"
jq --version
curl --retry 3 -s -D /dev/stderr -H "Authorization: token ${GITHUB_TOKEN}" --fail "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs" | \
  jq -r '[.jobs[] | {id, started_at, completed_at, result: .steps[] | select(.name | startswith("Conclude:")).name | split(": ") } | {job: .id, time: ((.completed_at | fromdate) - (.started_at | fromdate)), config: .result[1], r: .result[2], check: .result[3]}]' |
  gzip | openssl base64 -A -out jobsdata.txt
echo "::endgroup::"
