# herdr-push

herdr plugin that pushes agent status events to [herdr-remote](https://github.com/dcolinmorgan/herdr-remote) for mobile and desktop monitoring.

## Install

```bash
herdr plugin install dcolinmorgan/herdr-push
```

## Configure

Set the relay URL (Cloudflare tunnel, LAN, or Tailscale):

```bash
export HERDR_RELAY="wss://your-tunnel.trycloudflare.com"
# or LAN:
export HERDR_RELAY="http://192.168.1.x:8375"

launchctl setenv HERDR_RELAY "$HERDR_RELAY"  # macOS
herdr server reload-config
```

No herdr restart required.

## How it works

On every agent status change (`idle` → `working` → `blocked`), this plugin pushes the event via HTTP POST (just curl — zero external deps) to your relay.

The relay broadcasts to connected clients:

- 🖥️ macOS menu bar app
- 💬 Telegram bot
- 🖲️ Terminal TUI

Event-driven — no polling, no SSH, no inbound ports on the monitored machine.

## Zero dependencies

Uses `curl` for HTTP POST. No pip packages needed. Falls back to UDP for local relay.
