#!/bin/bash
# The Gatling bundle is ~200 MB, so it is not committed. This fetches it.
set -euo pipefail
VERSION="3.13.5"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
URL="https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/${VERSION}/gatling-charts-highcharts-bundle-${VERSION}.zip"

[ -d "$HERE/gatling-charts-highcharts-bundle-${VERSION}" ] && { echo "already installed"; exit 0; }
curl -fL --progress-bar -o "$HERE/gatling.zip" "$URL"
unzip -q "$HERE/gatling.zip" -d "$HERE"
rm "$HERE/gatling.zip"
echo "installed Gatling ${VERSION}"
