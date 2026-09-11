#!/bin/zsh
set -u

support_dir="$HOME/Library/Application Support/CodexWeeklyLimit"
indicator="$HOME/Applications/Codex Limite.app/Contents/MacOS/CodexWeeklyLimit"
disabled="$support_dir/indicator.disabled"

codex_running() {
    /bin/ps -axo ucomm=,args= | /usr/bin/awk '$1 ~ /^(ChatGPT|Codex)$/ && $0 ~ /\/Contents\/MacOS\/(ChatGPT|Codex)( |$)/ { found = 1 } END { exit found ? 0 : 1 }'
}

while true; do
    if codex_running; then
        if [[ ! -e "$disabled" && -x "$indicator" ]] && ! /usr/bin/pgrep -x CodexWeeklyLimit >/dev/null 2>&1; then
            "$indicator" >/dev/null 2>&1 &
        fi
    else
        /bin/rm -f "$disabled"
        /usr/bin/pkill -TERM -x CodexWeeklyLimit >/dev/null 2>&1 || true
    fi
    /bin/sleep 2
done
