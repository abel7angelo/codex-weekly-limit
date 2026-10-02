#!/bin/zsh
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
app="$HOME/Applications/Claude Limite.app"
support_dir="$HOME/Library/Application Support/ClaudeUsageLimit"
launch_agent="$HOME/Library/LaunchAgents/local.claude.usage-limit.plist"
agent_domain="gui/$(id -u)"
agent_label="$agent_domain/local.claude.usage-limit"
agent_tmp="$(mktemp /tmp/claude-usage-limit-agent.XXXXXX)"
agent_backup="$(mktemp /tmp/claude-usage-limit-agent-backup.XXXXXX)"
had_agent=false

cleanup() {
    /bin/rm -f "$agent_tmp" "$agent_backup"
}
trap cleanup EXIT

if [[ "$(/usr/sbin/sysctl -in hw.optional.arm64)" != "1" ]]; then
    print -u2 "Este recurso suporta somente Macs Apple Silicon."
    exit 1
fi

mkdir -p "$HOME/Applications" "$support_dir" "$HOME/Library/LaunchAgents"
"$root_dir/Scripts/build-app.sh" "$app"
cp "$root_dir/Scripts/watch-claude.sh" "$support_dir/watch-claude.sh"
chmod 755 "$support_dir/watch-claude.sh"

if [[ -f "$launch_agent" ]]; then
    cp "$launch_agent" "$agent_backup"
    had_agent=true
fi

cat > "$agent_tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.claude.usage-limit</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>$support_dir/watch-claude.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

/usr/bin/plutil -lint "$agent_tmp" >/dev/null
/bin/mv "$agent_tmp" "$launch_agent"
/bin/rm -f "$support_dir/indicator.disabled"

/bin/launchctl bootout "$agent_label" 2>/dev/null || true
/usr/bin/pkill -TERM -U "$(id -u)" -x ClaudeUsageLimit >/dev/null 2>&1 || true
if ! /bin/launchctl bootstrap "$agent_domain" "$launch_agent"; then
    /bin/rm -f "$launch_agent"
    if "$had_agent"; then
        /bin/mv "$agent_backup" "$launch_agent"
        /bin/launchctl bootstrap "$agent_domain" "$launch_agent" 2>/dev/null || true
    fi
    print -u2 "Não foi possível ativar o LaunchAgent do indicador."
    exit 1
fi

print "Instalação concluída. O indicador acompanha o Claude nesta conta do macOS."
