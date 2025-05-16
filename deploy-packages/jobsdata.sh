#!/bin/bash

# Script should error when any of these steps fails
set -euo pipefail

save_jobs_data(){
  echo "::group::getting jobs info $1"
  ENDPOINT="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs"
  echo "Getting $ENDPOINT"
  jq --version
  curl --retry 3 -s -D /dev/stderr -H "Authorization: token ${GITHUB_TOKEN}" --fail $ENDPOINT | \
    jq -r '[.jobs[] | {id, started_at, completed_at, result: .steps[] | select((.name | startswith("Conclude:")) and .conclusion != "cancelled").name | split(": ") } | {job: .id, time: ((.completed_at | fromdate) - (.started_at | fromdate)), config: .result[1], r: .result[2], check: .result[3]}]' | tee jobsdata.json
  echo "::endgroup::"

  # Only succeed if file is non empty
  if [ -s "jobsdata.json" ]; then
    echo "Converting jobsdata.json to base64-json..."
    cat jobsdata.json | gzip | openssl base64 -A -out jobsdata.txt
    exit 0
  else
    return 1
  fi
}

# Sometimes this randomly fails. Retry 3 times.
for x in 1 2 3; do
  save_jobs_data "$x" || echo "Something went wrong. Waiting 30 seconds to retry..."
  sleep 30
done

echo "Failed to get jobs data from API"
exit 1
