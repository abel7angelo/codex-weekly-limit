#!/bin/zsh
set -u

support_dir="$HOME/Library/Application Support/ClaudeUsageLimit"
indicator="$HOME/Applications/Claude Limite.app/Contents/MacOS/ClaudeUsageLimit"
disabled="$support_dir/indicator.disabled"
current_uid="$(id -u)"

# Acompanha o app Claude para desktop ou uma sessão do Claude Code no Terminal.
claude_pid() {
    /bin/ps -axo uid=,pid=,ucomm=,args= | /usr/bin/awk -v uid="$current_uid" '
        $1 != uid { next }
        $3 == "Claude" && $4 ~ /\.app\/Contents\/MacOS\/Claude$/ { print $2; exit }
        $3 == "claude" { print $2; exit }
        $3 == "node" && $0 ~ /\/(bin\/claude|@anthropic-ai\/claude-code\/cli\.js)( |$)/ { print $2; exit }
    '
}

indicator_pid="$(/usr/bin/pgrep -U "$current_uid" -x ClaudeUsageLimit 2>/dev/null | /usr/bin/head -n 1)"

stop_indicator() {
    if [[ -n "$indicator_pid" ]] && /bin/kill -0 "$indicator_pid" 2>/dev/null; then
        /bin/kill -TERM "$indicator_pid" 2>/dev/null || true
        wait "$indicator_pid" 2>/dev/null || true
    fi
    indicator_pid=""
}

while true; do
    current_claude_pid="$(claude_pid)"

    if [[ -n "$current_claude_pid" ]]; then
        if [[ -e "$disabled" && "$(<"$disabled")" != "$current_claude_pid" ]]; then
            /bin/rm -f "$disabled"
        fi
        if [[ -n "$indicator_pid" ]] && ! /bin/kill -0 "$indicator_pid" 2>/dev/null; then
            indicator_pid=""
        fi
        if [[ ! -e "$disabled" && -x "$indicator" && -z "$indicator_pid" ]]; then
            CLAUDE_LIMIT_HOST_PID="$current_claude_pid" "$indicator" >/dev/null 2>&1 &
            indicator_pid=$!
        fi
    else
        /bin/rm -f "$disabled"
        stop_indicator
    fi
    /bin/sleep 2
done
