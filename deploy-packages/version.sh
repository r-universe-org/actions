#!/bin/bash
if [ "$UNIVERSE_NAME" == "cran" ] || [ "$UNIVERSE_NAME" == "bioc" ] || [ "$UNIVERSE_NAME" == "bioc-release" ]; then
echo "Skipping version bump check for cran/bioc repos."
exit 0
fi

OLDVERSION=$(curl -sSf "https://${UNIVERSE_NAME}.r-universe.dev/api/packages/${PACKAGE}" | jq -r '.Version')
if [ "$OLDVERSION" ] && [ "$OLDVERSION" != "$VERSION" ]; then
  echo "Version change from $OLDVERSION to $VERSION"
  echo "version_change=true" >> $GITHUB_OUTPUT
else
  echo "Version $VERSION has not changed."
fi

exit 0
