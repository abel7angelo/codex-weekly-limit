#!/bin/zsh
set -euo pipefail

app="$HOME/Applications/Codex Limite.app"
support_dir="$HOME/Library/Application Support/CodexWeeklyLimit"
launch_agent="$HOME/Library/LaunchAgents/local.codex.weekly-limit.plist"
agent_label="gui/$(id -u)/local.codex.weekly-limit"

launchctl bootout "$agent_label" 2>/dev/null || true
/usr/bin/pkill -TERM -x CodexWeeklyLimit >/dev/null 2>&1 || true
rm -rf "$app" "$support_dir" "$launch_agent"
print "Codex Limite removido desta conta do macOS."
