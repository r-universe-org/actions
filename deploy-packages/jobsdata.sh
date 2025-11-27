#!/bin/bash

# Script should error when any of these steps fails
set -euo pipefail

save_jobs_data(){
  echo "::group::getting jobs info"
  ENDPOINT="/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs"
  echo "Getting $ENDPOINT"
  jq --version
  gh api "$ENDPOINT" | jq '.jobs' > input.json
  missingsteps=$(cat input.json | jq -r '[.[] | select(.conclusion != "skipped").steps | length ] | min')
  if [ -z "$missingsteps" ] || [ "$missingsteps" = "0" ]; then
    echo "Some jobs have missing steps. Falling back on getting all old jobsdata"
    gh api --paginate --slurp "$ENDPOINT?filter=all&per_page=100" | jq '[.[].jobs[]]' > input.json
    if [ $? -ne 0 ]; then
      echo "GitHub API failure retrieving logs. Might need full rebuild."
      exit 1
    fi
  else
    echo "Jobs data from API seems complete"
  fi
  cat input.json | jq -r '[.[] | {id, started_at, completed_at, result: .steps[] | select((.name | startswith("Conclude:")) and .conclusion != "cancelled").name | split(": ") } | {job: .id, time: ((.completed_at | fromdate) - (.started_at | fromdate)), config: .result[1], r: .result[2], check: .result[3], artifact: .result[4]}] | sort_by(-.job) | unique_by(.config)' | tee jobsdata.json
  echo "::endgroup::"

  # Only succeed if file is non empty
  if [ -s "jobsdata.json" ] && [ $(cat jobsdata.json | jq -r 'length') != "0" ]; then
    echo "Converting jobsdata.json to base64-json..."
    cat jobsdata.json | gzip | openssl base64 -A -out jobsdata.txt
    echo "jobdata=$(cat jobsdata.txt)" >> $GITHUB_OUTPUT
    exit 0
  else
    return 1
  fi
}

# Sometimes this randomly fails. Retry 3 times.
for x in 60 300 600 0; do
  save_jobs_data "$x" || echo "Something went wrong. Waiting $x seconds to retry..."
  sleep $x
done

echo "Failed to get jobs data from API"
exit 1
