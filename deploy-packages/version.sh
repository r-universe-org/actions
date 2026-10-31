#!/bin/bash
if [ "$UNIVERSE" == "cran" ]; then
echo "Skipping version bump check for cran repos."
exit 0
fi

# For S4 it might be needed that revdeps of revdeps also get rebuilt hence skip version req
# Version bumps are meaningless in bioconductor anyway but we use abitools to find breakage
if [ "${UNIVERSE:0:4}" = "bioc" ]; then
echo "version_change=true" >> $GITHUB_OUTPUT
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
