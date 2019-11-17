#!/bin/bash

set -e

cd "$(dirname "$0")"

inputPath=input
outputPath=output
version=1671.60.109
rm -rf $outputPath
mkdir $outputPath

function run
{
	frameworkName=$1
	frameworkPath=$2
	
	cp -R $inputPath/$frameworkName $outputPath/
	
	frameworkNameMoved=${frameworkName}Original
	
	binaryPathLocal=$outputPath/$frameworkName
	binaryPathLocalMoved=$outputPath/$frameworkNameMoved
	
	binaryPathFull=$frameworkPath/$frameworkName.framework/Versions/A/$frameworkName
	binaryPathFullMoved=$frameworkPath/$frameworkName.framework/Versions/A/$frameworkNameMoved
	
	mv $binaryPathLocal $binaryPathLocalMoved
	
	wrapperName=${frameworkName}Wrapper

	clang++ $wrapperName.m -dynamiclib -o $wrapperName.o -framework CoreFoundation -framework Foundation -fmodules -Xlinker -reexport_library $binaryPathLocalMoved -install_name $binaryPathFull -compatibility_version $version -current_version $version -arch i386 -arch x86_64

	install_name_tool -id $binaryPathFullMoved $binaryPathLocalMoved
	install_name_tool -change $binaryPathFull $binaryPathFullMoved $wrapperName.o
		
	mv $wrapperName.o $binaryPathLocal
	
	codesign -f -s - $binaryPathLocalMoved
	codesign -f -s - $binaryPathLocal
}

run "AppKit" "/System/Library/Frameworks"
run "AudioToolbox" "/System/Library/Frameworks"

# sudo install_name_tool -change "/System/Library/Frameworks/AudioToolbox.framework/Versions/A/AudioToolboxOriginal" "@loader_path/AudioToolboxOriginal" ./AudioToolbox.framework/Versions/A/AudioToolbox