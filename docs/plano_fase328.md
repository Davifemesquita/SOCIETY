# Plano da Fase 328 — Capim rente

**Estado: feita em 06/11/2026**, a quarta do roteiro `docs/plano_fases_325_329.md` (prado e mata). No prado de perto, os tufos do
tapete de capim (Fase 286) saíam como fios verdes soltos, altos e claros, espalhados como pelos sobre o chão; no Anno, o capim é rente,
cerrado e no tom do chão.

## O plano

- **Arquivos**: `presentation/grass_carpet_view.gd` (as medidas e as cores do tufo), `shaders/grass_carpet.gdshader` (a altura do
  capim alto), o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: a primeira versão da Fase 286 (folhas de 0,22 a 0,42 m) não aparecia na distância normal da câmera. Aqui é de propósito:
  o tapete passa a ser textura do chão, não fio solto. E mais tufos custam GPU no prado.
- **Como testar**: a cor do chão e das folhas na tela (`01_prado_de_perto` e `02_prado` do `tools/capture_phase285.tscn`), o custo
  no `tools/grass_cost.tscn`, o teste novo, os do tapete e das flores e o benchmark.

## A medida

Na tela, numa área do prado (os 40% mais escuros são o chão; os 15% mais claros, as pontas das folhas, as flores e as touceiras do
recheio):

| | chão (rgb) | claros (rgb) | desvio do brilho |
|---|---|---|---|
| antes, de perto | 66 84 28 | 118 144 41 | 48,0 |
| primeira tentativa | 66 82 29 | 107 125 37 | 37,6 |
| depois, de perto | 66 82 28 | 111 129 36 | 40,0 |
| antes, a 70 m | 68 86 28 | 134 139 48 | 53,4 |
| depois, a 70 m | 68 84 28 | 131 127 46 | 50,5 |

A primeira tentativa (12 tufos, folha de 4 cm, pé 0,21/0,28/0,09) deixou as folhas mais escuras que o chão, em fiapos escuros soltos;
a segunda clareou o pé e alargou e adensou as folhas. A 70 m quase não muda: lá os claros são as papoulas e as flores.

## O que entrou

- **Folhas**: de 0,4–0,75 m para 0,2–0,38 m (`BLADE_HEIGHT_M`); o capim alto 1,45 vezes a folha (`tall_height`, era 1,7): a mais alta
  fica em ~0,69 m, antes ~1,6 m.
- **Mais cerrado**: 14 tufos por célula (eram 8), de 9 folhas (eram 7), com 5 cm de meia largura no pé (eram 4).
- **No tom do chão**: pé 0,2/0,34/0,09 → 0,25/0,33/0,105 e ponta 0,5/0,68/0,22 → 0,34/0,43/0,14 (a ponta era 2,5 vezes o pé; agora
  ~1,3), no matiz do capim do terreno.
- **A flor do tufo** a 0,32 m (era 0,42), acima da folha média.
- **Ficou de fora**: as touceiras claras do recheio (`ScatterView`, Fase 41) ainda saem mais altas e claras que o tapete.

## Medida

Benchmark: 70,2 FPS, GPU 13,2 ms (327: 71,6 FPS, GPU 13,1 ms). O trajeto passa quase só pela vila. Sobre o prado aberto
(`tools/grass_cost.tscn`), 56 mil tufos em vez de 32 mil, e o tapete custa +0,61/+0,69/+0,80 ms na GPU a 30/60/110 m (antes
+0,48/+0,38/+0,41). Montar um bloco cresce na mesma proporção dos tufos; não foi medido à parte.

## Como testar

- `tests/world/test_phase328_short_grass.gd`: a folha baixa (a mais alta do capim alto abaixo de 0,7 m), o tapete mais cerrado, a ponta
  perto do pé e no matiz do capim e a flor acima da folha média.
- Captura: `tools/capture_phase285.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase328\antes\`, as tentativas em `a\` e `b\`
  (a que ficou). Custo: `tools/grass_cost.tscn -- <saida.md>` (`antes\custo.md` e `custo_depois.md`).