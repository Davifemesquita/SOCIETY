# Plano da Fase 359 — Raso verde

**Estado: feita em 07/11/2026**, a última do roteiro `docs/plano_fases_355_359.md` (mar aberto). No Anno o raso das temperadas é
verde-escuro sobre o fundo; o nosso (`cold_shelf`, Fase 280) ainda puxava para o turquesa claro.

## O laboratório

`CAPTURA_AGUA` no `tools/capture_phase330.tscn`, com várias cores de `cold_shelf` na falésia, na praia e no mar de cima
(`F:\ferramentas\capturas\fase359\lab\`). Verde demais virava lagoa; claro demais voltava ao turquesa.

## O que entrou

- **`cold_shelf`** no `shaders/water.gdshader` em (0,22; 0,44; 0,38; 0,5), era (0,19; 0,52; 0,53; 0,52): o verde acima do azul e mais escuro.
  As tropicais seguem turquesa.

## Medida

Só cor: sem custo de quadro. O benchmark do fim do roteiro em `docs/benchmark.md` (69,0 FPS, GPU 13,6 ms; na Fase 354 GPU 13,5 ms).

## Como testar

- `tests/world/test_phase359_green_shallows.gd`: o verde passa do azul e o raso fica mais escuro que o turquesa de antes. O da Fase 280
  (com tela).
- Captura: `tools/capture_phase280.tscn` com `CAPTURA_SO=dia` (`F:\ferramentas\capturas\fase359\depois\`); antes e depois do roteiro
  inteiro em `F:\ferramentas\capturas\fase359\antes_depois_330_359.png` (o mar da Fase 329 à esquerda).
- Ficou à vista: com o sol na frente da câmera (Fase 330), o reflexo dele no mar de perto ainda faz manchas brancas grandes.
