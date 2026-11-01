# Plano da Fase 247 — Madeira curvada no estaleiro

**Estado: feita em 01/11/2026**, a terceira do roteiro `docs/plano_fases_245_249.md` (coelho, cogumelo e pedra, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ShipTimberView.sites`): em cada estaleiro, nas duas células do meio de um lado pelo `SideYard` — o de −X do modelo,
  depois o de trás e por fim o de +X —, nunca no lado do mar, onde desce a carreira da Fase 115 (a fileira de células encostada no
  estaleiro por ali fica tomada, pelo `HarborView.seaward`); guardado pelo `SideYard.remember`. O recheio e as bombas deixam as
  células limpas.
- **A madeira** (`timber_mesh`, `_rib`): a pilha de tábuas compridas junto da parede, em três camadas sobre os dormentes, e na
  frente as cavernas curvas em U deitadas umas sobre as outras, com uma de pé, a abertura para cima, na ponta da pilha; nas cores
  da madeira da carreira (`ShipwayView`). Um MultiMesh.

## Como testar

- `tests/world/test_phase247_ship_timbers.gd`: em cada rotação a madeira fica num lado do estaleiro (nunca na frente), encostada
  nele; com uma célula bloqueada ela muda de lado; o vinhedo não tem; o recheio e as bombas deixam as células; a madeira cabe nas
  duas células.
- Captura: `tools/capture_phase247.tscn` (a ilha plana; `madeira_de_perto.png`, `madeira_e_predio.png`, `madeira_de_longe.png`).
