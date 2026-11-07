# Plano da Fase 249 — Montes de pedra nos campos

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_245_249.md` (coelho, cogumelo e pedra, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`FieldStoneView.spot`): num campo com dono (pelo `module_owner` do estado derivado) das ilhas temperadas a cada
  `STONE_EVERY` pelo id (resto `STONE_REST`), num canto da cabeceira escolhido pelo id, no referencial das fileiras da `CropView`
  (`_row_frame`): depois do fim das fileiras, no meio da faixa da cabeceira, e para dentro da borda do campo.
- **O monte** (`heap_mesh`): as pedras tiradas da terra arada em três camadas baixas, cada uma um bloco girado à toa, de tamanho e
  tom pelo número dela. Um MultiMesh; refeito na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase249_field_stones.gd`: numa fazenda de trigo com os campos dela, os campos do resto certo têm o monte, dentro
  do lote e além do fim das fileiras, e os outros não; campos sem fazenda não têm; o monte é baixo e largo.
- Captura: `tools/capture_phase249.tscn` (a ilha plana; `pedras_de_perto.png`, `pedras_e_campo.png`, `pedras_de_longe.png`).
