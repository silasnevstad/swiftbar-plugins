#!/bin/bash
# <xbar.title>Mail Unread (Apple Mail)</xbar.title>
# <xbar.version>1.0.0</xbar.version>
# <xbar.author>Silas Nevstad</xbar.author>
# <xbar.author.github>silasnevstad</xbar.author.github>
# <xbar.desc>Unread Inbox count from Apple Mail (all accounts). Local-only; no credentials.</xbar.desc>
# <xbar.dependencies>bash,osascript</xbar.dependencies>
# <xbar.abouturl>https://github.com/silasnevstad/swiftbar-plugins</xbar.abouturl>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

set -u

# Config (override via env if needed)
SHOW_ZERO="${SHOW_ZERO:-false}"                 # show "0" when no unread
SCRIPT_TIMEOUT_SECONDS="${SCRIPT_TIMEOUT_SECONDS:-3}"

ICON_UNREAD="${ICON_UNREAD:-envelope.badge.fill}"
ICON_ZERO="${ICON_ZERO:-envelope}"
ICON_ERROR="${ICON_ERROR:-envelope}"

# Helpers
is_uint() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

sanitize_bool() {
  case "${1:-}" in
    true|TRUE|True|1|yes|YES|Yes) echo "true" ;;
    *) echo "false" ;;
  esac
}

sanitize_timeout() {
  [[ "${1:-}" =~ ^[0-9]+$ ]] && echo "$1" || echo 3
}

sanitize_symbol() {
  [[ "${1:-}" =~ ^[A-Za-z0-9._-]+$ ]] && echo "$1" || echo "$2"
}

# Normalize config
SHOW_ZERO="$(sanitize_bool "$SHOW_ZERO")"
SCRIPT_TIMEOUT_SECONDS="$(sanitize_timeout "$SCRIPT_TIMEOUT_SECONDS")"
ICON_UNREAD="$(sanitize_symbol "$ICON_UNREAD" "envelope.badge.fill")"
ICON_ZERO="$(sanitize_symbol "$ICON_ZERO" "envelope")"
ICON_ERROR="$(sanitize_symbol "$ICON_ERROR" "envelope")"

# Detect SF Symbols support
SUPPORTS_SFIMAGE="true"
OS_MAJOR="${OS_VERSION_MAJOR:-}"
if ! is_uint "$OS_MAJOR"; then
  VER="$(/usr/bin/sw_vers -productVersion 2>/dev/null || echo "")"
  OS_MAJOR="${VER%%.*}"
fi
if is_uint "$OS_MAJOR" && (( OS_MAJOR < 11 )); then
  SUPPORTS_SFIMAGE="false"
fi

# Query Mail
# Returns:
#   uint  = unread count
#   -1    = Mail not running
#   -2    = timed out
#   E:<n> = AppleScript/AppleEvent error number
get_inbox_unread_count() {
  /usr/bin/osascript - "$SCRIPT_TIMEOUT_SECONDS" <<'APPLESCRIPT'
on run argv
  set t to 3
  try
    if (count of argv) > 0 then set t to (item 1 of argv) as integer
  end try

  if application "Mail" is not running then return "-1"

  try
    if t > 0 then
      with timeout of t seconds
        tell application "Mail"
          return (unread count of inbox) as text
        end tell
      end timeout
    else
      tell application "Mail"
        return (unread count of inbox) as text
      end tell
    end if
  on error errMsg number errNum
    if errNum is -1712 then return "-2"
    return "E:" & errNum
  end try
end run
APPLESCRIPT
}

RAW_OUT="$(get_inbox_unread_count 2>/dev/null)"
RC=$?
RAW_OUT="${RAW_OUT//[[:space:]]/}"

STATUS="ok"
COUNT=0
ERR_CODE=""

if [[ $RC -ne 0 ]]; then
  STATUS="error"
  ERR_CODE="osascript_exit_${RC}"
elif [[ "$RAW_OUT" == "-1" ]]; then
  STATUS="mail_not_running"
elif [[ "$RAW_OUT" == "-2" ]]; then
  STATUS="timeout"
elif [[ "$RAW_OUT" == E:* ]]; then
  STATUS="error"
  ERR_CODE="${RAW_OUT#E:}"
elif is_uint "$RAW_OUT"; then
  COUNT="$RAW_OUT"
else
  STATUS="error"
  ERR_CODE="bad_output"
fi

print_header() {
  local title="$1"
  local symbol="$2"

  if [[ "$SUPPORTS_SFIMAGE" == "true" ]]; then
    printf '%s | sfimage=%s dropdown=false\n' "$title" "$symbol"
  else
    # Fallback (e.g. macOS 10.15 / hosts without sfimage support)
    if [[ -n "$title" ]]; then
      printf '%s ✉︎ | dropdown=false\n' "$title"
    else
      printf '✉︎ | dropdown=false\n'
    fi
  fi
}

# Menu bar header
case "$STATUS" in
  error)
    print_header "?" "$ICON_ERROR"
    ;;
  timeout)
    print_header "…" "$ICON_ERROR"
    ;;
  *)
    if (( COUNT > 0 )); then
      print_header "$COUNT" "$ICON_UNREAD"
    else
      if [[ "$SHOW_ZERO" == "true" ]]; then
        print_header "0" "$ICON_ZERO"
      else
        print_header "" "$ICON_ZERO"
      fi
    fi
    ;;
esac

echo "---"

# Use bundle id to avoid localization / renames
echo "Open Mail | bash=/usr/bin/open param1=-b param2=com.apple.mail terminal=false"
echo "Refresh | refresh=true"

case "$STATUS" in
  ok)
    echo "Unread in Inbox: ${COUNT}"
    ;;
  mail_not_running)
    echo "Mail.app is not running."
    ;;
  timeout)
    echo "⚠️ Timed out querying Mail.app."
    echo "Try: SCRIPT_TIMEOUT_SECONDS=5"
    ;;
  *)
    echo "⚠️ Could not query Mail.app."
    [[ -n "$ERR_CODE" ]] && echo "Error: ${ERR_CODE}"
    echo "Check: System Settings → Privacy & Security → Automation → SwiftBar → Mail"
    echo "If Mail is slow, try: SCRIPT_TIMEOUT_SECONDS=5"
    ;;
esac
