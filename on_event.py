#!/usr/bin/env python3
"""Push agent status change to herdi relay."""
import json, os, socket

RELAY = os.environ.get("HERDI_RELAY_HOST", "")
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

if RELAY.startswith("ws"):
    import subprocess, sys
    subprocess.run([sys.executable, "-c", f"""
import asyncio, websockets
async def push():
    async with websockets.connect("{RELAY}", open_timeout=3, close_timeout=1) as ws:
        await ws.send('''{payload}''')
asyncio.run(push())
"""], capture_output=True, timeout=5)
else:
    host, port = (RELAY or "127.0.0.1:8376").rsplit(":", 1)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.sendto(payload.encode(), (host, int(port)))
    sock.close()
