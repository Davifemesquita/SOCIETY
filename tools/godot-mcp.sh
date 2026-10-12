#!/usr/bin/env bash
# Binário do Godot visto pelo Godot MCP (.mcp.json). Sem tela, abre jogo e editor
# no xvfb; consultas headless e --version vão direto, sem custo de servidor X.
GODOT_BIN="${GODOT_BIN:-$HOME/ferramentas/godot/Godot_v4.7.2-stable_linux.x86_64}"
if [ -n "${DISPLAY:-}" ]; then
	exec "$GODOT_BIN" "$@"
fi
for arg in "$@"; do
	case "$arg" in
		--version|--headless) exec "$GODOT_BIN" "$@" ;;
	esac
done
exec xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT_BIN" "$@"
