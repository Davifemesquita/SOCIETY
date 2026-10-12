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

## Fase 4 — vida e tempo

Carga da Fase 3 mais 2.000 pedestres na rua (o teto; a população do benchmark volta aos 10 mil
antes de medir), ~9.800 janelas, céu do Sky3D e um dia inteiro em 60 s com a partida rodando a
1x e a câmera a 40, 120 e 300 m. **O FPS desta VM não vale** (Vulkan por software, segundos por
quadro): a meta de 60 FPS em 1080p se mede na RTX 3060 com `Society.exe -- --benchmark`. Aqui
valem o tick e o custo da multidão na CPU. (O tempo de processo do Godot por quadro não vale
nesta VM: numa partida vazia e pausada ele dá 233 ms, o quadro inteiro, porque inclui a espera
pela renderização por software. Saiu do benchmark.)

### 2026-10-12 18:04:48 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15604 ms |
| carroças na rua depois de 2 min | 198 de 200 |
| tick de simulação (média / 95% / pior) | 3.32 / 3.67 / 4.18 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.02 · produção 0.61 · logística 1.40 · necessidades 0.10 · população 1.06 · economia 0.00 |
| construir um prédio com a ilha cheia | 35.1 ms (limite 50 ms) |
| recálculo por etapa (ms) | prédios 8.6 · serviços 9.5 · módulos e poluição 0.0 · armazéns 11.3 · produção 3.6 · grupos de casas 1.2 |
| salvar | 101 ms (49 KB) |
| carregar (inclui refazer as vistas) | 360 ms |
| quadro com tudo visível | 509 ms (2 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 9769 janelas |
| multidão saindo de casa (rotas novas) | 201 quadros, 1628 ms; 1384 rotas, 0.42 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.27 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.3 / 0.2 FPS / 4750 ms em 20 quadros (meta 60 FPS), a partir das 10:00 |

O arranque da multidão (todos saindo de casa de uma vez, como ao carregar) calcula ~1.400 rotas
com A*, 0,42 ms cada nesta VM; o teto de 1 ms de rotas por quadro (4 ms na partida em massa)
espalha isso por ~200 quadros. Depois, a multidão custa 0,27 ms por quadro na CPU.

No executável Linux exportado (build de release, mesma VM), pelo `-- --benchmark`: tick médio
2,82 ms, 95% até 3,14 ms, pior 3,28 ms; construir com a ilha cheia 30,1 ms; 2.000 pedestres,
1.905 na rua; arranque com 1.376 rotas a 0,32 ms cada; multidão assentada a 0,22 ms por quadro.
