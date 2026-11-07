# Plano da Fase 334 — Prado fundo

**Estado: feita em 07/11/2026**, a quinta e última do roteiro `docs/plano_fases_330_334.md` (luz e sombra). O capim de longe saía
verde-limão claro e liso; no Anno o prado é verde mais fundo, com o capim alto escuro em manchas.

## A medida

| | cor média (rgb) | matiz | saturação | luminância |
|---|---|---|---|---|
| Anno, prado (`c10_05`, `c10_06`, `c10_07`) | 44–66, 51–70, 22–34 | 66–75° | 0,34–0,47 | 0,14–0,20 |
| Society antes da Fase 330 | 81–94, 98–106, 33–44 | 72–75° | 0,41–0,50 | 0,26–0,29 |
| Society depois da Fase 333 | 89–94, 101–105, 45–48 | 71–74° | 0,36–0,38 | 0,29–0,30 |

O "limão" era a saturação, e a Fase 330 já a tirou (com o sol na frente, o capim não brilha de frente para a câmera): o matiz e a
saturação são os do Anno. Sobra o brilho, mais alto que o do Anno pela cor viva que o dono pediu (Fase 255) e que não se baixa aqui.
No laboratório (`CAPTURA_TERRENO`), baixar a graduação da grama mal mexe na tela (0,33 para 0,32: o AgX comprime).

## O plano

- **Arquivos**: `shaders/terrain.gdshader` e `shaders/grass_carpet.gdshader` (a cor do capim alto), `shaders/meadow_patch.gdshaderinc`
  (a oitava fina), o teste novo, a cópia da conta no teste da Fase 325, a captura do ciclo (`CAPTURA_TERRENO`), `AGENTS.md` e o
  roteiro.
- **Risco**: com as manchas mais escuras, as facetas de borda reta que o laboratório mostrou.
- **Como testar**: o laboratório, a mata alta de cima antes e depois, o teste novo e os do prado e do tapete.

## O que entrou

- **O capim alto mais escuro** (`meadow_tall_tint` (0,52; 0,68; 0,46), era (0,64; 0,79; 0,58)), igual no tapete de capim
  (`tall_tint`): as manchas se leem de longe, como no Anno.
- **A oitava fina das manchas de gradiente**: era de ruído de valor, e as curvas de nível dentro de cada célula, quase retas, faziam
  as manchas escuras saírem em facetas de borda reta (o mesmo defeito que a Fase 325 tirou da oitava larga). A cobertura do capim alto
  e do baixo segue a de antes (o teste da Fase 325, com a conta copiada, passa).

## Medida

Benchmark: 63,4 FPS, GPU 14,7 ms, carregar 6.875 ms (a 330 na mesma sessão: 63,9 FPS, GPU 14,5 ms).

## Como testar

- `tests/world/test_phase334_deep_meadow.gd`: a oitava fina de gradiente e o capim alto mais escuro, o mesmo nos dois shaders.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; o laboratório com `CAPTURA_TERRENO="meadow_tall_tint=0.52:0.68:0.46|..."`.
  Antes em `F:\ferramentas\capturas\fase333\depois\`, depois em `F:\ferramentas\capturas\fase334\depois\`, laboratórios em
  `fase334\lab\` e `lab2\`.
