# Plano da Fase 223 — Lençóis no hospital

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_220_224.md` (bomba, barril e lençol, a partir das capturas do Anno
do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`LinenView.sites`, `cells`): em cada hospital, as duas células do meio do lado de −X do modelo, depois o de +X e por
  fim o de trás, pelo `SideYard` (guardado pelo `SideYard.remember`), fora dos pátios de lado de antes. O recheio e as bombas as
  deixam limpas.
- **Os varais** (`linen_mesh`, `_sheet`): dois varais compridos ao longo da parede em postes de madeira com a travessa, o arame e
  `SHEETS` lençóis brancos em cada um, enfunados de leve no meio, com a barra de baixo ondulando pela fase de cada lençol e a dobra
  mais escura embaixo; o cesto de vime com a roupa no chão. O material sem descarte de face (o lençol é uma folha só). Um
  MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase223_linen.gd`: nas quatro rotações os varais ficam de lado, encostados no hospital, nunca na frente; com
  uma das células bloqueada, vão para o outro lado; outros prédios não têm; o recheio e as bombas deixam as células; a malha cabe
  nas duas células, a barra do lençol fica longe do chão e os lençóis cabem no varal.
- Captura: `tools/capture_phase223.tscn` (dois hospitais na ilha plana; `lencois_de_perto.png`, `lencois_e_hospital.png`,
  `lencois_de_longe.png`).
