# Plano da Fase 191 — Pombal

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_190_194.md` (colmeia, pombal e varal, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`DovecoteView.spot`): numa fazenda de `FARMS` (ovelhas, porcos, trigo e batata) a cada `DOVECOTE_EVERY` pelo id, na
  célula logo depois do canto da frente de +X do lote, na diagonal (fora do caminho da porta), se ela está livre e quase plana;
  a frente da casinha para o lado da frente da fazenda. Só nas ilhas com relevo.
- **O pombal** (`dovecote_mesh`): o poste com as escoras, a casinha de tábua com duas fileiras de buracos e o poleiro na frente
  e no lado, e o telhado de quatro águas com a beira saindo.
- **Os pombos** (`PIGEONS`, o pombo pousado da `BirdView`): no alto do telhado e nos poleiros (`PERCHES`), virando de tempos em
  tempos pela conta das gaivotas do cais (`PerchedGullView.heading_at`), no tempo de jogo. Dois MultiMesh
  (`GameScreen.dovecote_view`).

## Como testar

- `tests/world/test_phase191_dovecotes.gd`: as fazendas do resto certo ganham o pombal no canto da frente, fora do lote; nada
  nos outros prédios nem na ilha plana; os poleiros ficam no pombal.
- Captura: `tools/capture_phase191.tscn` (o roteiro das fazendas da Fase 190, com as fotos do pombal).
