#!/bin/bash
# Deliverable (l) - export a Gatling HTML report to PDF.
#
#   ./tools/report-to-pdf.sh <report-dir> <output.pdf>
#
# Headless Chrome sometimes writes the PDF and then fails to exit, so it is run
# in the background under a watchdog: as soon as the file stops growing we take
# it and kill Chrome, and we give up after a hard deadline either way.
set -uo pipefail

SRC="${1:?usage: report-to-pdf.sh <report-dir> <output.pdf>}"
OUT="${2:?usage: report-to-pdf.sh <report-dir> <output.pdf>}"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
DEADLINE=90

# Chrome needs an absolute file:// path. A relative one parses the first path
# segment as a hostname and silently renders an ERR_INVALID_URL error page.
SRC="$(cd "$SRC" 2>/dev/null && pwd)" || { echo "no such directory: $1" >&2; exit 1; }
[ -f "$SRC/index.html" ] || { echo "no index.html in $SRC" >&2; exit 1; }
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"
PROFILE="$(mktemp -d /tmp/gatling-pdf-XXXX)"

"$CHROME" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
  --user-data-dir="$PROFILE" --virtual-time-budget=15000 \
  --run-all-compositor-stages-before-draw --print-to-pdf-no-header \
  --print-to-pdf="$OUT" "file://$SRC/index.html" >/dev/null 2>&1 &
CPID=$!

STABLE=0; LAST=0
for _ in $(seq 1 $DEADLINE); do
  kill -0 "$CPID" 2>/dev/null || break
  SIZE=$(stat -f%z "$OUT" 2>/dev/null || echo 0)
  if [ "$SIZE" -gt 0 ] && [ "$SIZE" -eq "$LAST" ]; then
    STABLE=$((STABLE+1)); [ "$STABLE" -ge 3 ] && break
  else
    STABLE=0
  fi
  LAST=$SIZE
  sleep 1
done

kill "$CPID" 2>/dev/null; wait "$CPID" 2>/dev/null
pkill -f "user-data-dir=$PROFILE" 2>/dev/null
sleep 1
rm -rf "$PROFILE" 2>/dev/null

[ -s "$OUT" ] || { echo "PDF was not produced for $SRC" >&2; exit 1; }

# A rendered error page is a valid, non-empty PDF, so size proves nothing.
# Confirm the report content actually made it in.
if command -v pdftotext >/dev/null; then
  if ! pdftotext "$OUT" - 2>/dev/null | grep -qiE "Gatling|Global Information|response time"; then
    echo "PDF rendered but contains no Gatling report content: $OUT" >&2
    exit 1
  fi
fi
echo "$OUT ($(du -h "$OUT" | cut -f1))"
