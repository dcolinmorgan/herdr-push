#!/bin/sh
PASS=0; FAIL=0
assert() { if [ "$1" = "$2" ]; then PASS=$((PASS+1)); echo "  pass: $3"; else FAIL=$((FAIL+1)); echo "  FAIL: $3"; fi; }
echo "herdr-push tests"
echo "1. exits cleanly with no HERDR_RELAY"
HERDR_RELAY="" HERDR_PLUGIN_EVENT_JSON='{}' sh on_event.sh 2>/dev/null; assert "$?" "0" "exit 0"
echo "2. test.sh fails gracefully without HERDR_RELAY"
OUTPUT=$(HERDR_RELAY="" HERDR_PLUGIN_CONFIG_DIR="/nonexistent" sh test.sh 2>&1)
echo "$OUTPUT" | grep -q "HERDR_RELAY not set" && { PASS=$((PASS+1)); echo "  pass: helpful error"; } || { FAIL=$((FAIL+1)); echo "  FAIL: no error msg"; }
echo "3. .env loading"
T=$(mktemp -d); echo 'HERDR_RELAY=http://test' > "$T/.env"
HERDR_RELAY="" HERDR_PLUGIN_CONFIG_DIR="$T" HERDR_PLUGIN_EVENT_JSON='{"data":{"pane_id":"x","agent_status":"idle","agent":"t","cwd":"/tmp"}}' sh on_event.sh 2>/dev/null
assert "$?" "0" ".env loads"; rm -rf "$T"
echo ""; echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
