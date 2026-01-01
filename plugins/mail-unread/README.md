# mail-unread

Shows unread count from Apple Mail **Inbox** (sum across all accounts) in the menu bar.

Local-only: no credentials, no network calls.

## What it counts
- Counts unread messages in each account's **Inbox**.
- Unread messages moved out of Inbox (rules/filters) are not counted.

## Permissions
Requires macOS Automation permission: SwiftBar → Mail.

## Install
#### Manual install
Copy `mail-unread.1m.sh` into your SwiftBar Plugin Folder and make it executable:
`chmod +x mail-unread.1m.sh`

#### One-click install (SwiftBar installed)
Copy and paste the following URL into your browser:
`swiftbar://addplugin?src=https://raw.githubusercontent.com/silasnevstad/swiftbar-plugins/main/plugins/mail-unread/mail-unread.1m.sh`

## Refresh interval
Default: every 1 minutes (`.1m`).
To update every 5 minutes, rename to `mail-unread.5m.sh`.

## Performance
- ~0.09–0.10s wall-clock per execution
- ~0.03–0.04s CPU time per run
- One `osascript` invocation; no persistent background processes
- No network calls in the script;
- No measurable energy impact

At a 1-minute refresh interval, this amounts to ~6 seconds of total execution time per hour.

## Configuration (optional)
Environment variables you can override:

- `SHOW_ZERO=true` — show `0` next to the icon when there are no unread messages
- `SCRIPT_TIMEOUT_SECONDS=5` — increase timeout if Mail is slow or heavily loaded