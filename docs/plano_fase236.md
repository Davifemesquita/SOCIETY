# Plano da Fase 236 — Âncora no cais

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_235_239.md` (cervo, âncora e marco, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`AnchorView.spot`): no cais de pedra de cada entreposto (Fase 106), do último lanço para o primeiro, fora da frente do
  entreposto, no fundo do cais (`ANCHOR_IN_M` para dentro da beira: as outras peças do cais ficam junto dela e não sobrava lanço
  livre na beira), ao longo da costa; fica de fora o lugar a menos de `CLEAR_M` de um lampião, cisterna, mastro, alto de escada,
  banco ou pilha de covos, e o que a terra de trás cobriria.
- **A âncora** (`anchor_mesh`): montada com a haste reta e os braços num plano de pé, e tombada até o cepo e a pata de baixo tocarem
  o chão juntos, como uma âncora deitada fica (o outro braço erguido); a haste e os braços de ferro escuro, as patas enferrujadas,
  o cepo de madeira com duas cintas, a argola deitada além da cabeça e a amarra saindo dela para o lado de terra, por fora do cepo,
  até o rolo de duas voltas, em elos alternados. Um MultiMesh.

## Como testar

- `tests/world/test_phase236_anchor.gd`: na semente 1840, a âncora fica num lanço do cais, virada para o mar e longe dos lampiões,
  mastros, covos e bancos; a ilha plana não tem; deitada, ela é mais comprida que alta, com o pé no chão e um braço erguido.
- Captura: `tools/capture_phase236.tscn` (a semente 1840; `ancora_0_do_mar.png`, `ancora_0_de_lado.png`, `ancora_longe.png`).
