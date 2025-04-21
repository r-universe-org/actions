#!/bin/bash

# Script should error when any of these steps fails
set -euo pipefail

echo "::group::getting jobs info"
curl -s -D /dev/stderr -H "Authorization: token ${GITHUB_TOKEN}" --fail "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs" | \
  jq -r '[.jobs[] | {job: .id, result: .steps[] | select(.name | startswith("Set:")).name | split(": ") } | {job, config: .result[1], r: .result[2], check: .result[3]}]' |
  gzip | openssl base64 -A -out jobsdata.txt
echo "::endgroup::"