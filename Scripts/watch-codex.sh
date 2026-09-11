#!/bin/zsh
set -u

support_dir="$HOME/Library/Application Support/CodexWeeklyLimit"
indicator="$HOME/Applications/Codex Limite.app/Contents/MacOS/CodexWeeklyLimit"
disabled="$support_dir/indicator.disabled"
current_uid="$(id -u)"

codex_pid() {
    /bin/ps -axo uid=,pid=,ucomm=,args= | /usr/bin/awk -v uid="$current_uid" \
        '$1 == uid && $3 ~ /^(ChatGPT|Codex)$/ && $0 ~ /\/Contents\/MacOS\/(ChatGPT|Codex)( |$)/ { print $2; exit }'
}

indicator_pid="$(/usr/bin/pgrep -U "$current_uid" -x CodexWeeklyLimit 2>/dev/null | /usr/bin/head -n 1)"

stop_indicator() {
    if [[ -n "$indicator_pid" ]] && /bin/kill -0 "$indicator_pid" 2>/dev/null; then
        /bin/kill -TERM "$indicator_pid" 2>/dev/null || true
        wait "$indicator_pid" 2>/dev/null || true
    fi
    indicator_pid=""
}

while true; do
    current_codex_pid="$(codex_pid)"

    if [[ -n "$current_codex_pid" ]]; then
        if [[ -e "$disabled" && "$(<"$disabled")" != "$current_codex_pid" ]]; then
            /bin/rm -f "$disabled"
        fi
        if [[ -n "$indicator_pid" ]] && ! /bin/kill -0 "$indicator_pid" 2>/dev/null; then
            indicator_pid=""
        fi
        if [[ ! -e "$disabled" && -x "$indicator" && -z "$indicator_pid" ]]; then
            "$indicator" >/dev/null 2>&1 &
            indicator_pid=$!
        fi
    else
        /bin/rm -f "$disabled"
        stop_indicator
    fi
    /bin/sleep 2
done
