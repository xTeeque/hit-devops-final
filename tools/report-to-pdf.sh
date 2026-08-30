#!/bin/bash
# Deliverable (l) - export a Gatling HTML report to PDF.
#
#   ./tools/report-to-pdf.sh <path-to-report-dir> <output.pdf>
#
# Gatling's report is one index.html that pulls in JS-rendered charts, so it is
# printed with headless Chrome after giving the charts time to draw.
set -euo pipefail

SRC="${1:?usage: report-to-pdf.sh <report-dir> <output.pdf>}"
OUT="${2:?usage: report-to-pdf.sh <report-dir> <output.pdf>}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

[ -f "$SRC/index.html" ] || { echo "no index.html in $SRC" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
PROFILE="$(mktemp -d /tmp/gatling-pdf-XXXX)"

"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir="$PROFILE" \
  --virtual-time-budget=15000 \
  --run-all-compositor-stages-before-draw \
  --print-to-pdf-no-header \
  --print-to-pdf="$OUT" \
  "file://$SRC/index.html" 2>/dev/null

rm -rf "$PROFILE"
[ -s "$OUT" ] || { echo "PDF was not produced" >&2; exit 1; }
echo "$OUT  ($(du -h "$OUT" | cut -f1))"
