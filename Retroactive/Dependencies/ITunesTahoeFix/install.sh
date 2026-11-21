#!/bin/bash
# ITunesTahoeFix installer for iTunes 12.9.5 installed by Retroactive (macOS 26 Tahoe).
#
# Fixes:
#   1. Crash when closing Get Info / About / MiniPlayer / after editing metadata
#      (_objc_fatal in weak_register_no_lock from -[ITNSButton dealloc]).
#   2. Startup "An unknown error occurred (-42408)." dialog (iTunes Store auth).
#
# Usage:
#   ./install.sh [path/to/iTunes.app]             install (default /Applications/iTunes.app)
#   ./install.sh --uninstall [path/to/iTunes.app]  remove
#
# Does not touch the iTunes binary, Apple frameworks or your iTunes Library.
# Only adds ITunesTahoeFix.dylib to Contents/Resources and one line to the
# Retroactive launcher script, then re-signs the outer bundle ad-hoc.

set -euo pipefail

MODE=install
if [[ "${1:-}" == "--uninstall" ]]; then MODE=uninstall; shift; fi
APP="${1:-/Applications/iTunes.app}"
APP="${APP%/}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER="$APP/Contents/MacOS/iTunes"
INNER="$APP/Contents/MacOS/iTunes.app/Contents/MacOS/iTunes"
DYLIB_DST="$APP/Contents/Resources/ITunesTahoeFix.dylib"
MARK='# ITunesTahoeFix'
LINE='    export DYLD_INSERT_LIBRARIES="${iTunes_PATH}/../Resources/ITunesTahoeFix.dylib" '"$MARK"
ANCHOR='export DYLD_LIBRARY_PATH='

die() { echo "Error: $*" >&2; exit 1; }

# --- sanity checks -----------------------------------------------------------
[[ -d "$APP" ]] || die "$APP not found."
[[ -f "$LAUNCHER" && -f "$INNER" ]] || die "$APP does not look like a Retroactive iTunes install (expected launcher script and nested iTunes.app)."
head -1 "$LAUNCHER" | grep -q '^#!' || die "$LAUNCHER is not a launcher script; this is not a Retroactive layout."
grep -q "$ANCHOR" "$LAUNCHER" || die "Unexpected launcher script format; refusing to edit it."
if [[ ! -w "$LAUNCHER" || ! -w "$APP/Contents" ]]; then
  die "No write permission for $APP. Re-run with: sudo \"$0\" ${MODE/install/} \"$APP\""
fi
if pgrep -f "$INNER" >/dev/null; then die "Quit iTunes first."; fi

resign() {
  codesign -s - -f "$APP" >/dev/null 2>&1 || die "codesign failed."
  codesign --verify --deep "$APP" || die "Signature verification failed."
}

# --- uninstall ---------------------------------------------------------------
if [[ "$MODE" == uninstall ]]; then
  if grep -q "$MARK" "$LAUNCHER"; then
    grep -v "$MARK" "$LAUNCHER" > "$LAUNCHER.tmp" && cat "$LAUNCHER.tmp" > "$LAUNCHER" && rm -f "$LAUNCHER.tmp"
  fi
  rm -f "$DYLIB_DST"
  resign
  echo "ITunesTahoeFix removed from $APP."
  exit 0
fi

# --- install -----------------------------------------------------------------
DYLIB_SRC="$HERE/ITunesTahoeFix.dylib"; [[ -f "$DYLIB_SRC" ]] || DYLIB_SRC="$HERE/../../Support/ITunesTahoeFix/ITunesTahoeFix.dylib"
if [[ ! -f "$DYLIB_SRC" ]]; then
  [[ -f "$HERE/ITunesTahoeFix.m" ]] || die "ITunesTahoeFix.dylib (or ITunesTahoeFix.m) not found next to this script."
  command -v clang >/dev/null || die "clang not found. Install Command Line Tools: xcode-select --install"
  echo "Building ITunesTahoeFix.dylib..."
  DYLIB_SRC="$(mktemp -d)/ITunesTahoeFix.dylib"
  clang -arch x86_64 -dynamiclib -fobjc-arc -mmacosx-version-min=10.13 \
        -framework AppKit -o "$DYLIB_SRC" "$HERE/ITunesTahoeFix.m"
  codesign -s - -f "$DYLIB_SRC" >/dev/null
fi
lipo -archs "$DYLIB_SRC" 2>/dev/null | grep -q x86_64 || die "dylib is not x86_64."

mkdir -p "$APP/Contents/Resources"
cp -f "$DYLIB_SRC" "$DYLIB_DST"

if ! grep -q "$MARK" "$LAUNCHER"; then
  awk -v anchor="$ANCHOR" -v line="$LINE" '{print} index($0, anchor){print line}' "$LAUNCHER" > "$LAUNCHER.tmp"
  cat "$LAUNCHER.tmp" > "$LAUNCHER" && rm -f "$LAUNCHER.tmp"
fi

resign
echo "ITunesTahoeFix installed into $APP. Launch iTunes normally."
