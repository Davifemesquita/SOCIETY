# Plano da Fase 92 — Medidas que faltam

**Estado: feita em 28/10/2026**, terceira do roteiro `docs/plano_fases_90_94.md`. As medidas que ficaram em aberto desde a
Fase 32, e um defeito achado no caminho.

## As medidas (RTX 5060, área de trabalho escondida, Vulkan, nível alto)

| caso | FPS médio | 1% low | 0,1% low | pior quadro | GPU média |
|---|---|---|---|---|---|
| 1080p, VSync desligado (`-- --sem-vsync`) | 86,4 | 44,0 | 36,0 | 35 ms | 10,8 ms |
| 3D nos pixels do 4K (`-- --4k`: 200% numa janela de 1080p) | 46,5 | 35,9 | 30,8 | 33 ms | 21,1 ms |
| executável exportado (release), 1080p | 89,1 | 54,6 | 48,2 | 21 ms | — |

- **VSync**: na área de trabalho escondida a janela não espera o monitor (o alto já passava de 60 com o VSync "ligado"),
  então desligar não muda o número; a opção `--sem-vsync` fica para medir no monitor de verdade.
- **4K**: o Windows não deixa a janela passar da altura da tela (`--resolution 3840x2160` virou 3840×1139), então o
  benchmark põe o 3D em 200% de uma janela de 1080p — os mesmos pixels do 4K, com a interface em 1080p. A GPU dobra
  (21 ms); quem joga em 4K usa a escala do FSR. A meta da especificação é 60 FPS em 1080p, e ela é cumprida.
- **Executável**: um pouco melhor que pelo editor (sem o depurador), principalmente nos quadros lentos.
- **Shader baker**: o preset do Windows tem `shader_baker/enabled=true`, a exportação roda com o Vulkan na RTX 5060, mas
  o log não mostra etapa de cozimento e o executável compila as mesmas pipelines que o editor (5 superfícies e 11
  especializações montando a cidade, 63 especializações no dia). Como essas compilações não param o quadro (Fase 91),
  não vale mais tempo agora; fica registrado.

## O defeito: o executável caía no benchmark

- O executável exportado caía (código 0xC0000005) montando a frota do benchmark: `TradeDemo.post` conferia com `assert`
  que a ilha tinha lugar de entreposto, e o `assert` some no executável; o índice vazio virava `Nil` e derrubava o
  jogo. O executável de depuração mostrou a mensagem: **as ilhas 3 e 4 da semente 1840 não têm lugar de entreposto**.
- No editor o benchmark também pulava as duas, em silêncio (o erro saía no log e a rota era criada para uma ilha sem
  porto). Agora `post` devolve 0 com um aviso, o benchmark não cria a rota e a linha "frota" diz quantas ilhas ficaram de
  fora.
- **A causa é do terreno v3** (o padrão do jogo novo desde a Fase 52): nas ilhas pequenas temperadas (recife e terras
  altas, 80×80) nenhuma posição passa nas regras do entreposto — a costa não é plana e o plano não encosta no mar. No v1
  as oito ilhas têm lugar. Numa partida de verdade, **essas duas ilhas não podem ser colonizadas**. A correção mexe no
  gerador e virou a Fase 93 (o roteiro foi atualizado).

## O que mudou

- `tools/benchmark.gd`: `-- --sem-vsync` e `-- --4k`; a linha "frota" conta as ilhas sem lugar de entreposto.
- `tools/trade_demo.gd`: `post` devolve 0 sem lugar, em vez do `assert`.
- No código do jogo há um só `assert` (`ArchipelagoJob.result`, só conferência): nada mais depende dele para funcionar.

## Como testar

- `godot --path . --resolution 1920x1080 res://tools/benchmark.tscn -- <saida.md> --sem-vsync` (ou `--4k`).
- O executável: `Society.exe -- --benchmark` (o resultado vai para `%APPDATA%\Godot\app_userdata\Society\benchmark.md`).
