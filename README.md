# herdr-push

herdr plugin that pushes agent status events to [herdr-remote](https://github.com/dcolinmorgan/herdr-remote) for mobile and desktop monitoring + approval.

## Install

```bash
herdr plugin install dcolinmorgan/herdr-push
```

## Configure

```bash
# Option 1: environment variable
export HERDR_RELAY="https://your-tunnel.trycloudflare.com"
launchctl setenv HERDR_RELAY "$HERDR_RELAY"  # macOS persist
herdr server reload-config

# Option 2: plugin config file (herdr standard)
echo 'HERDR_RELAY=https://your-tunnel.trycloudflare.com' > "$(herdr plugin config-dir herdr.push)/.env"
```

## Test

```bash
herdr plugin action invoke herdr.push test
```

## How it works

```
agent status changes → herdr fires pane.agent_status_changed
  → on_event.sh reads HERDR_PLUGIN_EVENT_JSON (standard herdr env)
  → curl POST to your relay
  → relay broadcasts to all connected clients
```

Uses standard herdr plugin conventions:
- `HERDR_PLUGIN_EVENT_JSON` for event data
- `HERDR_PLUGIN_CONTEXT_JSON` for workspace/tab context
- `HERDR_PLUGIN_CONFIG_DIR/.env` for persistent config
- `HERDR_BIN_PATH` available for calling herdr back

## Zero dependencies

Shell script + `curl`. Uses `python3` or `jq` (whichever is available) for JSON parsing. Nothing to install beyond the plugin itself.

## Quick tunnel setup (no account needed)

On your Mac (where you want to monitor from):
```bash
git clone https://github.com/dcolinmorgan/herdr-remote && cd herdr-remote/relay
python3 -m venv .venv && .venv/bin/pip install websockets
.venv/bin/python3 herdr_relay.py &
cloudflared tunnel --url http://localhost:8375
# → gives you https://something.trycloudflare.com
```

Then on any machine running herdr:
```bash
herdr plugin install dcolinmorgan/herdr-push
echo "HERDR_RELAY=https://something.trycloudflare.com" > "$(herdr plugin config-dir herdr.push)/.env"
herdr plugin action invoke herdr.push test
```

## Clients

Once events are flowing, monitor from:
- 🖥️ [macOS menu bar app](https://github.com/dcolinmorgan/herdr-remote/releases)
- 🌐 [Web app](https://herdr-remote.pages.dev) (phone browser)
- 💬 Telegram bot
- 🖲️ Terminal TUI
