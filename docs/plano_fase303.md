# Plano da Fase 303 — Telhado de tábuas

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_300_304.md`. No Anno, as casas pobres têm telhado de tábuas
cinzentas ao lado das de telha; no Society, os operários eram todos de telha.

## O que entrou

- **`BuildingView.shingled`**: uma em cada `SHINGLE_EVERY` (2) casas de `SHINGLE_TIER` (os operários), pelo hash da casa, só nas
  ilhas temperadas. O parâmetro de instância `shingle` vai junto do sapê, da ardósia e da chapa (Fases 130, 134 e 138).
- **`shaders/building_kit.gdshader`**:
  - nas águas, `shingle_shade`: fileiras de `shingle_row_m` ao longo da água, tábuas de largura sorteada por fileira (as frestas não
    se alinham), um tom por tábua, o veio, a fresta e a sombra da borda de baixo; de longe, o tom médio;
  - sem o relevo das telhas no mapa de normais;
  - na capa e no beiral, a madeira cinzenta mais escura.
- A casa que sobe de classe troca de modelo e perde as tábuas junto.

## Medida

GPU 12,7 ms (302: 12,6). Neutra.

## Como testar

- `tests/presentation/test_phase303_shingle_roofs.gd`:
  - perto de metade dos operários das temperadas; nenhum camponês, artesão, tropical ou mercado;
  - as tábuas nas águas e na capa;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase300.tscn -- <pasta>`; o recorte está em `F:\ferramentas\capturas\fase303\telhado_de_tabuas.png`.
