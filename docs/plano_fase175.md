# Plano da Fase 175 — Espantalho no campo

**Estado: feita em 31/10/2026**, a primeira do roteiro `docs/plano_fases_175_179.md` (espantalho, cegonha e vaga-lume, a partir
das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScarecrowView.spot`): num campo a cada `SCARECROW_EVERY` pelo id, só se a fazenda dona dele (`module_owner` do
  estado derivado) planta trigo ou batata (`CROPS`); no vão do meio entre duas fileiras, pela mesma conta das fileiras da
  `CropView` (`SPACING`, `HEADLAND_M`, `MARGIN_M`, `_row_frame`), um pouco fora do meio ao longo delas (`ALONG_SHARE`) e torto
  à toa (`MAX_LEAN`), pelo id.
- **O espantalho** (`scarecrow_mesh`): o poste e a travessa, o casaco com a barra mais larga e as mangas abertas na travessa, a
  calça pendurada, a palha em leque nas mangas, na barra e na boca da calça, a cabeça de saco amarrada e o chapéu de aba larga,
  ~2 m de alto. Um MultiMesh (`GameScreen.scarecrow_view`), refeito na obra, na demolição e ao trocar de mundo.

## Riscos

- O espantalho pode cair perto de um par de caixas da colheita da Fase 157 (o vão delas é sorteado): ficou assim, as duas são
  coisas que o campo tem.

## Como testar

- `tests/presentation/test_phase175_scarecrows.gd`: só os campos do resto certo do trigo e da batata têm espantalho; dentro do
  campo, no vão entre fileiras, no chão e de pé; nenhum no lúpulo nem no campo sem fazenda; a altura e os braços; a vista
  acompanha a fazenda nova.
- Captura: `tools/capture_phase175.tscn` (os campos de cima e os espantalhos de perto).
