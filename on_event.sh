#!/bin/sh
# herdr-push: push agent status to herdr-remote relay
# Uses standard herdr plugin environment variables

# Load config from plugin config dir (herdr creates this)
if [ -z "$HERDR_RELAY" ] && [ -n "$HERDR_PLUGIN_CONFIG_DIR" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/.env" ]; then
    HERDR_RELAY=$(grep '^HERDR_RELAY=' "$HERDR_PLUGIN_CONFIG_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
    export HERDR_RELAY
fi

# Optional shared-secret token (matches HERDR_RELAY_TOKEN on the relay)
if [ -z "$HERDR_RELAY_TOKEN" ] && [ -n "$HERDR_PLUGIN_CONFIG_DIR" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/.env" ]; then
    HERDR_RELAY_TOKEN=$(grep '^HERDR_RELAY_TOKEN=' "$HERDR_PLUGIN_CONFIG_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
    export HERDR_RELAY_TOKEN
fi

RELAY="${HERDR_RELAY:-}"
[ -z "$RELAY" ] && exit 0

# Parse HERDR_PLUGIN_EVENT_JSON (standard herdr plugin env)
# Also merge HERDR_PLUGIN_CONTEXT_JSON for workspace/tab info
if command -v python3 >/dev/null 2>&1; then
    PAYLOAD=$(python3 << 'EOF'
import json, os, socket

event = json.loads(os.environ.get("HERDR_PLUGIN_EVENT_JSON", "{}"))
context = json.loads(os.environ.get("HERDR_PLUGIN_CONTEXT_JSON", "{}"))
data = event.get("data", {})

print(json.dumps({
    "type": "agent_event",
    "pane_id": data.get("pane_id", ""),
    "status": (data.get("agent_status") or "").lower(),
    "agent": (data.get("agent") or data.get("display_agent") or "").lower(),
    "project": os.path.basename(data.get("cwd", "")),
    "cwd": data.get("cwd", ""),
    "host": socket.gethostname().split(".")[0],
    "workspace": context.get("workspace", ""),
    "tab": context.get("tab", ""),
    "custom_status": data.get("custom_status", ""),
}))
EOF
)
elif command -v jq >/dev/null 2>&1; then
    PAYLOAD=$(echo "$HERDR_PLUGIN_EVENT_JSON" | jq -c --arg host "$(hostname -s)" '{
        type: "agent_event",
        pane_id: .data.pane_id,
        status: (.data.agent_status // "" | ascii_downcase),
        agent: ((.data.agent // .data.display_agent // "") | ascii_downcase),
        project: (.data.cwd // "" | split("/") | last),
        cwd: (.data.cwd // ""),
        host: $host,
        custom_status: (.data.custom_status // "")
    }')
else
    exit 0
fi

[ -z "$PAYLOAD" ] && exit 0

# POST to relay (encode payload in query param for compatibility)
HTTP_RELAY=$(echo "$RELAY" | sed 's|^ws://|http://|;s|^wss://|https://|')
ENCODED=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$PAYLOAD" 2>/dev/null || \
          printf '%s' "$PAYLOAD" | jq -sRr @uri 2>/dev/null || \
          printf '%s' "$PAYLOAD" | sed 's/ /%20/g;s/{/%7B/g;s/}/%7D/g;s/"/%22/g;s/:/%3A/g;s/,/%2C/g')
URL="${HTTP_RELAY}/push?d=${ENCODED}"
[ -n "$HERDR_RELAY_TOKEN" ] && URL="${URL}&token=${HERDR_RELAY_TOKEN}"
curl -s --max-time 5 "$URL" >/dev/null 2>&1
exit 0
