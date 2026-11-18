#!/usr/bin/env bash
# Drive bin/fm-inbox.sh (base vs head) against disposable FM_HOMEs.
# Usage: drive-inbox.sh <bin-dir> <label>
set -uo pipefail
BIN=$1/fm-inbox.sh; LABEL=$2
T=$(mktemp -d "${TMPDIR:-/tmp}/fm-inbox-live.XXXXXX")
run() { local h=$1; shift; FM_HOME="$h" FM_STATE_OVERRIDE="$h/state" FM_DATA_OVERRIDE="$h/data" FM_CONFIG_OVERRIDE="$h/config" "$BIN" "$@"; }
wakes() { [ -f "$1/state/.wake-queue" ] && grep -c 'inbox:' "$1/state/.wake-queue" || echo 0; }
echo "===== $LABEL ($BIN) ====="
h=$T/acked; mkdir -p $h/state $h/data $h/config
echo "--- S1 note --request-id seen-1 --json (first submission)"
first=$(run $h note --request-id seen-1 --json "announced then drained"); echo "rc=$? $first"
id=$(printf '%s' "$first" | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
echo "--- drain --ack $id"; run $h drain --ack "$id" >/dev/null; echo "rc=$?"
echo "handled/: $(ls $h/state/inbox/handled)"; w0=$(wakes $h); echo "wakes=$w0"
echo "--- S1 replay: note --request-id seen-1 --json"
out=$(run $h note --request-id seen-1 --json "announced then drained"); echo "rc=$? $out"
echo "--- S2 human replay: note --request-id seen-1"
out=$(run $h note --request-id seen-1 "announced then drained"); echo "rc=$?"; echo "$out"
echo "--- S3 announce --json $id"
out=$(run $h announce --json "$id"); echo "rc=$? $out"
echo "--- S3 human announce $id"
out=$(run $h announce "$id"); echo "rc=$? $out"
echo "--- S4 side effects: wakes before=$w0 after=$(wakes $h); pending notes=$(find $h/state/inbox -maxdepth 1 -name '*.note'|wc -l); handled notes=$(find $h/state/inbox/handled -name '*.note'|wc -l)"
h=$T/pending; mkdir -p $h/state $h/data $h/config
echo "--- S5 regression: announced, NOT acknowledged"
first=$(run $h note --request-id p-1 --json "still pending"); echo "rc=$? $first"
id=$(printf '%s' "$first" | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
out=$(run $h note --request-id p-1 --json "still pending"); echo "replay json rc=$? $out"
out=$(run $h note --request-id p-1 "still pending"); echo "replay human rc=$?"; echo "$out"
out=$(run $h announce --json "$id"); echo "announce json rc=$? $out"
echo "wakes=$(wakes $h)"
rm -rf "$T"
