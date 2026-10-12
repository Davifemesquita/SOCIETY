# Benchmark por fase

Registro da cena `tools/benchmark.tscn` ao fim de cada fase (seção 15 da especificação).
Orçamentos: tick de simulação ≤ 4 ms na carga do benchmark; quadro ≤ 16,6 ms em 1080p no PC
alvo (RTX 3060); nenhum travamento > 50 ms ao construir.

**Esta VM não tem GPU** (renderiza por software, llvmpipe): os tempos de CPU (comandos, tick,
salvar, carregar) valem; o tempo de quadro só vale medido no PC alvo, com
`Society.exe` rodando a mesma cena.

```bash
tools/godot.sh godot --path . --resolution 1920x1080 res://tools/benchmark.tscn -- docs/benchmark.md
```

## Fase 1 — protótipo cinza

Carga: 500 casas provisórias ligadas por estrada. Moradores, carroças e pedestres ainda não
existem (entram nas Fases 2 a 4).

### 2026-10-12 10:41:28

| Medida | Resultado |
|---|---|
| prédios | 500 (estrada: 1259 células) |
| construir tudo (comandos + eventos + vistas) | 129.5 ms (0.259 ms por prédio) |
| tick de simulação | 0.0002 ms (orçamento 4.0 ms; ainda sem sistemas) |
| componentes da rede de estradas | 13.17 ms (1 trecho) |
| salvar | 24.3 ms (7.0 KB) |
| carregar (inclui refazer as vistas) | 100.2 ms |
| quadro com tudo visível | 219.7 ms (5 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |

## Fase 2 — núcleo econômico

Carga: 10.000 moradores (500 casas de operário cheias), 250 lenhadores, 250 serrarias e 20
mercados, com todos os sistemas rodando. Medido nesta VM (Xeon de 2016 a 2,2 GHz, dividido
com os outros serviços da máquina); no PC alvo, rode `Society.exe -- --benchmark`.

Antes da otimização o tick médio era 42 ms. O que trouxe para 3,2 ms: busca das definições
por dicionário; necessidades da classe calculadas uma vez por tick em vez de por casa; casas
avaliadas em 10 grupos alternados (cada casa a cada 2 s); totais (manutenção, demanda de
trabalhadores, consumidores de cada bem) guardados no DerivedState; e, na escassez, só os
consumidores mais urgentes recebem entrada, sem ordenar a lista inteira.
"Montar tudo" é lento porque cada prédio novo refaz o DerivedState inteiro (~30 ms); no
jogo isso acontece uma vez por clique, abaixo do limite de 50 ms.

### 2026-10-12 13:01:52 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| carga | 10000 moradores em 500 casas; 520 prédios de produção e serviço |
| montar tudo (comandos + eventos + vistas) | 12736 ms |
| tick de simulação (média / 95% / pior) | 3.18 / 3.49 / 10.33 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.01 · produção 1.54 · estoque 0.46 · necessidades 0.09 · população 0.98 · economia 0.00 |
| construir um prédio com a ilha cheia | 32.8 ms (limite 50 ms) |
| salvar | 101 ms (40 KB) |
| carregar (inclui refazer as vistas) | 294 ms |
| quadro com tudo visível | 313 ms (3 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |

No executável Linux exportado (build de release, mesma VM), pelo `-- --benchmark`: tick médio
2,45 ms, 95% até 2,67 ms, pior 8,18 ms; construir com a ilha cheia 24,3 ms.

## Fase 3 — logística

Carga: 10.000 moradores (200 casas de camponeses e 400 de operários), 200 prédios de produção
com 200 carroças rodando entre eles, 14 armazéns e o entreposto, e 20 mercados.
A logística custa ~1,5 ms por tick nesta VM. Construir com a ilha cheia passou de 50 ms
quando entrou o cálculo dos armazéns; as buscas em largura por índice da grade (em vez de
coordenadas) trouxeram para ~42 ms.

### 2026-10-12 13:59:00 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15363 ms |
| carroças na rua depois de 2 min | 198 de 200 |
| tick de simulação (média / 95% / pior) | 3.36 / 3.70 / 3.98 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.02 · produção 0.62 · logística 1.40 · necessidades 0.10 · população 1.15 · economia 0.00 |
| construir um prédio com a ilha cheia | 37.2 ms (limite 50 ms) |
| recálculo por etapa (ms) | prédios 8.7 · serviços 9.4 · módulos e poluição 0.0 · armazéns 12.5 · produção 4.4 · grupos de casas 1.4 |
| salvar | 108 ms (49 KB) |
| carregar (inclui refazer as vistas) | 281 ms |
| quadro com tudo visível | 394 ms (3 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |

No executável Linux exportado (mesma VM), pelo `-- --benchmark`: tick médio 2,79 ms, 95% até
3,18 ms, pior 3,52 ms; construir com a ilha cheia 26,9 ms; 198 de 200 carroças na rua.
