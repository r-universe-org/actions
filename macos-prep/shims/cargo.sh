#!/bin/bash
TEMP_CARGO_CONFIG="${CARGO_HOME:-$HOME/.cargo}/config.toml"
if [ -f "$TEMP_CARGO_CONFIG" ] && grep -qF '[build]' "$TEMP_CARGO_CONFIG"; then
sed -i.bak '/^target = .*/d' "$TEMP_CARGO_CONFIG"
sed -i.bak '/\[build\]/s/.*/&\
target = "aarch64-apple-darwin"/' "$TEMP_CARGO_CONFIG"
cat "$TEMP_CARGO_CONFIG"
else
mkdir -p $(dirname "${TEMP_CARGO_CONFIG}")
echo '[build]' >> "${TEMP_CARGO_CONFIG}"
echo 'target = "aarch64-apple-darwin"' >> "${TEMP_CARGO_CONFIG}"
fi

# Call real cargo
"$HOME/.cargo/bin/cargo" "$@"

# I could not get build.target-dir to do the right thing
if [ "$1" = "build" ];then
targetdir=$(find . -path '*target/aarch64-apple-darwin')
if [ "$targetdir" ]; then
  echo "targetdir: $targetdir"
  #(cd $(dirname $targetdir); ln -sfv aarch64-apple-darwin/* .) || true
  cp -Rf $targetdir/* $(dirname $targetdir)
fi
fi
