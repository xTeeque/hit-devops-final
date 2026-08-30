#!/bin/bash
# Wrapper around the Gatling bundle so Jenkins and the terminal run it identically.
#
#   ./gatling/run.sh MaxLimitSimulation
#   ./gatling/run.sh LoadSimulation  -Dload.rate=40
#   APP_BASE=https://example.com ./gatling/run.sh StressSimulation
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE="$(ls -d "$HERE"/gatling-charts-highcharts-bundle-* 2>/dev/null | head -1)"

if [ -z "$BUNDLE" ]; then
  echo "Gatling bundle not found. Run ./gatling/install.sh first." >&2
  exit 1
fi

SIM="${1:?usage: run.sh <SimulationClass> [-Dkey=value ...]}"
shift || true

# The default java on this machine is 1.8; Gatling 3.13 needs 11+.
export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

APP_BASE="${APP_BASE:-http://localhost:8080/AsafArusi}"

# Simulations live in gatling/simulations/ so they are version controlled;
# the bundle itself is not committed. Sync them in before every run.
mkdir -p "$BUNDLE/src/test/java"
rm -f "$BUNDLE"/src/test/java/*.java
cp "$HERE"/simulations/*.java "$BUNDLE/src/test/java/"

echo "=================================================="
echo " simulation : $SIM"
echo " target     : $APP_BASE"
echo " java       : $(java -version 2>&1 | head -1)"
echo " started    : $(date '+%Y-%m-%d %H:%M:%S')"
echo "=================================================="

cd "$BUNDLE"
./mvnw -q gatling:test \
  -Dgatling.simulationClass="$SIM" \
  -Dapp.base="$APP_BASE" \
  "$@"

LATEST="$(ls -dt "$BUNDLE"/target/gatling/*/ 2>/dev/null | head -1)"
echo
echo "HTML report: ${LATEST}index.html"
