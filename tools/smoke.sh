#!/bin/bash
# Flock smoke runner: build instrumented, run headless in the Playdate
# Simulator, poll the datastore, report.
#
#   tools/smoke.sh [seconds] [until-grep] [seed]

set -u
SECS="${1:-420}"
UNTIL="${2:-}"
SEED="${3:-1}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="com.sdwfrost.flock"
DATA="$HOME/Developer/PlaydateSDK/Disk/Data/$BUNDLE"
SIM="$HOME/Developer/PlaydateSDK/bin/Playdate Simulator.app/Contents/MacOS/Playdate Simulator"
SHOT="$ROOT/build/flock-shot.png"

cd "$ROOT"
rm -rf build/smoke
make smoke SEED="$SEED" >/dev/null || { echo "BUILD FAILED"; exit 1; }

pkill -9 -f "Playdate Simulator" 2>/dev/null
rm -rf "$DATA" "$SHOT"
("$SIM" "$ROOT/out/FlockSmoke.pdx" >"$ROOT/build/sim.log" 2>&1 &)

ITER=$((SECS / 5))
for i in $(seq 1 "$ITER"); do
    [ -s "$DATA/err.json" ] && break
    if [ -n "$UNTIL" ] && grep -qE "$UNTIL" "$DATA/smoke.json" 2>/dev/null; then
        break
    fi
    sleep 5
done

echo "--- err:"
cat "$DATA/err.json" 2>/dev/null || echo "no error"
echo "--- smoke:"
cat "$DATA/smoke.json" 2>/dev/null || echo "NO HEARTBEAT"
echo
[ -f "$SHOT" ] && echo "screenshot: $SHOT"

pkill -9 -f "Playdate Simulator" 2>/dev/null
mkdir -p "$ROOT/results"
cp "$DATA/smoke.json" "$ROOT/results/smoke-seed$SEED.json" 2>/dev/null
rm -rf "$DATA"
