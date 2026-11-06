# Plano da Fase 326 — Mata no tom

**Estado: feita em 05/11/2026**, a segunda do roteiro `docs/plano_fases_325_329.md` (prado e mata). As copas das folhosas eram de
um verde-limão claro e saturado; no Anno, a mata é de um verde mais fundo, com cada árvore num tom.

## O plano

- **Arquivos**: `presentation/tree_model.gd` (as cores das folhosas, o sol do alto da copa e os tufos), `shaders/foliage.gdshaderinc`
  (os tons por árvore da Fase 305), o teste novo e o da Fase 256.
- **Risco**: a Fase 256 clareou as folhas porque, com a sombra da copa, a mata virava quase preta; escurecer demais volta a isso. O
  tom por árvore já existia (Fase 305): não precisa de sorteio novo, só de tons que não puxem para o limão.
- **Como testar**: a cor média das copas e do prado nas capturas, comparada com a do Anno; o teste novo; os testes das árvores e o
  benchmark.

## A medida

A régua é relativa (a luz e o céu não são os do Anno): a cor média das copas sobre a do prado, na mesma captura (`01_falesia` do
`tools/capture_phase280.tscn` e `c10_09` do Anno).

| | copa (rgb) | prado (rgb) | verde da copa / do prado |
|---|---|---|---|
| Anno | 45 53 18 | 70 75 35 | ~0,7 |
| antes (325) | 96 138 20 | 107 126 43 | 1,1 (a mata mais clara que o capim) |
| primeira tentativa | 64 107 26 | 107 126 43 | 0,85 |
| depois | 60 92 28 | 107 126 43 | 0,73 |

## O que entrou

- **Folhosas** (`TreeModel`): carvalho 0,37/0,57/0,19 → 0,27/0,40/0,17, faia 0,48/0,66/0,22 → 0,32/0,46/0,19, bétula
  0,47/0,65/0,25 → 0,36/0,50/0,22 (segue a mais clara) e tropical 0,24/0,51/0,15 → 0,21/0,37/0,14. O pinheiro e o abeto ficam.
- **Sol do alto da copa** (`CROWN_SUN`): o azul de 0,82 para 0,9; o vermelho e o verde ficam (o alto segue mais amarelo que a base,
  o teste da Fase 256). Baixar o vermelho para 1,04 deixou o alto e a base no mesmo tom e o teste caiu.
- **Tufos** (`PUFF_LIGHT`): a cor vezes 1,08 no lugar do `lightened(0.06)`, que puxa para o branco e, na folha funda, deixava a base
  da copa mais amarelada que o alto.
- **Tons por árvore** (`tint_dark`, `tint_olive`, `tint_yellow`): o oliva e o amarelado cortavam o azul a 66% e 67% do verde e
  deixavam a árvore mais saturada; agora nenhum corta abaixo de 78%, e o escuro puxa para o azul.

## Medida

71,1 FPS, GPU 13,1 ms (325: 71,2 FPS, GPU 13,1 ms). Neutra: só constantes.

## Como testar

- `tests/world/test_phase326_canopy_tone.gd`: as folhosas mais escuras e menos saturadas que antes e ainda verdes, a bétula a mais
  clara, o alto da copa iluminado fora do limão, os tons por árvore sem cortar o azul e as coníferas iguais.
- Captura: `CAPTURA_SO=dia tools/capture_phase280.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase325\depois_dia\`, as
  tentativas em `F:\ferramentas\capturas\fase326\a\` e `b\`, depois em `depois\`.
