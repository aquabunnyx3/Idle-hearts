#!/usr/bin/env bash
# Builds Idle Hearts for the simulator and captures App Store-sized screenshots.
# Usage: scripts/screenshots.sh [output-dir]   (macOS + Xcode required)
set -euo pipefail
OUT="${1:-screenshots}"
mkdir -p "$OUT"
DERIVED=build/DerivedData

xcodebuild -project IdleHearts.xcodeproj -scheme IdleHearts -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO build | tail -5

APP="$DERIVED/Build/Products/Debug-iphonesimulator/IdleHearts.app"
BUNDLE=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")

# Largest iPhone available (6.9" screenshots are what App Store Connect requires).
DEVICE=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
d=json.load(sys.stdin)["devices"]
names=[(rt,x) for rt,l in d.items() if "iOS" in rt for x in l]
pick=[p for p in names if "Pro Max" in p[1]["name"]] or [p for p in names if "Plus" in p[1]["name"]] or [p for p in names if "iPhone" in p[1]["name"]]
pick.sort(key=lambda p:(p[0],p[1]["name"]))
print(pick[-1][1]["udid"])')
echo "Using simulator $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl status_bar "$DEVICE" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
xcrun simctl install "$DEVICE" "$APP"

shot() {
  local name="$1"; shift
  xcrun simctl terminate "$DEVICE" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$DEVICE" "$BUNDLE" "$@" >/dev/null
  sleep 5
  xcrun simctl io "$DEVICE" screenshot "$OUT/$name.png" >/dev/null
  echo "captured $name"
}

shot 01-home -demo
shot 02-matches -demo -tab matches
shot 03-agency -demo -tab agency
shot 04-story -demo -tab story
shot 05-welcome -demo -overlay welcome
shot 06-complete -demo -overlay complete
shot 07-drama -demo -overlay drama
# A genuine first launch, no demo data.
xcrun simctl uninstall "$DEVICE" "$BUNDLE"; xcrun simctl install "$DEVICE" "$APP"
shot 08-first-launch
