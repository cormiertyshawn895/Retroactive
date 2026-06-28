#!/bin/bash
set -e
cd "$(dirname "$0")"
OUT=../../Support/iLifeMediaBrowserShim
rm -rf "$OUT"
mkdir -p "$OUT/Versions/A"
clang -arch x86_64 -dynamiclib iLifeMediaBrowser.m \
  -framework Foundation -F /System/Library/PrivateFrameworks \
  -Xlinker -reexport_framework -Xlinker iLifeMediaBrowser \
  -install_name @executable_path/../Frameworks/iLifeMediaBrowser.framework/Versions/A/iLifeMediaBrowser \
  -o "$OUT/Versions/A/iLifeMediaBrowser"
ln -sf A "$OUT/Versions/Current"
ln -sf Versions/Current/iLifeMediaBrowser "$OUT/iLifeMediaBrowser"
codesign -fs - "$OUT/Versions/A/iLifeMediaBrowser"
echo "Built $OUT/Versions/A/iLifeMediaBrowser"
