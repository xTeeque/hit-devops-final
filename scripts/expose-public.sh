#!/bin/bash
# Brief step 5 (bonus) - put production on a public URL.
#
# NOTE: this failed on the network used during development. cloudflared needs
# outbound TCP and UDP on port 7844, which was blocked; ngrok's endpoints had
# their TLS handshake reset. Both are network restrictions, not tool problems.
# Re-run this from a phone hotspot or a home network and it should come up.
#
#   ./scripts/expose-public.sh
#
set -euo pipefail

LOG="$HOME/Library/Logs/cloudflared-quick.log"
LOCAL="http://localhost:8080"

command -v cloudflared >/dev/null || { echo "brew install cloudflared" >&2; exit 1; }

echo "checking whether this network allows tunnel traffic..."
if ! nc -z -G 5 region1.v2.argotunnel.com 7844 2>/dev/null; then
  cat >&2 <<'MSG'
Outbound port 7844 is blocked on this network, so a Cloudflare tunnel cannot
connect. Options, cheapest first:
  1. Tether to a phone hotspot and run this again.
  2. Use ngrok instead (tunnels over 443):
       brew install ngrok && ngrok config add-authtoken <token> && ngrok http 8080
  3. Forward port 8080 on your home router to this machine and use the WAN IP.
MSG
  exit 1
fi

pkill -f "cloudflared tunnel" 2>/dev/null || true
nohup cloudflared tunnel --url "$LOCAL" > "$LOG" 2>&1 &
disown

echo "waiting for the public URL..."
for _ in $(seq 1 30); do
  URL=$(grep -oE "https://[a-z0-9-]+\.trycloudflare\.com" "$LOG" 2>/dev/null | head -1 || true)
  [ -n "${URL:-}" ] && break
  sleep 2
done

[ -n "${URL:-}" ] || { echo "no URL appeared - see $LOG" >&2; exit 1; }

echo
echo "  public application : ${URL}/AsafArusi/"
echo "  log                : ${LOG}"
echo
echo "Keep this tunnel running. A quick tunnel gets a NEW random URL every"
echo "restart, so point UptimeRobot at it only once it is stable, and re-run"
echo "the Gatling tests against it with:"
echo "  APP_BASE=${URL}/AsafArusi ./gatling/run.sh LoadSimulation"
