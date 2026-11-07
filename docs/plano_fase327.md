# Plano da Fase 327 — Copa sem bolhas

**Estado: feita em 06/11/2026**, a terceira do roteiro `docs/plano_fases_325_329.md` (prado e mata). De perto, cada massa de
folhagem das folhosas aparece como uma bola lisa, clara em cima e escura embaixo, e a copa vira um cacho de balões; no Anno, a copa é
uma massa só, com a sombra por dentro.

## O diagnóstico

No `TreeModel._crown`, o claro e o escuro (`CROWN_SHADE` → `CROWN_LIGHT`) e o sol do alto (`CROWN_SUN`) saem do `unit.y` de **cada
massa**: toda massa tem o seu alto iluminado e a sua base escura, e é isso que desenha a bola. A normal já puxa para a da copa inteira
(`CROWN_ROUND`, Fase 41), mas só 65%.

## O plano

- **Arquivos**: `presentation/tree_model.gd` (`_crown`, `_puffs` e as constantes), o teste novo, `AGENTS.md` e o roteiro.
- **Luz pela copa inteira** (`CROWN_WHOLE`): nas folhosas (carvalho, faia, bétula e tropical), o claro e o escuro e o sol do alto pela
  altura do vértice em relação ao meio da copa (`hull`), não pela da massa. O pinheiro e o abeto ficam (as massas achatadas dele são
  o desenho da conífera, e a Fase 326 os deixou iguais).
- **Sombra por dentro** (`CROWN_INNER`): o lado de cada massa virado para o meio da copa fica mais escuro (é o que as outras massas
  tapam), e a junta entre as massas vira sombra, não o contorno de uma bola.
- **Normal mais redonda**: `CROWN_ROUND` de 0,65 para perto de 0,85.
- **Risco**: a sombra por dentro escurece a mata, que a Fase 326 acabou de acertar em ~0,73 do brilho do prado; o brilho médio das
  folhas não pode cair mais que ~5%.
- **Como testar**: a correlação entre a altura e o brilho das folhas de cada folhosa (quanto do claro e do escuro vem da copa inteira e
  não de cada bola), o brilho médio, o teste novo, os das árvores, a captura (`01_falesia` do `tools/capture_phase280.tscn`) e o
  benchmark.

## A medida de antes

Correlação entre a altura e o brilho (r + g + b) das folhas, e o brilho médio, na variante 0 de perto:

| | carvalho | faia | bétula | tropical | pinheiro |
|---|---|---|---|---|---|
| correlação | 0,718 | 0,613 | 0,368 | 0,659 | 0,584 |
| brilho médio | 0,868 | 0,980 | 1,084 | 0,713 | 0,903 |

## A medida de depois

| | carvalho | faia | bétula | tropical | pinheiro |
|---|---|---|---|---|---|
| correlação, só a luz da copa inteira | 0,849 | 0,881 | 0,913 | 0,623 | 0,584 |
| correlação, com a sombra por dentro (0,86) | 0,785 | 0,839 | 0,871 | 0,551 | 0,584 |
| brilho médio (0,86) | 0,826 (−4,8%) | 0,937 (−4,4%) | 1,066 (−1,7%) | 0,690 (−3,2%) | 0,903 |

A sombra por dentro tira um pouco da correlação de propósito: ela escurece o meio da copa, não a base. A 0,78 o brilho caía ~7%
(mais que o limite); ficou em 0,86. O tropical, de copa larga e baixa, tem pouca altura para a conta e fica de fora do teste.

## O que entrou

- `CROWN_WHOLE` (0,8): nas folhosas, o claro e o escuro e o sol do alto pela altura do vértice em relação ao `hull`, misturada com a
  da massa (`_crown(..., whole)`, `_puffs(..., whole)`; o pinheiro chama sem).
- `CROWN_INNER` (0,86): o lado da massa virado para o meio da copa (`-unit · outward`); a massa a menos de 20 cm do `hull` não tem.
- `CROWN_ROUND`: 0,65 → 0,85 nas folhosas; o pinheiro e o abeto (`_needle`) seguem em 0,65 (`CONIFER_ROUND`). As capturas foram tiradas
  antes dessa separação (as coníferas nelas com 0,85); as folhosas são as mesmas.

## Medida

71,6 FPS, GPU 13,1 ms (326: 71,1 FPS, GPU 13,1 ms). A primeira rodada (65,6 FPS, a mesma GPU) pegou a máquina lenta. Neutra.

## Como testar

- `tests/world/test_phase327_crown_whole.gd`: a correlação do carvalho, da faia e da bétula acima da de antes, o brilho médio no máximo
  5% abaixo, o pinheiro igual e as constantes.
- Captura: `tools/capture_phase305.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase327\antes\`, depois em `depois\`, e o recorte
  da mata baixa de perto lado a lado em `F:\ferramentas\capturas\fase327\antes_depois.png`. As bolas ainda aparecem no contorno (a
  forma das massas): a fase mexeu só na luz.