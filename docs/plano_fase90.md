# Plano da Fase 90 — Daltônico no Windows

**Estado: feita em 28/10/2026**, a primeira do roteiro `docs/plano_fases_90_93.md`.

## O que se achou

- A pendência do `AGENTS.md` dizia que `tests/ui/test_menus.gd` → `test_colorblind_option_repaints_the_house_needs`
  falhava no Windows do dono (25/10/2026, "a cor do marcador não muda") e passava no CI, "não investigado".
- Hoje o teste passou quatro vezes seguidas com janela, na área de trabalho escondida.
- A causa já tinha sido corrigida em 26/10/2026 (`2f735e3`, "Testes com janela no PC do dono: dois consertos de tempo"):
  o painel do selecionado só repintava no refresco de 0,25 s, e o teste esperava 10 quadros — no lavapipe do CI isso
  passa de 0,25 s, na GPU do dono não. Desde então o painel repinta na hora em que uma opção muda
  (`EventBus.settings_changed`). Só faltou tirar a pendência da lista.
- Hipóteses descartadas no caminho: a cor neutra (`5c4a36`) é igual nas duas paletas, mas os marcadores das necessidades
  só usam bom, parcial e ruim, que mudam; o painel fica visível na hora (`show_building`).

## O que mudou

- A pendência saiu do `AGENTS.md`.
- A suíte inteira foi conferida no PC do dono: com janela (área de trabalho escondida) presentation 235 e ui 167 casos;
  sem janela core 57, data 18, sim 367, tools 15 e world 127. **986 casos, nenhum vermelho.**

## Como testar

- `powershell -File F:\ferramentas\testes_janela_oculta.ps1 res://tests/ui/test_menus.gd`
- `powershell -File F:\ferramentas\testes_society.ps1` (sem janela) e `testes_janela_oculta.ps1 res://tests/presentation`
  e `res://tests/ui` (com janela).
