# herdr-push

herdr plugin that pushes agent status events to [herdr-remote](https://github.com/dcolinmorgan/herdr-remote) for mobile and desktop monitoring + approval.

## Install

```bash
herdr plugin install dcolinmorgan/herdr-push
```

## Configure

Set the relay URL and reload:

```bash
export HERDR_RELAY="https://your-tunnel.trycloudflare.com"
launchctl setenv HERDR_RELAY "$HERDR_RELAY"  # macOS persist
herdr server reload-config
```

**Quick tunnel** (no account needed):
```bash
# On the machine running herdr-remote relay:
cloudflared tunnel --url http://localhost:8375
```

## How it works

```
herdr agent status changes → plugin fires → curl POST to relay → clients notified
```

On every status change (`idle` → `working` → `blocked`), this plugin POSTs the event to your relay. Connected clients can then approve or respond to blocked agents.

## Zero dependencies

Uses `curl` + `python3` or `jq` (whichever is available) for JSON. Nothing to `pip install`.

## What's herdr-remote?

The relay + client suite that receives events from this plugin:

- 🖥️ macOS menu bar app — see agents, approve with one click
- 💬 Telegram bot — approve from your phone
- 🖲️ Terminal TUI — kanban dashboard in your terminal
- 📱 iOS app (coming)

Install: [github.com/dcolinmorgan/herdr-remote](https://github.com/dcolinmorgan/herdr-remote)
