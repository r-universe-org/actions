#!/bin/bash
if [ "$UNIVERSE" == "cran" ] || [ "$UNIVERSE" == "bioc" ] || [ "$UNIVERSE" == "bioc-release" ]; then
echo "Skipping version bump check for cran/bioc repos."
exit 0
fi

OLDVERSION=$(curl -sSf "https://${UNIVERSE}.r-universe.dev/api/packages/${PACKAGE}" | jq -r '.Version')
if [ "$OLDVERSION" ] && [ "$VERSION" ] && [ "$OLDVERSION" != "$VERSION" ]; then
  echo "version_change=true" >> $GITHUB_OUTPUT
  echo "### Version bump!" | tee -a $GITHUB_STEP_SUMMARY
  echo "Version changed from $OLDVERSION to $VERSION" | tee -a $GITHUB_STEP_SUMMARY
else
  echo "Version $VERSION has not changed."
fi

exit 0
