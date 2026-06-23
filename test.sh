#!/bin/sh
# Test push to herdr-remote relay
# Usage: herdr plugin action invoke herdr.push test

RELAY="${HERDR_RELAY:-}"

# Load from plugin config dir (standard herdr location)
if [ -z "$RELAY" ] && [ -n "$HERDR_PLUGIN_CONFIG_DIR" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/.env" ]; then
    RELAY=$(grep '^HERDR_RELAY=' "$HERDR_PLUGIN_CONFIG_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
fi

if [ -z "$RELAY" ]; then
    echo "✗ HERDR_RELAY not set."
    echo ""
    echo "Option 1 — env var:"
    echo "  export HERDR_RELAY=\"https://your-relay-url\""
    echo "  launchctl setenv HERDR_RELAY \"\$HERDR_RELAY\""
    echo "  herdr server reload-config"
    echo ""
    echo "Option 2 — config file:"
    CONFIG_DIR="${HERDR_PLUGIN_CONFIG_DIR:-$(herdr plugin config-dir herdr.push 2>/dev/null)}"
    echo "  echo 'HERDR_RELAY=https://your-relay-url' > \"$CONFIG_DIR/.env\""
    exit 1
fi

HTTP_RELAY=$(echo "$RELAY" | sed 's|^ws://|http://|;s|^wss://|https://|')
HOST=$(hostname -s)
PAYLOAD="{\"type\":\"agent_event\",\"pane_id\":\"test-$$\",\"status\":\"blocked\",\"agent\":\"test\",\"project\":\"test-project\",\"cwd\":\"/tmp/test\",\"host\":\"$HOST\"}"

echo "→ Pushing to $HTTP_RELAY"
STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" --max-time 5 "$HTTP_RELAY")

if [ "$STATUS" = "200" ]; then
    echo "✓ Success! Test agent should appear on your dashboard."
else
    echo "✗ Failed (HTTP $STATUS)"
    echo "  Is the relay running? Is the URL correct?"
    exit 1
fi
