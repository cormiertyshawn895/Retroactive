#!/bin/bash
# Builds ITunesTahoeFix.dylib (x86_64, iTunes runs under Rosetta 2) into Support/ITunesTahoeFix.
set -e
cd "$(dirname "$0")"
clang -arch x86_64 -dynamiclib -fobjc-arc -mmacosx-version-min=10.13 -framework AppKit \
      -o ../../Support/ITunesTahoeFix/ITunesTahoeFix.dylib ITunesTahoeFix.m
codesign -fs - ../../Support/ITunesTahoeFix/ITunesTahoeFix.dylib
