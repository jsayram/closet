#!/bin/bash
# Render an .html or .svg file to PNG with headless Chrome.
# usage: shot.sh <input.html|svg> <out.png> [width=390] [height=844] [scale=2]
in="$1"; out="$2"; w="${3:-390}"; h="${4:-844}"; s="${5:-2}"
case "$in" in
  http://*|https://*|file://*) target="$in" ;;
  *) [ -f "$in" ] || { echo "no such file: $in" >&2; exit 1; }
     target="file://$(cd "$(dirname "$in")" && pwd)/$(basename "$in")" ;;
esac
# Prefer chrome-headless-shell (honours small window sizes like 390x844); fall back to Chrome.
SHELL_BIN="$(ls -d "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-mac-*/chrome-headless-shell 2>/dev/null | tail -1)"
if [ -n "$SHELL_BIN" ] && [ -x "$SHELL_BIN" ]; then BROWSER="$SHELL_BIN"; HEADLESS_FLAG=""; else BROWSER="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; HEADLESS_FLAG="--headless=new"; fi
prof="$(mktemp -d "${TMPDIR:-/tmp}/shot.XXXXXX")"
rm -f "$out"
"$BROWSER" $HEADLESS_FLAG --disable-gpu --hide-scrollbars \
  --no-first-run --no-default-browser-check --user-data-dir="$prof" --allow-file-access-from-files \
  --force-device-scale-factor="$s" --window-size="$w,$h" --virtual-time-budget=2500 \
  --default-background-color=FFFFFFFF --screenshot="$out" "$target" >/dev/null 2>&1 &
pid=$!
# Chrome sometimes stays alive after writing the file, so wait for the file, then stop it.
for i in $(seq 1 100); do
  if [ -s "$out" ]; then sleep 0.4; break; fi
  kill -0 $pid 2>/dev/null || break
  sleep 0.25
done
kill $pid 2>/dev/null; sleep 0.2; kill -9 $pid 2>/dev/null
pkill -f "user-data-dir=$prof" 2>/dev/null
rm -rf "$prof"
[ -s "$out" ] && echo "wrote $out" || { echo "render failed" >&2; exit 1; }
