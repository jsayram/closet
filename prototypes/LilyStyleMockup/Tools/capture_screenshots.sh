#!/bin/zsh
# Runs the ScreenshotTour UI test on one simulator and exports labelled PNGs.
# Usage: Tools/capture_screenshots.sh "<simulator name or UDID>" <label> [light|dark] [large|key|-] [landscape|landscapeonly|-] [lab]
# Example: Tools/capture_screenshots.sh "iPhone 12 Pro Max" iphone12promax-ios27 light
# Set SHOT_ONLY="10-history-reuse,23-profile" to recapture only those shots into an existing folder.
set -e
DEST="$1"; LABEL="$2"; APPEARANCE="${3:-light}"; LARGE="${4:-}"; LAND="${5:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${TMPDIR:-/tmp}/lsm-shots-$LABEL"
rm -rf "$WORK"; mkdir -p "$WORK"
if [[ "$DEST" =~ ^[0-9A-F-]{36}$ ]]; then DSPEC="id=$DEST"; else DSPEC="platform=iOS Simulator,name=$DEST"; fi
export TEST_RUNNER_SHOT_APPEARANCE="$APPEARANCE"
[[ "$LARGE" == "large" ]] && export TEST_RUNNER_SHOT_LARGE_TEXT=1
[[ "$LARGE" == "key" ]] && export TEST_RUNNER_SHOT_ONLY_KEY=1
[[ "$LAND" == "landscape" ]] && export TEST_RUNNER_SHOT_LANDSCAPE=1
[[ "$LAND" == "landscapeonly" ]] && export TEST_RUNNER_SHOT_ORIENTATION=landscape
[[ -n "${SHOT_ONLY:-}" ]] && export TEST_RUNNER_SHOT_ONLY="$SHOT_ONLY"
LAB="${6:-}"
EXTRA=()
[[ "$LAB" == "lab" ]] && EXTRA+=(-only-testing:LilyStyleMockupUITests/ScreenshotTour/testCaptureLayoutLab)
xcodebuild test -project "$ROOT/LilyStyleMockup.xcodeproj" -scheme LilyStyleMockup -destination "$DSPEC" \
  -derivedDataPath "$WORK/dd" -resultBundlePath "$WORK/result.xcresult" \
  -only-testing:LilyStyleMockupUITests/ScreenshotTour/testCaptureTour \
  -only-testing:LilyStyleMockupUITests/ScreenshotTour/testCaptureKeyboard \
  "${EXTRA[@]}" \
  CODE_SIGNING_ALLOWED=NO > "$WORK/test.log" 2>&1 || echo "xcodebuild test exited non-zero (see $WORK/test.log)"
mkdir -p "$WORK/raw"
xcrun xcresulttool export attachments --path "$WORK/result.xcresult" --output-path "$WORK/raw" > /dev/null
OUT="$ROOT/Screenshots/$LABEL"
mkdir -p "$OUT"
python3 - "$WORK/raw" "$OUT" <<'PY'
import json, os, shutil, sys
raw, out = sys.argv[1], sys.argv[2]
manifest = json.load(open(os.path.join(raw, "manifest.json")))
n = 0
for test in manifest:
    for att in test.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or att.get("exportedFileName")
        base = name.split("_0_")[0] if "_0_" in name else os.path.splitext(name)[0]
        shutil.copy(os.path.join(raw, att["exportedFileName"]), os.path.join(out, base + ".png"))
        n += 1
print(f"exported {n} screenshots to {out}")
PY
grep -E "Test Suite .* (passed|failed)|error:" "$WORK/test.log" | tail -5
