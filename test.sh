#!/bin/sh
# Test push to herdr-remote relay
RELAY="${HERDR_RELAY:-}"

# Load from config dir if not in env
if [ -z "$RELAY" ] && [ -n "$HERDR_PLUGIN_CONFIG_DIR" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/.env" ]; then
    RELAY=$(grep '^HERDR_RELAY=' "$HERDR_PLUGIN_CONFIG_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
fi

if [ -z "$RELAY" ]; then
    echo "✗ HERDR_RELAY not set. Run:"
    echo "  export HERDR_RELAY=\"https://your-relay-url\""
    echo "  launchctl setenv HERDR_RELAY \"\$HERDR_RELAY\""
    echo "  herdr server reload-config"
    exit 1
fi

HTTP_RELAY=$(echo "$RELAY" | sed 's|^ws://|http://|;s|^wss://|https://|')
PAYLOAD='{"type":"agent_event","pane_id":"test","status":"blocked","agent":"test","project":"test-project","cwd":"/tmp","host":"'"$(hostname -s)"'"}'

STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" --max-time 5 "$HTTP_RELAY")

if [ "$STATUS" = "200" ]; then
    echo "✓ Push succeeded to $HTTP_RELAY"
else
    echo "✗ Push failed (HTTP $STATUS) to $HTTP_RELAY"
    exit 1
fi
