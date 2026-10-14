# Society

City builder 3D de economia e logística no século XIX, em Godot 4.7 (Forward+), para PC
Windows. O jogador governa um arquipélago que vai do campo à indústria entre 1800 e 1880.

A especificação inteira está em [`docs/especificacao.pdf`](docs/especificacao.pdf). O
contexto de trabalho e o estado das fases estão no [`AGENTS.md`](AGENTS.md).

```bash
tools/godot.sh importar      # uma vez, num clone novo
tools/godot.sh testes        # suíte gdUnit4 headless
tools/godot.sh rodar         # abre o jogo
tools/godot.sh exportar      # exportado/windows/Society.exe
tools/godot.sh planilha      # CSV de balanceamento a partir dos dados
```

O jogo abre no menu principal (continuar, jogo novo com semente, tamanho do arquipélago e
dificuldade, carregar, opções e créditos). No executável: `Society.exe -- --benchmark` mede o
desempenho no PC.
