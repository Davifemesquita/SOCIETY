# Plano da Fase 215 — Tábuas secando na serraria

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_215_219.md` (tábua, cortina e andorinha, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`PlankStackView.sites`, `cells`): em cada serraria, as duas células do meio de um lado, encostadas nela: o de −X do
  modelo, oposto à roda d'água da Fase 13 (que fica em +X), e, se ele não der, o de trás. As células têm de ser de terra, sem
  prédio, estrada, trilho nem árvore, fora do largo e da alameda e quase planas. O recheio e as bombas as deixam limpas.
- **As pilhas** (`stack_mesh`): uma por célula, encostada na parede, com as tábuas ao longo dela em `LAYERS` camadas de `BOARDS`
  tábuas (um tom por tábua), os tabiques de través entre as camadas para o ar passar, sobre três dormentes, e três tábuas velhas
  inclinadas por cima contra a chuva; na frente, uma pilha mais baixa e sem cobertura. Um MultiMesh.

## Como testar

- `tests/world/test_phase215_plank_stacks.gd`: nas quatro rotações as pilhas ficam encostadas na serraria e do lado oposto à roda
  d'água; com uma das células bloqueada, vão para os fundos; outros prédios não têm; o recheio e as bombas deixam as células; a
  malha cabe na célula e fica de pé no chão.
- Captura: `tools/capture_phase215.tscn` (duas serrarias na ilha plana; `tabuas_de_perto.png`, `tabuas_e_roda.png`,
  `tabuas_de_longe.png`).
