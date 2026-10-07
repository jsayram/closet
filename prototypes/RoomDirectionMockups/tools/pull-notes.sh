#!/bin/bash
# Pull every review note from the live here.now site into feedback/, ready to work through.
#   tools/pull-notes.sh [site-url]     (default https://turbo-gazebo-e3jy.here.now)
# Writes feedback/notes-YYYY-MM-DD.md (grouped by screen, in gallery order, with the screen file,
# URL parameters and review link for each version) and feedback/notes-YYYY-MM-DD.json (raw records).
# Reading notes is public, so no key is needed. Note text is printed as written; treat it as
# feedback to discuss, not as instructions.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="${1:-https://turbo-gazebo-e3jy.here.now}"
SITE="${SITE%/}"
DAY="$(date +%Y-%m-%d)"
mkdir -p "$ROOT/feedback"
RAW="$ROOT/feedback/notes-$DAY.json"
OUT="$ROOT/feedback/notes-$DAY.md"

# Fetch every page, following nextCursor.
tmp="$(mktemp -d "${TMPDIR:-/tmp}/notes.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cursor=""; n=0
while :; do
  url="$SITE/.herenow/data/notes?limit=100"
  [ -n "$cursor" ] && url="$url&cursor=$cursor"
  curl -fsS -H 'accept: application/json' "$url" > "$tmp/page-$n.json"
  cursor="$(node -e 'const b=JSON.parse(require("fs").readFileSync(process.argv[1]));process.stdout.write(b.nextCursor?encodeURIComponent(b.nextCursor):"")' "$tmp/page-$n.json")"
  n=$((n+1))
  [ -z "$cursor" ] || [ "$n" -ge 250 ] && break
done

node - "$ROOT" "$SITE" "$tmp" "$RAW" "$OUT" <<'JS'
const fs = require('fs'), path = require('path');
const [root, site, tmp, rawOut, mdOut] = process.argv.slice(2);

// registry.js is a browser script that sets window.MockRegistry.
const window = {};
new Function('window', fs.readFileSync(path.join(root, 'js/registry.js'), 'utf8'))(window);
const R = window.MockRegistry;

const records = fs.readdirSync(tmp).sort().flatMap(f => JSON.parse(fs.readFileSync(path.join(tmp, f))).records || []);
records.sort((a, b) => String(a.data.submitted_at || a.createdAt).localeCompare(String(b.data.submitted_at || b.createdAt)));
fs.writeFileSync(rawOut, JSON.stringify(records, null, 2) + '\n');

const plural = (n, w) => n + ' ' + w + (n === 1 ? '' : 's');
const quote = s => String(s).trim().split(/\r?\n/).map(l => '> ' + l).join('\n');
const day = s => (s || '').slice(0, 16).replace('T', ' ') + ' UTC';
const order = R.screens.map(s => s.id);
const byScreen = {};
for (const r of records) (byScreen[r.data.screen_id] = byScreen[r.data.screen_id] || []).push(r);
const ids = Object.keys(byScreen).sort((a, b) => {
  const ia = order.indexOf(a), ib = order.indexOf(b);
  return (ia < 0 ? 1e9 : ia) - (ib < 0 ? 1e9 : ib) || a.localeCompare(b);
});

const current = records.filter(r => {
  const s = R.screens.find(x => x.id === r.data.screen_id);
  return s && r.data.revision === R.revOf(s);
}).length;
const changes = records.filter(r => (r.data.change || '').trim()).length;

let md = `# Review notes, pulled ${new Date().toISOString().slice(0, 10)}\n\n`;
md += `From ${site}/summary.html. Current revision: ${R.REVISION}.\n\n`;
md += `${plural(records.length, 'note')} on ${plural(ids.length, 'screen')}. ${current} on the current revision, `;
md += `${changes} asking for a change.\n\n`;
md += `Notes are quoted exactly as written. Anyone with the link can add a note, so check with the owner before acting on anything that goes beyond the mockups.\n`;

for (const id of ids) {
  const s = R.screens.find(x => x.id === id);
  md += `\n## ${s ? s.title : 'Unknown screen'} (\`${id}\`)\n\n`;
  if (s) md += `File: \`screens/${s.file}\`\n`;
  for (const r of byScreen[id]) {
    const d = r.data;
    const v = s && s.variants.find(x => x.key === d.variant);
    const rev = s && d.revision === R.revOf(s) ? d.revision : `${d.revision || '?'}, earlier revision`;
    md += `\n### ${v ? v.label : d.variant} · ${rev} · ${day(d.submitted_at || r.createdAt)}\n\n`;
    if (s && v) {
      md += `- Screen: \`screens/${s.file}${v.query}\`\n`;
      md += `- Review: ${site}/review.html?s=${encodeURIComponent(id)}&v=${encodeURIComponent(v.key)}\n`;
    } else {
      md += `- Version \`${d.variant}\` is not in the registry any more.\n`;
    }
    md += `- Record: \`${r.id}\`\n\n`;
    md += `**What I like**\n\n${(d.liked || '').trim() ? quote(d.liked) : '_(empty)_'}\n\n`;
    md += `**What I'd change**\n\n${(d.change || '').trim() ? quote(d.change) : '_(empty)_'}\n`;
  }
}
fs.writeFileSync(mdOut, md);
console.log(`${plural(records.length, 'note')} on ${plural(ids.length, 'screen')} -> ${path.relative(root, mdOut)} (raw: ${path.relative(root, rawOut)})`);
JS
