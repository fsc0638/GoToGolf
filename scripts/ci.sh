#!/usr/bin/env bash
# One-key CI entry: GolfCore unit/integration tests + App UI tests.
# Runs entirely on the iOS Simulator with signing disabled, so it never
# needs an Apple development team.
#
#   ./scripts/ci.sh            # full run
#   ./scripts/ci.sh core       # only the swift-test (pure logic) layer
set -euo pipefail
cd "$(dirname "$0")/.."

bold() { printf "\n\033[1m==> %s\033[0m\n" "$1"; }

bold "GolfCore unit/integration tests (swift test)"
swift test --enable-code-coverage

if [ "${1:-all}" = "core" ]; then
    bold "Done (core only)."
    exit 0
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen not found — install with: brew install xcodegen" >&2
    exit 1
fi

bold "Regenerating Xcode project from project.yml"
( cd App && xcodegen generate )

bold "Picking an available iPhone simulator"
UDID=$(xcrun simctl list devices available \
    | grep -Eo 'iPhone[^(]*\(([0-9A-Fa-f-]{36})\)' \
    | grep -Eo '[0-9A-Fa-f-]{36}' | head -1 || true)
if [ -z "${UDID}" ]; then
    echo "No available iPhone simulator. Create one in Xcode ▸ Settings ▸ Platforms." >&2
    exit 1
fi
echo "Simulator: ${UDID}"

bold "App UI tests (xcodebuild, signing disabled)"
xcodebuild test \
    -project App/GoToGolf.xcodeproj \
    -scheme GoToGolf \
    -destination "id=${UDID}" \
    CODE_SIGNING_ALLOWED=NO \
    -quiet

bold "All green."
