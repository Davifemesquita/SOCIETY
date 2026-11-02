# Plano da Fase 275 — Abeto em camadas

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_275_279.md` (a mata no jeito do Anno). Antes, a conífera
da mata era só o pinheiro-silvestre, de copa no último terço: vista do campo, a beira de toda mata de pinheiros era uma cerca de
troncos vermelhos. No Anno, as coníferas são abetos em cone, com os galhos até perto do chão.

## O que entrou

- **`TreeModel.Species.NORWAY_SPRUCE`**, no fim do enum.
  - `_spruce`: o tronco curto, só o pé aparece. Em volta dele vão `SPRUCE_TIERS` (8) camadas de `SPRUCE_SPOKES` (12) galhos,
    da beira a `SPRUCE_SKIRT_M` (0,45 m) do chão até a ponta.
  - Cada camada (`_skirt`) é um cone que desce em arco do meio até a beira, recortada em pontas: galho comprido e vão se alternam,
    e a ponta do galho fica mais baixa. Cada uma sobe 1,8 passo, então cobre o pé da de cima.
  - O raio vai de `SPRUCE_RADIUS_M` (2 m) embaixo a ~0,45 m no alto, e a flecha fica na ponta. A altura vai de 8,6 a 10 m.
  - Cor (`_needle`): `SPRUCE_NEEDLE` (verde-escuro azulado), mais clara e amarelada junto do alto de cada camada e mais escura
    na beira. A normal do cone puxa para a da árvore inteira.
  - De longe, três camadas de seis galhos.
  - As faces vão no sentido horário visto de fora, como as do `_limb`. Com o material de duas faces, a face trocada vira a
    normal e acende a camada do lado da sombra.
- **`TreeView.CONIFER`** passa a ser dois abetos e dois pinheiros.
  - `conifer_pick` escolhe entre eles pelo sorteio da árvore: pinheiro em `PINE_SHARE` (20%), e em `PINE_SHARE_HIGH` (60%)
    acima de `PINE_HEIGHT_M` (12 m, os patamares mais altos). O resto é abeto.
  - A variante vem do mesmo sorteio de antes, e as folhosas não mudaram.
  - O roteiro previa pinheiro também junto da costa. Conferir a costa em cada célula de mata custaria uma busca a mais no
    jogo novo, e ficou só a altura.

## Como testar

- `tests/world/test_phase275_spruce.gd`:
  - a espécie no fim do enum;
  - de pé no chão, no tamanho e no orçamento de triângulos, com o nível de longe mais leve e da mesma altura;
  - a folhagem descendo abaixo de 0,6 m e duas vezes mais larga no terço de baixo que no de cima, mais estreita que o carvalho;
  - mais escura que o pinheiro;
  - o sorteio com abeto na maior parte e pinheiro mais no alto, as quatro coníferas aparecendo;
  - na semente 1840, mais abetos que pinheiros desenhados.
- Captura: `tools/capture_phase275.tscn -- <pasta>`. Mostra a vila de cima, os campos de perto, a mata alta de perto e de meia
  distância e a mata baixa de perto, todas fora da vila. É a captura do ciclo da mata, antes e depois.
