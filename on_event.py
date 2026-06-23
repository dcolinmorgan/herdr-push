#!/usr/bin/env python3
"""Push agent status change to herdr-remote relay. Zero external deps."""
import json, os, socket, subprocess

RELAY = os.environ.get("HERDR_RELAY", os.environ.get("HERDR_RELAY_HOST", ""))
event = json.loads(os.environ.get("HERDR_PLUGIN_EVENT_JSON", "{}"))
data = event.get("data", {})

payload = json.dumps({
    "type": "agent_event",
    "pane_id": data.get("pane_id", ""),
    "status": (data.get("agent_status") or "").lower(),
    "agent": (data.get("agent") or data.get("display_agent") or "").lower(),
    "project": os.path.basename(data.get("cwd", "")),
    "cwd": data.get("cwd", ""),
    "host": socket.gethostname().split(".")[0],
})

if RELAY.startswith("ws://") or RELAY.startswith("wss://"):
    # Convert ws(s):// to http(s):// for curl POST
    http_url = RELAY.replace("ws://", "http://", 1).replace("wss://", "https://", 1)
    subprocess.run(
        ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
         "-d", payload, "--max-time", "5", http_url],
        capture_output=True, timeout=7
    )
elif RELAY.startswith("http"):
    subprocess.run(
        ["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json",
         "-d", payload, "--max-time", "5", RELAY],
        capture_output=True, timeout=7
    )
else:
    # UDP fallback for local relay
    host, port = (RELAY or "127.0.0.1:8376").rsplit(":", 1)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(payload.encode(), (host, int(port)))
    sock.close()
