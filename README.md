# herdr-remote

herdr plugin that pushes agent status events to a remote relay for mobile and desktop monitoring.

## Install

```bash
herdr plugin install dcolinmorgan/herdr-remote
```

## Configure

Set the relay URL (Cloudflare tunnel, LAN, or Tailscale):

```bash
export HERDI_RELAY_HOST="wss://your-tunnel.trycloudflare.com"
# or LAN:
export HERDI_RELAY_HOST="ws://192.168.1.x:8375"

launchctl setenv HERDI_RELAY_HOST "$HERDI_RELAY_HOST"  # macOS
herdr server reload-config
```

No herdr restart required.

## How it works

On every agent status change (`idle` → `working` → `blocked`), this plugin pushes the event to your relay. The relay broadcasts to connected clients:

- 📱 iOS app
- 🖥️ macOS menu bar app ([herdi](https://github.com/dcolinmorgan/herdi))
- 💬 Telegram bot
- 🖲️ Terminal TUI

Event-driven — no polling, no SSH, no inbound ports required on the monitored machine.

## Requirements

- `websockets` Python package (for `ws://` or `wss://` relay)
- Or nothing extra (falls back to UDP for local relay)

```bash
pip install websockets
```
