# herdi-push

herdr plugin that pushes agent status events to [herdi](https://github.com/dcolinmorgan/herdi) for mobile and remote monitoring.

## Install

```bash
herdr plugin install dcolinmorgan/herdi-push
```

## Configure

Set the relay URL (your herdi relay or Cloudflare tunnel):

```bash
export HERDI_RELAY_HOST="wss://your-tunnel.trycloudflare.com"
# or for LAN:
export HERDI_RELAY_HOST="ws://192.168.1.x:8375"

launchctl setenv HERDI_RELAY_HOST "$HERDI_RELAY_HOST"  # macOS
herdr server reload-config
```

No herdr restart required.

## How it works

On every agent status change (`idle` → `working` → `blocked`), this plugin pushes the event to your herdi relay. The relay broadcasts to all connected clients:

- 📱 iOS app
- 🖥️ macOS menu bar app
- 💬 Telegram bot
- 🖲️ Terminal TUI

Event-driven — no polling, no SSH, no inbound ports required.

## Requirements

- `websockets` Python package (for `ws://` or `wss://` relay)
- Or nothing extra (falls back to UDP for local relay)

```bash
pip install websockets
```
