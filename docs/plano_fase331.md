# Plano da Fase 331 — Abeto sem ciano

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_330_334.md` (luz e sombra). As coníferas saíam verde-azuladas,
quase ciano; no Anno o abeto é verde-escuro, puxando para o oliva.

## O diagnóstico

A agulha do abeto tinha mais azul que vermelho, (0,16; 0,36; 0,21), e a do pinheiro quase o mesmo, (0,24; 0,45; 0,21). A saturação
da cor viva (Fase 255, 1,25 depois do AgX) empurrava esse azul para o ciano. De longe, o tom da Fase 308 (`far_cool_tint`,
(0,6; 0,72; 0,88)) azulava mais.

## O plano

- **Arquivos**: `presentation/tree_model.gd` (as agulhas), `shaders/foliage.gdshaderinc` (o tom de longe), o teste novo, o da Fase 326
  (que fixava as cores de antes), `AGENTS.md` e o roteiro.
- **Risco**: perder o contraste entre o abeto e o pinheiro e entre as coníferas e as folhosas.
- **Como testar**: o teste novo e os das cores das árvores; as capturas da mata (`tools/capture_phase330.tscn`).

## O que entrou

- **As agulhas**: o pinheiro em (0,26; 0,43; 0,17) e o abeto em (0,17; 0,33; 0,14), o azul abaixo do vermelho; o abeto segue mais
  escuro que o pinheiro.
- **O tom de longe** das coníferas em (0,64; 0,7; 0,74): ainda escurece e esfria, sem o azul a mais.

## Medida

Nos pixels de folhagem das capturas da mata, o azul médio caiu de 0,46 para 0,45 do verde e de 0,59 para 0,56 do vermelho (a medida
inclui o capim; nas coníferas a diferença se vê a olho). Só cor: sem custo de quadro, sem benchmark à parte.

## Como testar

- `tests/world/test_phase331_spruce_green.gd`: as agulhas sem mais azul que vermelho, no matiz do verde amarelado, o abeto mais escuro
  que o pinheiro e o tom de longe sem azular muito.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase330\depois3\`, depois em
  `F:\ferramentas\capturas\fase331\depois\`.
