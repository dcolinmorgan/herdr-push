#!/bin/sh
# herdr-push: push agent status to herdr-remote relay. Zero deps.
# Env: HERDR_RELAY (http/https URL) or falls back to UDP localhost:8376

RELAY="${HERDR_RELAY:-}"
EVENT="${HERDR_PLUGIN_EVENT_JSON:-{}}"

# Parse event JSON with built-in tools (or python/jq if available)
if command -v python3 >/dev/null 2>&1; then
    PAYLOAD=$(python3 -c "
import json, os, socket
e = json.loads('''$EVENT''')
d = e.get('data', {})
print(json.dumps({
    'type': 'agent_event',
    'pane_id': d.get('pane_id', ''),
    'status': (d.get('agent_status') or '').lower(),
    'agent': (d.get('agent') or d.get('display_agent') or '').lower(),
    'project': os.path.basename(d.get('cwd', '')),
    'cwd': d.get('cwd', ''),
    'host': socket.gethostname().split('.')[0],
}))
")
elif command -v jq >/dev/null 2>&1; then
    PAYLOAD=$(echo "$EVENT" | jq -c '{
        type: "agent_event",
        pane_id: .data.pane_id,
        status: (.data.agent_status // "" | ascii_downcase),
        agent: ((.data.agent // .data.display_agent // "") | ascii_downcase),
        project: (.data.cwd // "" | split("/") | last),
        cwd: (.data.cwd // ""),
        host: env.HOSTNAME
    }')
else
    # Minimal fallback — no JSON parser available
    exit 0
fi

[ -z "$PAYLOAD" ] && exit 0

# Send to relay
if echo "$RELAY" | grep -qE '^https?://'; then
    curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" --max-time 5 "$RELAY" >/dev/null 2>&1
elif [ -n "$RELAY" ]; then
    # WebSocket URL — convert to HTTP
    HTTP_RELAY=$(echo "$RELAY" | sed 's|^ws://|http://|;s|^wss://|https://|')
    curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" --max-time 5 "$HTTP_RELAY" >/dev/null 2>&1
fi

exit 0
