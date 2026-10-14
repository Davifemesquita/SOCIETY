#!/usr/bin/env bash
# Baixa do game-icons.net (CC BY 3.0) os SVGs da lista de ícones para assets/source/game-icons/.
# Depois: tools/godot.sh godot --headless --path . --script res://tools/build_icons.gd
set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"
fontes=$(tail -n +2 tools/icons/icon_list.csv | cut -d, -f2 | grep -v "^@"; echo delapouite/scroll-quill)
for fonte in $(echo "$fontes" | sort -u); do
	destino="assets/source/game-icons/$fonte.svg"
	[ -f "$destino" ] && continue
	mkdir -p "$(dirname "$destino")"
	curl -sfL -o "$destino" "https://raw.githubusercontent.com/game-icons/icons/master/$fonte.svg"
done
