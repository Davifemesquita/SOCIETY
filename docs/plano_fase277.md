# Plano da Fase 277 — Bétula

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_275_279.md`. As folhosas da mata eram só o carvalho e a
faia, de copa redonda e verde-viva. No Anno, a beira da mata tem bétulas: tronco branco e copa leve e clara.

## O que entrou

- **`TreeModel.Species.BIRCH`**, no fim do enum.
- **O tronco** (`_birch`):
  - fino e alto (`BIRCH_HEIGHT_M`, de 7,6 a 8,8 m) e um pouco torto;
  - escuro no pé e branco (`BIRCH_BARK`) daí para cima;
  - com `BIRCH_MARKS` (9) manchas pretas (`_birch_marks`): losangos achatados colados na casca, no sentido horário visto de
    fora, só de perto.
- **Os galhos e a copa**:
  - três galhos finos subindo do meio do tronco;
  - a copa em `BIRCH_MASSES` (7) massas pequenas e soltas, numa oval mais alta que larga, e uma no alto;
  - folha `BIRCH_LEAF`, verde-clara.
- **Onde ela aparece**: `TreeView.BROADLEAF` ganhou as duas bétulas no fim, e `broadleaf_pick` escolhe entre as folhosas.
  - Bétula em `BIRCH_SHARE_EDGE` (40%) na beira da mata (a célula de uma árvore só), em `BIRCH_SHARE_LOW` (25%) na terra
    baixa (abaixo de `BIRCH_LOW_M`, 4 m) e em `BIRCH_SHARE` (10%) no resto.
  - Carvalho e faia pelo mesmo sorteio de antes.

## Como testar

- `tests/world/test_phase277_birch.gd`:
  - a espécie no fim do enum;
  - de pé no chão, no tamanho e no orçamento de triângulos, com o nível de longe mais leve e da mesma altura;
  - mais fina que o carvalho;
  - o tronco branco com as nove manchas de perto e nenhuma de longe;
  - a escolha com bétula mais na beira e na terra baixa, e as seis folhosas aparecendo.
- A cor da malha volta em 8 bits por canal: o teste compara as cores com folga.
- Captura: `tools/capture_phase275.tscn -- <pasta>` (as vistas do ciclo da mata).
