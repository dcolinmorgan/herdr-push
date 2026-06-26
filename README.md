# herdr-push

herdr plugin: push agent status to [herdr-remote](https://github.com/dcolinmorgan/herdr-remote) for mobile monitoring and one-tap approval.

**Zero dependencies** — uses `curl` + system Python or `jq`. Nothing to install beyond the plugin.

## Install

```bash
herdr plugin install dcolinmorgan/herdr-push
```

## Configure

```bash
# Option 1: plugin config file (recommended)
echo 'HERDR_RELAY=https://your-tunnel.trycloudflare.com' > "$(herdr plugin config-dir herdr.push)/.env"

# Option 2: environment variable
export HERDR_RELAY="https://your-tunnel.trycloudflare.com"
launchctl setenv HERDR_RELAY "$HERDR_RELAY"
herdr server reload-config
```

## Test

```bash
herdr plugin action invoke herdr.push test
```

## How it works

```
agent blocks → herdr fires pane.agent_status_changed
  → on_event.sh reads HERDR_PLUGIN_EVENT_JSON
  → curl POST to your relay
  → relay broadcasts to phone/desktop/Telegram
  → you tap "approve" → agent continues
```

Uses standard herdr plugin conventions:
- `HERDR_PLUGIN_EVENT_JSON` / `HERDR_PLUGIN_CONTEXT_JSON`
- `HERDR_PLUGIN_CONFIG_DIR/.env` for persistent config

## Get a relay URL

On your Mac (or any machine):

```bash
git clone https://github.com/dcolinmorgan/herdr-remote
cd herdr-remote/relay && ./start.sh
# → prints wss:// URL
```

Then open [herdr-remote.pages.dev](https://herdr-remote.pages.dev) on your phone and paste the URL.

## What you get

- Approve blocked agents from your phone
- macOS menu bar status + approval
- Telegram bot with inline buttons (works on Apple Watch)
- Browser notifications when agents need you
- 11 themes
