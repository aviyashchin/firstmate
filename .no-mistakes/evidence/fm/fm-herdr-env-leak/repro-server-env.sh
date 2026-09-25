#!/usr/bin/env bash
# Reproduce the Herdr server env leak before/after the fix.
# Usage: repro-server-env.sh <worktree>
# Simulates fm-fleet-snapshot.sh -> fm-crew-state.sh fm-provider-repair, whose
# Herdr probe auto-starts the long-lived server. A fake `herdr server` records
# the environment the server (and so every later pane) inherits.
set -u
WT=$1
T=$(mktemp -d)
mkdir -p "$T/base" "$T/fb"
git -C "$WT" archive a8572f6 bin | tar -x -C "$T/base"
cat > "$T/fb/herdr" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  status) if [ -e "$MARK" ]; then echo '{"server":{"running":true}}'; else echo '{"server":{"running":false}}'; fi ;;
  server) { env | grep -E '^(FM_|HERDR_SESSION)' | sort; echo "args=$*"; } > "$LOG"; : > "$MARK" ;;
esac
SH
chmod +x "$T/fb/herdr"
run() {  # <label> <root>
  PATH="$T/fb:$PATH" LOG="$T/$1.env" MARK="$T/$1.mark" \
    FM_CREW_STATE_META_OVERRIDE=/tmp/snap/fm-provider-repair.meta FM_CREW_STATE_STATUS_OVERRIDE=/tmp/snap/fm-provider-repair.status \
    FM_CREW_STATE_NO_FORGE=1 FM_CREW_STATE_BIN=/tmp/stub \
    FM_SESSION_START_STAGE_FILE=/tmp/stage FM_SESSIONSTART_SUPERVISOR_PID=4242 \
    FM_HOME_SUMMARY_IF_IDLE=1 FM_HOME_SUMMARY_WORKER_BEST_EFFORT=1 FM_HOME_SUMMARY_PARENT_STAMP=s \
    FM_SESSION_START_TIMEOUT=300 FM_SESSION_START_QUEUED_LIMIT=7 FM_SESSION_START_STATUS_TAIL=9 \
    FM_HOME_SUMMARY_INTERVAL=90 FM_HOME_SUMMARY_TIMEOUT=11 FM_HOME_SUMMARY_FAILURE_REPORT=5 \
    FM_CREW_STATE_RUNS_LIMIT=50 FM_CREW_STATE_NM_TIMEOUT=25 \
    bash -c '. "$0/bin/backends/herdr.sh"; fm_backend_herdr_server_ensure default; echo "server_ensure rc=$?"' "$2"
}
echo "# Environment inherited by a 'herdr server' auto-started from a fleet-snapshot crew-state probe"
echo
echo "## BEFORE (base a8572f6)"; run before "$T/base"; cat "$T/before.env"
echo
echo "## AFTER (target a03419f)"; run after "$WT"; cat "$T/after.env"
echo
echo "## diff before -> after"; diff "$T/before.env" "$T/after.env"
echo "(temp dir: $T)"
