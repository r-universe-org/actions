#!/bin/sh
set -e

# This script allows inserting some custom variables

# Sanity check
if [ -z "$PACKAGE" ] || [ -z "$UNIVERSE" ]; then
echo "Something is wrong"
exit 1
fi

# Determine CRAN_VERSION
if [ -f ".config.json" ]; then
  CRAN_VERSION=$(jq -r '.cran_version // empty' .config.json)
  if [ "$CRAN_VERSION" ]; then
    echo "Found config.json with cran_version $CRAN_VERSION"
    echo "CRAN_VERSION=$CRAN_VERSION" | tee -a $GITHUB_OUTPUT
  fi
fi

# Check for metadata in registry
if [ -f ".metadata.json" ]; then
  METADATA=$(jq -r ".[] | select(.package == \"${PACKAGE}\") | .metadata | tostring" .metadata.json | head -n1)
  if [ "$METADATA" ] && [ "$METADATA" != "null" ]; then
    echo "Found package metadata: $METADATA"
    echo "REGISTRY_METADATA=$METADATA" | tee -a $GITHUB_OUTPUT
  fi
fi

# Get maintainer metadata
gh api "/repos/${GITHUB_REPOSITORY}/commits?path=$PACKAGE" | jq '.[0]' > commit.json || APIFAIL=true
if [ "$APIFAIL" ]; then
  echo "GitHub API call failed (probably very old commit). Falling back on fetching monorepo..."
  git fetch --unshallow
  COMMIT_ID=$(git log -n 1 --pretty=format:%H -- ${PACKAGE})
  gh api "/repos/${GITHUB_REPOSITORY}/commits/${COMMIT_ID}" > commit.json
fi
MAINTAINERLOGIN=$(jq -r '.author.login' commit.json)
MAINTAINERUUID=$(jq -r '.author.id' commit.json)
if [ "$MAINTAINERLOGIN" ] && [ "$MAINTAINERLOGIN" != "null" ]; then
  echo "Package maintainer github login: $MAINTAINERLOGIN ($MAINTAINERUUID)"
  echo "MAINTAINERLOGIN=$MAINTAINERLOGIN" | tee -a $GITHUB_OUTPUT
  echo "MAINTAINERUUID=$MAINTAINERUUID" | tee -a $GITHUB_OUTPUT
else
  echo "No GitHub user found for https://api.github.com/repos/${GITHUB_REPOSITORY}/commits?path=$PACKAGE"
fi
rm -f commit.json

# If package is remote do not build vignettes
if [ "$REGISTERED" = "false" ]; then
echo "SKIP_VIGNETTES=true" | tee -a $GITHUB_OUTPUT
fi

# Propagate name of upstream tracking branch
UPSTREAMBRANCH=$(git config -f .gitmodules --get "submodule.${PACKAGE}.branch" || true)
echo "UPSTREAMBRANCH=$UPSTREAMBRANCH" | tee -a $GITHUB_OUTPUT

# This requires a GitHub session token...
if [ "$DUMMY_SESSION" ] && [ "$REGISTERED" != "false" ]; then
  echo "Looking up blackbird count..."
  ENDPOINT="https://github.com/search/blackbird_count?saved_searches=&q=%22library%28${PACKAGE}%29%22"
  AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
  curl -sS --cookie-jar "cookies.txt" -A "$AGENT" --cookie "user_session=$DUMMY_SESSION" -H "Accept: text/html" "https://github.com" -o /dev/null
  COUNT=$(curl -sSf --cookie-jar "cookies.txt" -A "$AGENT" --cookie "user_session=$DUMMY_SESSION" -H "Accept: application/json" $ENDPOINT | jq '.count' || true)
  if [ "$COUNT" ] && [ "$COUNT" != "null" ]; then
    echo "BLACKBIRD_COUNT=$COUNT" | tee -a $GITHUB_OUTPUT
  fi
fi
