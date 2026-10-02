#!/bin/zsh
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_app="${1:-$root_dir/dist/Claude Limite.app}"

if [[ "$(/usr/sbin/sysctl -in hw.optional.arm64)" != "1" ]]; then
    print -u2 "Este recurso suporta somente Macs Apple Silicon."
    exit 1
fi

if ! /usr/bin/xcrun --find swiftc >/dev/null 2>&1; then
    print -u2 "Swift não encontrado. Instale as Xcode Command Line Tools e tente novamente."
    exit 1
fi

if [[ "$output_app" != /* ]]; then
    output_app="$PWD/$output_app"
fi

output_dir="$(dirname "$output_app")"
mkdir -p "$output_dir"
output_app="$(cd "$output_dir" && pwd)/$(basename "$output_app")"

if [[ "$(basename "$output_app")" != *.app || "$(basename "$output_app")" == ".app" ]]; then
    print -u2 "O destino precisa ser um aplicativo .app."
    exit 1
fi

if [[ "$output_app" == "/" || "$output_app" == "$HOME" || "$output_app" == "$root_dir" || -L "$output_app" ]]; then
    print -u2 "Destino de compilação inválido."
    exit 1
fi

build_dir="$(mktemp -d /tmp/claude-usage-limit-build.XXXXXX)"
trap '/bin/rm -rf "$build_dir"' EXIT

staging_app="$build_dir/Claude Limite.app"
mkdir -p "$staging_app/Contents/MacOS"

/usr/bin/arch -arm64 /usr/bin/xcrun --sdk macosx swiftc -O -framework Cocoa \
    "$root_dir/Sources/main.swift" \
    -o "$staging_app/Contents/MacOS/ClaudeUsageLimit"

cp "$root_dir/Resources/Info.plist" "$staging_app/Contents/Info.plist"

/usr/bin/codesign --force --deep --sign - "$staging_app" >/dev/null
/usr/bin/codesign --verify --deep --strict "$staging_app"

previous_app="$build_dir/previous.app"
if [[ -e "$output_app" ]]; then
    /bin/mv "$output_app" "$previous_app"
fi

if ! /bin/mv "$staging_app" "$output_app"; then
    if [[ -e "$previous_app" ]]; then
        /bin/mv "$previous_app" "$output_app"
    fi
    print -u2 "Não foi possível instalar o aplicativo compilado."
    exit 1
fi

print "Aplicativo Apple Silicon criado em: $output_app"
