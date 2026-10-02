#!/bin/zsh
set -euo pipefail

app="$HOME/Applications/Claude Limite.app"
support_dir="$HOME/Library/Application Support/ClaudeUsageLimit"
launch_agent="$HOME/Library/LaunchAgents/local.claude.usage-limit.plist"
agent_label="gui/$(id -u)/local.claude.usage-limit"

launchctl bootout "$agent_label" 2>/dev/null || true
/usr/bin/pkill -TERM -U "$(id -u)" -x ClaudeUsageLimit >/dev/null 2>&1 || true
rm -rf "$app" "$support_dir" "$launch_agent"
print "Claude Limite removido desta conta do macOS."
