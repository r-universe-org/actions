#!/bin/sh
set -e

# Sanity check
if [ "$GITHUB_REPOSITORY_OWNER" != "r-universe" ]; then
echo "This action should only run under the official r-universe account"
exit 1
fi

# Find package name
if [ "$1" ]; then
  PACKAGE="$1"
else
  PACKAGE=$(git log --pretty=format: --name-only HEAD^.. | grep "^[^.]")
fi

# Need to initiate
echo "Building package: ${PACKAGE} in: https://github.com/${GITHUB_REPOSITORY}"
git submodule init ${PACKAGE}

# Determine universe
UNIVERSE="$(basename $GITHUB_REPOSITORY)"
REPOSITORY=$(git config --list | grep "submodule.${PACKAGE}.url=" | cut -d'=' -f2)
REF=$(git submodule status $PACKAGE | awk '{print $1}' | sed 's/^[^0-9a-z]*//')
SUBDIR=$(git config -f .gitmodules --get "submodule.${PACKAGE}.subdir" || true)
if [ "$GITHUB_REPOSITORY" = "r-universe/cran" ]; then
NOBINARIES="true"
fi

# Check for remotes
REGISTERED=$(git config -f .gitmodules --get "submodule.${PACKAGE}.registered" || true)

# Custom organization hooks
if [ "$REGISTERED" != "false" ]; then
ORGANIZATION="$UNIVERSE"
if [ "$ORGANIZATION" = "bioc-release" ] || [ "$ORGANIZATION" = "bioc" ] || [ "$ORGANIZATION" = "tempbioc" ]; then
ORGANIZATION="bioconductor"
fi
if [ "$ORGANIZATION" = "r-multiverse" ]; then
ORGANIZATION="r-multiverse"
fi
fi

# Check if we have the app
if [ -f ".ghapp" ] && [ "$(dirname $REPOSITORY)" = "https://github.com/$UNIVERSE" ]; then
  cat .ghapp
  if jq -e '.repository_selection == "all"' .ghapp; then
    HASAPP="true"
  elif jq -e ".repositories|any(. == \"${PACKAGE}\")" .ghapp; then
    HASAPP="true"
  else
    echo "GitHub app does not have permission for: ${PACKAGE}"
  fi
fi

# Export settings
echo "package=$PACKAGE" | tee -a $GITHUB_OUTPUT
echo "universe=$UNIVERSE" | tee -a $GITHUB_OUTPUT
echo "repository=$REPOSITORY" | tee -a $GITHUB_OUTPUT
echo "subdir=$SUBDIR" | tee -a $GITHUB_OUTPUT
echo "ref=$REF" | tee -a $GITHUB_OUTPUT
echo "nobinaries=$NOBINARIES" | tee -a $GITHUB_OUTPUT
echo "organization=$ORGANIZATION" | tee -a $GITHUB_OUTPUT
echo "registered=$REGISTERED" | tee -a $GITHUB_OUTPUT
echo "hasapp=$HASAPP" | tee -a $GITHUB_OUTPUT

# Pass down to next script
echo "PACKAGE=$PACKAGE" >> $GITHUB_ENV
echo "UNIVERSE=$UNIVERSE" >> $GITHUB_ENV
echo "REPOSITORY=$REPOSITORY" >> $GITHUB_ENV
echo "REGISTERED=$REGISTERED" >> $GITHUB_ENV
