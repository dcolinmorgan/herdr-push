#!/bin/sh
# herdr-push: push agent status to herdr-remote relay. Zero deps.

# Load config from plugin config dir if HERDR_RELAY not in env
if [ -z "$HERDR_RELAY" ] && [ -n "$HERDR_PLUGIN_CONFIG_DIR" ] && [ -f "$HERDR_PLUGIN_CONFIG_DIR/.env" ]; then
    HERDR_RELAY=$(grep '^HERDR_RELAY=' "$HERDR_PLUGIN_CONFIG_DIR/.env" | cut -d= -f2- | tr -d '"' | tr -d "'")
    export HERDR_RELAY
fi

RELAY="${HERDR_RELAY:-}"
EVENT="${HERDR_PLUGIN_EVENT_JSON:-{}}"

[ -z "$RELAY" ] && exit 0

# Parse event JSON
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
        host: (env.HOSTNAME // "unknown")
    }')
else
    exit 0
fi

[ -z "$PAYLOAD" ] && exit 0

# Send to relay (convert ws:// to http:// for POST)
HTTP_RELAY=$(echo "$RELAY" | sed 's|^ws://|http://|;s|^wss://|https://|')
curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" --max-time 5 "$HTTP_RELAY" >/dev/null 2>&1

exit 0
