# Plano da Fase 91 — Travadas do ultra

**Estado: feita em 28/10/2026**, segunda do roteiro `docs/plano_fases_90_93.md`. Ferramenta e medida: nada muda no jogo.

## O que se mediu

A pendência vinha da Fase 32 (25/10/2026, RTX 5060, 1080p): "o ultra trava, pior quadro de até ~2 s". Três rodadas do
benchmark no ultra, hoje, na área de trabalho escondida (Vulkan, mesma máquina):

| rodada | FPS médio | 1% low | 0,1% low | pior quadro | p99 |
|---|---|---|---|---|---|
| 1 | 61,8 | 33,9 | 15,0 | 85 ms | 24,3 ms |
| 2 | 63,9 | 39,8 | 32,9 | 32 ms | — |
| 3 | 64,1 | 41,6 | 37,1 | 28 ms | 22,6 ms |

- **As travadas de ~2 s não voltaram** em nenhuma rodada. Na rodada 1, só 3 dos 3.710 quadros passaram de 40 ms (85, 55 e
  61 ms), com a CPU do render em ~2 ms, a GPU em ~15 ms e o tick em zero.
- **Compilação de shader não é a causa.** O benchmark passou a gravar, por quadro, a hora do jogo e quantas pipelines o
  motor compilou nele (`hour` e `pipelines_frame` no JSON, formato 2). As compilações do dia se juntam no anoitecer (73 às
  18h18 e 45 às 18h48, quando as luzes acendem) e 40 às 2h42, mas **nenhum quadro acima de 25 ms teve compilação**: o Godot
  4.7 compila essas variantes por fora, sem parar o quadro. Pré-aquecer as luzes da noite atrás da cortina não traria
  nada, e ficou de fora.
- O pico de 85 ms da rodada 1 não se repetiu e não tem compilação nem tick no quadro: fica como ruído da máquina (a área
  de trabalho escondida divide a GPU com o resto do Windows).

## O que mudou

- `tools/benchmark.gd`: `hour` e `pipelines_frame` por quadro no JSON (`FRAMES_FORMAT` 2), para a próxima investigação
  de travada achar o momento sem adivinhar.
- A pendência de desempenho no `AGENTS.md` foi atualizada com as medidas de hoje.

## Como testar

- `godot --path . --resolution 1920x1080 res://tools/benchmark.tscn -- <saida.md> --nivel 3`; os quadros brutos ficam em
  `<saida>_quadros.json`.
