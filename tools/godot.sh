#!/usr/bin/env bash
# Atalhos do Godot para o Society. Sem tela (esta VM não tem GPU), roda no xvfb com
# Vulkan por software: serve para testar, capturar e exportar, não para medir FPS.
#
#   tools/godot.sh importar            importa os recursos (necessário num clone novo)
#   tools/godot.sh testes [caminho]    suíte gdUnit4 no xvfb (padrão: res://tests)
#   tools/godot.sh rodar               abre o jogo
#   tools/godot.sh editor              abre o editor
#   tools/godot.sh captura [arq] [n]   grava o quadro n do jogo em PNG (padrão: 120)
#   tools/godot.sh exportar [alvo]     windows (padrão) ou linux, em exportado/<alvo>/
#   tools/godot.sh godot [args...]     repassa os argumentos ao binário
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/ferramentas/godot/Godot_v4.7.2-stable_linux.x86_64}"
export GODOT_BIN

if [ ! -x "$GODOT_BIN" ]; then
	echo "Godot não encontrado em $GODOT_BIN (defina GODOT_BIN)." >&2
	exit 1
fi

# Com tela, chama direto; sem tela, dentro do xvfb.
com_tela() {
	if [ -n "${DISPLAY:-}" ]; then
		"$GODOT_BIN" "$@"
	else
		xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT_BIN" "$@"
	fi
}

cd "$RAIZ"
comando="${1:-}"
shift || true

case "$comando" in
	importar)
		"$GODOT_BIN" --headless --path . --import
		;;
	testes)
		# Com tela (xvfb sem DISPLAY): os testes de entrada simulam clique e precisam dela.
		alvo="${1:-res://tests}"
		if [ -n "${DISPLAY:-}" ]; then
			addons/gdUnit4/runtest.sh -a "$alvo"
		else
			xvfb-run -a -s "-screen 0 1920x1080x24" addons/gdUnit4/runtest.sh -a "$alvo"
		fi
		;;
	rodar)
		com_tela --path .
		;;
	editor)
		com_tela --path . --editor
		;;
	captura)
		saida="$(realpath -m "${1:-$RAIZ/captura.png}")"
		quadro="${2:-120}"
		tmp="$(mktemp -d)"
		trap 'rm -rf "$tmp"' EXIT
		com_tela --path . --resolution 1920x1080 --write-movie "$tmp/quadro.png" \
			--fixed-fps 60 --quit-after "$quadro" >/dev/null
		ultimo="$(ls "$tmp"/quadro*.png | sort | tail -1)"
		cp "$ultimo" "$saida"
		echo "$saida"
		;;
	exportar)
		alvo="${1:-windows}"
		case "$alvo" in
			windows) preset="Windows"; arquivo="exportado/windows/Society.exe" ;;
			linux) preset="Linux"; arquivo="exportado/linux/Society.x86_64" ;;
			*) echo "alvo desconhecido: $alvo (windows ou linux)" >&2; exit 2 ;;
		esac
		mkdir -p "$(dirname "$arquivo")"
		"$GODOT_BIN" --headless --path . --export-release "$preset" "$arquivo"
		ls -la "$arquivo"
		;;
	godot)
		com_tela "$@"
		;;
	*)
		sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
		exit 2
		;;
esac
