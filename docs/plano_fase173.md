# Plano da Fase 173 — Tina de lavar

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_170_174.md` (laterita, lenha e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`YardView.tub_place`): ao lado de cada varal da Fase 15 (na célula de trás das casas de camponeses e operários),
  `TUB_OUT_M` para longe da casa, fora da roupa pendurada, e `TUB_SIDE_M` para o lado, girada pelo id.
- **A tina** (`YardView.tub_mesh`): a tina de aduelas baixa e larga com dois arcos de ferro, a água ensaboada e a tábua de
  esfregar de pé encostada nela. Mais um MultiMesh da `YardView` (`Washtubs`), com o mesmo alcance de visibilidade das outras
  peças do quintal.

## Como testar

- `tests/presentation/test_phase173_washtubs.gd` (com janela): uma tina por varal, na célula do varal e mais longe da casa que o
  meio dele; a tina é baixa e cabe na metade da célula.
- Captura: `tina_de_lavar.png` no `tools/capture_phase95.tscn`.
