#!/bin/bash
# Build the review site into ROOT/site/ (deleted and recreated every time), ready to publish on here.now.
#   tools/build-site.sh
# Copies: index.html, review.html, summary.html, screens/*.html (not files starting with "_"), css/, js/
# (not avatar.js), art/*.svg, snapshots/*.png, and site-data.json as site/.herenow/data.json (the Site Data
# manifest). Leaves out archive/, ref/, tools/, Markdown, research, any .herenow/state.json and credentials.
# Publish from ROOT (not from inside site/) so here.now's state file stays in ROOT/.herenow/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/site"
cd "$ROOT"

case "$OUT" in "$ROOT"/site) ;; *) echo "refusing to clear $OUT" >&2; exit 1 ;; esac
rm -rf "$OUT"
mkdir -p "$OUT/screens" "$OUT/css" "$OUT/js" "$OUT/art" "$OUT/snapshots" "$OUT/.herenow"

for f in index.html review.html summary.html; do
  [ -f "$f" ] || { echo "missing $f" >&2; exit 1; }
  cp "$f" "$OUT/$f"
done

shopt -s nullglob
for f in screens/*.html; do
  case "$(basename "$f")" in _*) continue ;; esac
  cp "$f" "$OUT/screens/"
done
for f in css/*.css; do cp "$f" "$OUT/css/"; done
for f in js/*.js; do
  [ "$(basename "$f")" = "avatar.js" ] && continue
  cp "$f" "$OUT/js/"
done
for f in art/*.svg; do cp "$f" "$OUT/art/"; done
for f in snapshots/*--*.png; do cp "$f" "$OUT/snapshots/"; done

# Site Data manifest: validate it is JSON before shipping it.
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' site-data.json || { echo "site-data.json is not valid JSON" >&2; exit 1; }
cp site-data.json "$OUT/.herenow/data.json"

# Belt and braces: nothing private or tool-only in the output.
find "$OUT" \( -name 'state.json' -o -name 'credentials' -o -name '*.md' -o -name '.DS_Store' \) -delete
# Screens still being written may reference files that are not there yet; warn, do not fail.
missing=0
while IFS= read -r ref; do
  [ -e "$OUT/screens/$ref" ] || { echo "warning: screens reference missing file: $ref" >&2; missing=$((missing+1)); }
done < <(grep -ohE '(src|href)="\.\./(css|js|art)/[^"?#]+' "$OUT"/screens/*.html 2>/dev/null | sed -E 's/^(src|href)="//' | sort -u)

count=$(find "$OUT" -type f | wc -l | tr -d ' ')
size=$(du -sh "$OUT" | cut -f1)
echo "built $OUT: $count files, $size"
[ "$missing" -eq 0 ] || echo "($missing missing asset references, see warnings)"
