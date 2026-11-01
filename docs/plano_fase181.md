# Plano da Fase 181 — Caixa de correio

**Estado: feita em 31/10/2026**, do roteiro `docs/plano_fases_180_184.md` (borboleta, correio e galo, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`PostBoxView.spots`): numa célula de paralelepípedo a cada tantas pelo desenho da grade
  (`posmod(7x + 13y, POST_EVERY) == POST_REST`, sem sorteio), fora das células dos postes de gás (`LampView.LAMP_EVERY`) e da
  escada diagonal, encostada no lado da calçada como o poste (`LampView._sidewalk_side`, `LAMP_OFFSET_M`), a boca virada para o
  meio da rua.
- **A caixa** (`box_mesh`): sólido de revolução (`_lathe`, no mesmo sentido do `VertexShapes.cylinder`) — o soco escuro, o
  fuste vermelho, o rebordo e o chapéu abaulado com o botão —, a boca escura com a aba e a plaquinha clara dos horários. Um
  MultiMesh (`GameScreen.post_box_view`), refeito quando as estradas mudam e ao trocar de mundo.

## Como testar

- `tests/world/test_phase181_post_boxes.gd`: só nas células calçadas do desenho certo, fora das dos postes; no lado da calçada,
  virada para a rua; nenhuma na rua de terra; a altura e o raio da caixa.
- Captura: `caixa_de_correio.png` no `tools/capture_phase150.tscn` (as esquinas calçadas da coluna de anúncios).
