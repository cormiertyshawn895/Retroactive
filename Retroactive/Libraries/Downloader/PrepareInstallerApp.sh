#!/bin/sh
sourcePath=$1
sharedSupportPath=$2
recHDMeta=$3
cp "$recHDMeta/AppleDiagnostics.chunklist" "$sharedSupportPath/"
cp "$recHDMeta/AppleDiagnostics.dmg" "$sharedSupportPath/"
cp "$recHDMeta/BaseSystem.chunklist" "$sharedSupportPath/"
cp "$recHDMeta/BaseSystem.dmg" "$sharedSupportPath/"
mv "$sourcePath/InstallESDDmg.pkg" "$sharedSupportPath/InstallESD.dmg"
