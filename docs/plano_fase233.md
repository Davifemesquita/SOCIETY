# Plano da Fase 233 — Cabines de banho

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_230_234.md` (sinal, cormorão e castanha, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BathingMachineView.cells`, `place_of`): nas ilhas temperadas com relevo, perto de cada entreposto — além do cais de
  pedra, pela mesma conta dos guarda-sóis de palha da Fase 204 (`PalapaView.near_of`) —, até `PER_POST` células de areia livre
  junto do mar (`PalapaView._sand`), as mais perto do entreposto, a `SPACING_CELLS` ou mais umas das outras e fora das redes e do
  barco na areia; a porta virada para a célula de mar mais perto. O recheio deixa as células limpas.
- **A cabine** (`machine_mesh`): a cabine de banho de época sobre quatro rodas de raios, o chassi, as paredes de lona em listras
  vermelhas e brancas (vistas dos dois lados), o teto de tábuas em arco com os oitões brancos, a porta escura com a capota de lona
  vermelha e a escadinha até a areia. Um MultiMesh; nas tropicais seguem os guarda-sóis de palha.

## Como testar

- `tests/world/test_phase233_bathing_machines.gd`: na semente 1840, perto do entreposto, as cabines ficam em areia livre junto do
  mar, até `PER_POST`, afastadas, com a porta para o mar; a ilha plana não tem; a cabine fica de pé nas rodas.
- Captura: `tools/capture_phase233.tscn` (o entreposto da semente 1840; `cabine_N_do_mar.png`, `cabine_N_da_terra.png`,
  `cabines_longe.png`).
