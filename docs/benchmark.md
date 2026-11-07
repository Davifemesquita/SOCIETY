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

## Fase 5 — mundo

A carga da Fase 4 no arquipélago da semente 1840: terreno das 5 ilhas, água com ondas e espuma,
~40 mil árvores desenhadas (as debaixo da cidade derrubadas), a cidade de teste montada sem olhar o relevo
(chave só do benchmark). O FPS desta VM continua não valendo; a meta se mede na RTX 3060.

### 2026-10-12 22:40:34 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| jogo novo: arquipélago, terreno, água e árvores | 4482 ms (semente 1840, 39763 árvores desenhadas) |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 20627 ms |
| carroças na rua depois de 2 min | 150 de 200 |
| tick de simulação (média / 95% / pior) | 3.51 / 3.81 / 4.27 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.04 · produção 0.60 · logística 1.23 · necessidades 0.37 · população 1.10 · economia 0.00 |
| construir um prédio com a ilha cheia | 45.0 ms (limite 50 ms): comando e vistas 45.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.2 · serviços 9.8 · módulos e poluição 0.0 · armazéns 12.3 · produção 6.2 · grupos de casas 1.4 |
| salvar | 140 ms (53 KB) |
| carregar (inclui refazer as vistas) | 1971 ms |
| quadro com tudo visível | 3313 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 9769 janelas |
| multidão saindo de casa (rotas novas) | 509 quadros, 3959 ms; 1423 rotas, 1.49 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.65 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.2 / 0.1 FPS / 11788 ms em 10 quadros (meta 60 FPS), a partir das 10:00 |

- **Construir com a ilha cheia**: o recálculo agora acontece uma vez só, dentro do evento (a
  etiqueta do prédio novo já consulta o estado); antes, as árvores derrubadas marcavam a
  simulação depois dos eventos e o estado era refeito duas vezes (79 ms).
- **Tick**: +0,3 ms em relação à Fase 4 porque necessidades e força de trabalho passam pelas 5
  ilhas, não por uma. Média dentro do orçamento.
- **Carroças**: 150 de 200 na rua (198 na Fase 4) porque parte dos lenhadores da cidade de teste
  fica sem árvores em volta (a cidade derruba a floresta onde é montada) e para, como manda a
  regra.
- **Carregar** refaz o arquipélago pela semente e o terreno desenhado (a Fase 4 levava 360 ms).
- **Rotas dos pedestres**: 1,49 ms cada aqui, 1,06 ms rodando sem tela (o renderizador por
  software disputa a CPU). A diferença que sobra contra os 0,42 ms da Fase 4 deve vir da cidade
  de teste montada sem olhar o relevo (cada mudança de inclinação vira um ponto a mais na rota);
  não foi medida à parte. Na ilha de verdade a estrada fica nos patamares planos.

No executável Linux exportado (build de release, mesma VM), pelo `-- --benchmark`: jogo novo
3,5 s; tick médio 2,85 ms, 95% até 3,15 ms, pior 3,35 ms; construir com a ilha cheia 32,5 ms;
carregar 1,7 s; 2.000 pedestres, 1.903 na rua; arranque com 1.449 rotas a 0,78 ms cada; multidão
assentada a 0,41 ms por quadro.

## Fase 6 — navios e comércio

Mesma carga da Fase 5, mais um entreposto no litoral de cada uma das outras 4 ilhas, 10 navios em
4 rotas saindo da principal, o navio inicial e o do comerciante.

### 2026-10-13 16:46:47 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| jogo novo: arquipélago, terreno, água e árvores | 4607 ms (semente 1840, 39763 árvores desenhadas) |
| frota | 10 navios em 4 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1123 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 20726 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.56 / 3.91 / 4.62 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.04 · produção 0.59 · logística 1.19 · necessidades 0.35 · população 1.11 · economia 0.00 · navios 0.07 |
| construir um prédio com a ilha cheia | 47.5 ms (limite 50 ms): comando e vistas 47.5 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 8.9 · serviços 9.8 · módulos e poluição 0.0 · armazéns 15.1 · produção 6.2 · grupos de casas 1.4 |
| salvar | 131 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1570 ms |
| quadro com tudo visível | 2250 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1904 na rua (teto 2000); 6693 janelas |
| multidão saindo de casa (rotas novas) | 469 quadros, 3053 ms; 1420 rotas, 1.09 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.44 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.2 / 0.1 FPS / 7561 ms em 11 quadros (meta 60 FPS), a partir das 07:00 |

- **Navios**: 0,07 ms por tick com 12 navios. O caminho novo no mar custa de 1 a mais de 20 ms
  (o pior par é o canto do comerciante até uma ilha do outro lado); numa primeira medição, com o
  caminho calculado no próprio tick, o pior tick chegou a 12,6 ms. Agora o navio iça velas por 1 s
  enquanto o `WorkerThreadPool` calcula, e o pior tick ficou em 4,6 ms.
- **Tick**: média 3,56 ms, dentro do orçamento; o sistema dos navios quase não pesa.
- **Construir com a ilha cheia**: 47,5 ms (limite 50 ms), ~2 ms acima da Fase 5 por causa dos
  pontos de atracação refeitos a cada recálculo.
- O FPS desta VM continua não valendo; a meta se mede na RTX 3060.

## Fase 8 — conteúdo

Mesma carga da Fase 6 (camponeses e operários): o custo das classes novas aparece nas necessidades
de todas as ilhas e na amostra do histórico das estatísticas, que a Fase 7 não mediu.

### 2026-10-14 09:08:40 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| jogo novo: arquipélago, terreno, água e árvores | 5310 ms (semente 1840, 39763 árvores desenhadas) |
| frota | 10 navios em 4 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1130 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 20671 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.59 / 4.00 / 5.08 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.04 · produção 0.63 · logística 1.31 · necessidades 0.22 · população 1.13 · economia 0.00 · navios 0.06 |
| construir um prédio com a ilha cheia | 48.0 ms (limite 50 ms): comando e vistas 48.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.3 · serviços 9.8 · módulos e poluição 0.0 · armazéns 15.3 · produção 5.8 · grupos de casas 1.5 |
| salvar | 142 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1646 ms |
| quadro com tudo visível | 2691 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 6693 janelas |
| multidão saindo de casa (rotas novas) | 487 quadros, 6158 ms; 1421 rotas, 1.95 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.68 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.2 / 0.1 FPS / 12574 ms em 10 quadros (meta 60 FPS), a partir das 07:00 |

- **Tick**: média 3,59 ms, 95% em 4,00 ms, pior 5,08 ms. A primeira medição da fase deu 4,37 ms
  de média e 11 ms de pior tick: as necessidades rodavam as cinco classes nas cinco ilhas, mesmo
  sem casa (0,97 ms; agora 0,22 ms), e a amostra do histórico das estatísticas (Fase 7, uma a cada
  60 s) percorria os prédios uma vez por ilha (agora é uma passada).
- **Construir com a ilha cheia**: 48,0 ms (limite 50 ms), igual à Fase 6.
- **Partida roteirizada** (critério): a cidade de 210 casas chega aos investidores em ~50 min de
  jogo; 4 horas de jogo rodam em ~2 min sem tela nesta VM.
- O FPS desta VM continua não valendo; a meta se mede na RTX 3060.

## Fase 9 — gráficos finais

Mesma carga da Fase 8, no **nível gráfico alto** (o do critério): materiais PBR dos prédios e
estradas, fumaça nas chaminés, clima, árvores ao vento, SSAO, SSIL, glow e neblina volumétrica. As
nuvens volumétricas ficam desligadas no llvmpipe (ver as notas).

### 2026-10-14 13:39:10 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| jogo novo: arquipélago, terreno, água e árvores | 6075 ms (semente 1840, 39763 árvores desenhadas) |
| frota | 10 navios em 4 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1210 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 21090 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.56 / 3.98 / 5.31 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.04 · produção 0.64 · logística 1.36 · necessidades 0.22 · população 1.12 · economia 0.00 · navios 0.07 |
| construir um prédio com a ilha cheia | 48.5 ms (limite 50 ms): comando e vistas 48.5 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.3 · serviços 10.2 · módulos e poluição 0.0 · armazéns 15.3 · produção 6.3 · grupos de casas 1.3 |
| salvar | 148 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1593 ms |
| quadro com tudo visível | 4707 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 6693 janelas |
| multidão saindo de casa (rotas novas) | 493 quadros, 5600 ms; 1404 rotas, 2.13 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.72 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.1 / 0.1 FPS / 11409 ms em 8 quadros (meta 60 FPS), a partir das 07:00 |

- **Tick**: média 3,56 ms, 95% em 3,98 ms, pior 5,31 ms: os gráficos não mexem na simulação.
- **Construir com a ilha cheia**: 48,5 ms (limite 50 ms). A primeira medição deu 52 ms: as gaivotas
  refaziam a revoada varrendo todos os prédios a cada construção; agora só quando entra ou sai um
  porto.
- **Quadro**: 4,7 s no llvmpipe, que não vale. **O critério da fase (quadro em até 16,6 ms no nível
  alto) só se mede na RTX 3060**, com `Society.exe -- --benchmark` (`-- --benchmark --nivel 3` mede o
  ultra, com as nuvens volumétricas).
- Uma medição feita com outra sessão renderizando vídeo na VM (swap cheio) deu pior tick de 317 ms e
  construir em 390 ms; foi descartada. Medir com a máquina livre (`uptime`, `free -m`).

## Fase 10 — polimento

Mesma carga da Fase 9, no nível alto, agora com música, ambiente por zona (vento e chuva gerados),
efeitos e fábricas com som posicional. Sem tela de verdade o áudio não toca, mas o ambiente conta
os prédios em volta da câmera e gera o ruído do vento.

### 2026-10-14 15:27:04 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| jogo novo: arquipélago, terreno, água e árvores | 5994 ms (semente 1840, 39763 árvores desenhadas) |
| frota | 10 navios em 4 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1148 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 21122 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.56 / 3.94 / 4.60 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.04 · produção 0.62 · logística 1.24 · necessidades 0.21 · população 1.14 · economia 0.00 · navios 0.08 |
| construir um prédio com a ilha cheia | 50.1 ms (limite 50 ms): comando e vistas 50.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.3 · serviços 9.7 · módulos e poluição 0.0 · armazéns 16.3 · produção 6.4 · grupos de casas 1.4 |
| salvar | 148 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1595 ms |
| quadro com tudo visível | 4820 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 6693 janelas |
| multidão saindo de casa (rotas novas) | 556 quadros, 6665 ms; 1413 rotas, 2.59 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.63 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.1 / 0.0 FPS / 21324 ms em 6 quadros (meta 60 FPS), a partir das 07:00 |

- **Tick**: média 3,56 ms, 95% em 3,94 ms, pior 4,60 ms: o áudio não mexe na simulação.
- **Construir com a ilha cheia**: 50,1 ms, **no limite de 50 ms** (Fase 9: 48,5). Quase tudo é o
  recálculo do estado derivado (armazéns ~16 ms, serviços ~10, prédios ~10, produção ~6), feito pela
  primeira vista que consulta o estado; os efeitos e o áudio somam ~2 ms. A folga volta otimizando o
  recálculo dos armazéns (busca em largura da ilha inteira a cada prédio novo). Uma segunda medição,
  com outra sessão pesando na VM (carga 4,2), deu 162 ms e foi descartada.
- Áudio sem tela não toca; o custo dele no PC alvo (geração do vento, 22 kHz) se vê no `--benchmark`.

### 2026-10-14 22:19:36 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| jogo novo: arquipélago, terreno, água e árvores | 7827 ms (semente 1840, 54682 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1451 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 21467 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.75 / 4.16 / 5.12 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.07 · produção 0.63 · logística 1.30 · necessidades 0.24 · população 1.22 · economia 0.00 · navios 0.08 |
| construir um prédio com a ilha cheia | 53.1 ms (limite 50 ms): comando e vistas 53.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.2 · serviços 9.5 · módulos e poluição 0.0 · armazéns 19.0 · produção 6.4 · grupos de casas 1.6 |
| salvar | 189 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2049 ms |
| quadro com tudo visível | 4624 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 6786 janelas |
| multidão saindo de casa (rotas novas) | 489 quadros, 4044 ms; 1423 rotas, 1.48 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.60 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.1 / 0.0 FPS / 44929 ms em 7 quadros (meta 60 FPS), a partir das 07:00 |

### 2026-10-15 12:25:23 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| jogo novo: arquipélago, terreno, água e árvores | 7135 ms (semente 1840, 54682 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1460 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 21437 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.93 / 4.42 / 5.37 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.06 · produção 0.76 · logística 1.31 · necessidades 0.23 · população 1.16 · economia 0.00 · navios 0.07 |
| construir um prédio com a ilha cheia | 52.1 ms (limite 50 ms): comando e vistas 52.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 10.5 · serviços 8.8 · módulos e poluição 0.0 · armazéns 17.5 · produção 7.0 · grupos de casas 1.4 |
| salvar | 161 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2008 ms |
| quadro com tudo visível | 4485 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 6786 janelas |
| multidão saindo de casa (rotas novas) | 473 quadros, 2910 ms; 1421 rotas, 1.05 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.48 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.2 / 0.1 FPS / 7803 ms em 10 quadros (meta 60 FPS), a partir das 07:00 |

Fase 11 (combate naval, eletricidade e especialistas), com outra sessão pesando na VM (carga ~3,2):

- **Tick**: média 3,93 ms, 95% em 4,42 ms (antes 3,75 / 4,16). A produção passou de 0,63 para 0,76 ms:
  cada fábrica confere as usinas do raio e o especialista do prédio a cada tick. A carga do benchmark
  não tem usina nem especialista, então o resto é ruído da VM; a média segue abaixo dos 4 ms.
- **Construir com a ilha cheia**: 52,1 ms (antes 53,1), no limite de 50 ms, como já estava; a folga
  volta otimizando o recálculo dos armazéns (17,5 ms).
- Combate e oferta de especialistas não aparecem no tick: sem guerra o combate só repara, e a oferta só
  compara o número da volta.

### 2026-10-15 14:35:44 — Intel(R) Xeon(R) CPU E5-2699 v4 @ 2.20GHz

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| jogo novo: arquipélago, terreno, água e árvores | 7292 ms (semente 1840, 54682 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1170 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15284 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.78 / 4.23 / 5.17 ms (orçamento 4.0 ms) |
| tick por sistema | força de trabalho 0.06 · produção 0.75 · logística 1.24 · necessidades 0.23 · população 1.12 · economia 0.00 · navios 0.07 |
| construir um prédio com a ilha cheia | 37.3 ms (limite 50 ms): comando e vistas 37.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.2 · serviços 7.7 · módulos e poluição 0.0 · armazéns 5.4 · produção 5.1 · grupos de casas 1.4 |
| salvar | 180 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2014 ms |
| quadro com tudo visível | 5212 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 6786 janelas |
| multidão saindo de casa (rotas novas) | 494 quadros, 3088 ms; 1422 rotas, 1.10 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.48 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.1 / 0.1 FPS / 8361 ms em 10 quadros (meta 60 FPS), a partir das 07:00 |

Desempenho depois da Fase 11 (recálculo do estado derivado), com a VM livre (carga ~1,7):

- **Construir com a ilha cheia**: 37,3 ms (antes 52,1), de volta abaixo do limite de 50 ms com folga.
  Armazéns 17,5 → 5,4 ms e produção 7,0 → 5,1. As buscas em largura (trechos de estrada, armazém mais
  próximo, alcance de serviço) não montam mais um Array por célula visitada; os trechos pulam de
  estrada em estrada pelo `find` em vez de varrer as 62,5 mil células da ilha em GDScript; e a frente
  dos prédios vira índice da grade (`Footprint.front_indices`) sem lista de `Vector2i`. Medido só a
  simulação (sem vistas, média de 10 recálculos), o recálculo passou de 36,0 para 26,2 ms.
- O que sobra pesando: prédios (~9 ms, acesso à estrada de cada um dos ~1.000 prédios) e serviços
  (~8 ms, o mapa das casas pela célula da frente).

### 2026-10-24 16:35:30 — AMD Ryzen 7 PRO 1700 Eight-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| jogo novo: arquipélago, terreno, água e árvores | 11652 ms (semente 1840, 93919 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1402 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 20856 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 3.10 / 4.38 / 6.09 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.93 · produção 0.78 · população 0.70 · necessidades 0.24 · navios 0.11 · riscos 0.11 · força de trabalho 0.06 · marcos, metas e vitória 0.05 · eventos, encomendas e especialistas 0.05 · estaleiro 0.03 · combate 0.02 · rivais 0.01 · estatísticas 0.01 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 41.2 ms (limite 50 ms): comando e vistas 41.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 9.6 · serviços 8.4 · módulos, poluição e beleza 0.0 · armazéns 9.6 · produção 5.7 · grupos de casas 1.4 |
| salvar | 184 ms (56 KB) |
| carregar (inclui refazer as vistas) | 3101 ms |
| quadro com tudo visível | 8146 ms (0 FPS) — llvmpipe (LLVM 20.1.2, 256 bits) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22639 janelas |
| multidão saindo de casa (rotas novas) | 535 quadros, 4884 ms; 1422 rotas, 1.60 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.60 ms por quadro |
| dia inteiro em 60 s a 1x, câmera a 40/120/300 m (FPS médio / 1% pior / pior quadro) | 0.1 / 0.1 FPS / 13631 ms em 5 quadros (meta 60 FPS), a partir das 10:00 |

Fase 29 (fôlego da simulação), medida antes e depois no mesmo dia e na mesma máquina. A VM agora roda num AMD Ryzen 7 PRO
1700, e não mais no Xeon E5-2699 das medições anteriores: comparar com as datas antigas não vale.

- **Tick**: média 4,19 → 3,10 ms, 95% 4,68 → 4,38 (nas rodadas só do tick, `-- --so-tick`, com a VM livre: ~3,05 ms e
  95% em ~3,4). Por etapa, agora medidas por dentro do tick (antes o benchmark media só sete dos dezoito sistemas):
  população 1,27 → 0,70, logística 1,28 → 0,93, produção 0,91 → 0,78. Carroças na rua depois de 2 min: 147 de 200,
  antes e depois (o resultado da simulação não mudou).
- **Construir com a ilha cheia**: 48,1 → 41,2 ms. Armazéns 16,0 → 9,6 ms e serviços 9,4 → 8,4: as buscas em largura das
  estradas liam cada vizinha duas vezes e conferiam os quatro cantos da diagonal (Fase 17) em toda célula.
- O que sobra pesando no tick: a logística (as 200 carroças a cada tick) e a produção; na obra, os prédios (~9,6 ms, o
  acesso à estrada de cada um) e os serviços (~8,4 ms).

## Fase 32 — medida e nitidez

A partir desta fase o dia inteiro anda num **trajeto de câmera fixo** (um terço a 40, 120 e 300 m, dando uma volta
inteira em torno do mesmo ponto) e mede cada quadro em bruto: o relógio entre dois quadros (não o `delta`, que é
suavizado), a CPU e a GPU do viewport (`viewport_set_measure_render_time`, que vale também com VSync), o tick da
simulação que caiu em cada quadro e as pipelines compiladas no caminho. O resumo traz FPS médio, **1% low e 0,1% low**
(a média do 1% e do 0,1% de quadros mais lentos, em FPS), p50, p95, p99 e o pior quadro. Os quadros brutos vão num JSON
ao lado do `.md` (`benchmark_quadros.json`, `format` 1; no executável, `user://benchmark_quadros.json`), sempre o da
última rodada. `-- --todos-os-niveis` repete o dia nos quatro níveis gráficos. Desde esta fase o jogo também desenha a
primeira vez de cada material atrás da cortina (`WarmUp`), e o benchmark conta as pipelines compiladas montando e
desenhando a cidade de teste depois disso.

### Primeira vez atrás da cortina, na VM (25/10/2026)

Partida na ilha plana, nível baixo, um prédio de cada tipo (67) construído na partida depois de montada, medindo os dois
quadros seguintes a cada um. Lavapipe: o tempo absoluto não vale, só a comparação.

| | Montar a partida | Pipelines compiladas (malha / superfície / desenho / especialização) | Média / p95 / pior dos dois quadros |
|---|---|---|---|
| sem o `WarmUp` | 3,0 s | 4 / 12 / 0 / 3 | 1856 / 2045 / 3889 ms |
| com o `WarmUp` | 7,2 s | 0 / 6 / 0 / 1 | 1821 / 1970 / 3107 ms |

O rascunho tira as compilações de malha, metade das de superfície e o pior quadro cai ~20%; a média quase não muda
porque no lavapipe o desenho domina cada quadro. O preço são ~4 s a mais atrás da cortina na VM (na placa deve ser
bem menos). As 6 de superfície que sobram ainda pedem a medição na RTX 3060.

### Como medir no PC com a RTX 3060

O que fecha a Fase 32 é esta tabela, que ainda não existe (todo número de quadro até aqui é da VM, sem GPU). Com o
`Society.exe` desta versão, no Windows, feche o resto e rode, em 1080p e depois em 4K (resolução da área de trabalho, tela
cheia nas opções):

```bat
Society.exe -- --benchmark --todos-os-niveis
Society.exe --rendering-driver d3d12 -- --benchmark --todos-os-niveis
```

Cada rodada leva ~10 min (a montagem da cidade e quatro dias de 60 s) e mostra o resultado na tela; o `.md` e o JSON
ficam em `%APPDATA%\Godot\app_userdata\Society\` (o caminho aparece no fim). Repita uma vez com o VSync desligado nas
opções. Mande os dois arquivos de cada rodada: a tabela abaixo sai deles.

Na mesma sessão, confira no ultra se as **nuvens volumétricas** aparecem certas (no Vulkan por software elas escurecem a
tela inteira) e se o FSR 2.2 do ultra deixa rastro nos pedestres e na água. A decisão do driver (Vulkan, o de hoje, ou
D3D12, sem cache de pipeline na 4.7.2 mas que costuma dar mais FPS) fica registrada aqui com os números.

### Primeira medição numa GPU de verdade (25/10/2026)

**Não é a RTX 3060**: o PC do dono do produto tem uma **RTX 5060** (driver 32.0.16.2101) com um Ryzen 7 5700X, Windows
11 e monitor de 1080p. O dono decidiu fechar a fase com esta medição. `Society.exe` de release exportado nesse PC pelo
`--headless` (logo, **sem o shader baker**), tela de 1920×1080, VSync ligado, `-- --benchmark --todos-os-niveis`; os
`.md` e os JSON de cada rodada ficaram em `exportado/benchmark/` no PC, e o JSON da rodada Vulkan está em
`docs/benchmark_quadros.json`.

| Driver | Resolução | Nível | FPS médio | 1% low | 0,1% low | Pior quadro | GPU média (p99) |
|---|---|---|---|---|---|---|---|
| Vulkan | 1080p | baixo | 114,1 | 62,1 | 49,0 | 26 ms | 8,3 ms (11,6) |
| Vulkan | 1080p | médio | 68,9 | 47,2 | 32,8 | 42 ms | 14,0 ms (19,3) |
| Vulkan | 1080p | alto | 48,6 | 39,4 | 35,7 | 28 ms | 20,1 ms (24,2) |
| Vulkan | 1080p | ultra | 29,8 | 8,5 | 0,8 | 1297 ms | 32,3 ms (42,3) |
| D3D12 | 1080p | baixo | 116,7 | 61,3 | 40,8 | 37 ms | 8,2 ms (11,4) |
| D3D12 | 1080p | médio | 68,5 | 45,1 | 33,0 | 36 ms | 14,3 ms (19,9) |
| D3D12 | 1080p | alto | 48,3 | 38,1 | 31,0 | 34 ms | 20,5 ms (25,0) |
| D3D12 | 1080p | ultra | 29,6 | 6,3 | 0,5 | 1964 ms | 32,4 ms (42,6) |

Uma segunda rodada Vulkan (que devia ter sido D3D12: o argumento do driver não chegou ao jogo) repetiu a primeira:
baixo 112,4, médio 69,2, alto 48,8 e ultra 29,6 FPS, mas com pior quadro de 154 ms no ultra.

- **Driver: fica o Vulkan.** Os dois empatam em todos os níveis (diferença abaixo de 3%, dentro da variação entre
  rodadas), e o D3D12 leva o dobro para abrir o jogo novo (8,0 s contra 3,9 s), sem cache de pipeline na 4.7.2.
- **O alto não bate a meta**: 48 FPS, quadro de 21,7 ms (p50) contra 16,6 ms. É a GPU (20 ms por quadro); a CPU do
  render gasta ~1,4 ms e o tick por quadro ~0,15 ms. A conta de onde vão os 20 ms (sombras, SSAO/SSIL, neblina
  volumétrica, luzes de área) fica para uma fase de desempenho gráfico; o médio também passa de 60 FPS só na média
  (p95 de 19,6 ms).
- **O ultra trava**: pior quadro de 154 a 1.964 ms nas três rodadas, com pior tick de 49 a 122 ms no mesmo dia, e
  pipelines compiladas no dia sem diferença para o alto. Não foi investigado; candidatos são a entrada das nuvens
  volumétricas e o FSR 2.2.
- **CPU com folga**: tick médio 1,03–1,07 ms (orçamento 4 ms), construir com a ilha cheia 13,6–14,0 ms (limite 50 ms),
  jogo novo 3,6–3,9 s no Vulkan.
- **Não medido**: 4K (o monitor é de 1080p), VSync desligado, o export com o shader baker (precisa do editor), e a
  conferência no olho das nuvens volumétricas e do rastro do FSR no ultra.

As duas rodadas, como o benchmark grava:

### 2026-10-25 17:37:02 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| jogo novo: arquipélago, terreno, água e árvores | 3884 ms (semente 1840, 93919 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 426 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 7196 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.07 / 1.20 / 2.15 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.32 · produção 0.27 · população 0.23 · necessidades 0.09 · navios 0.04 · riscos 0.03 · força de trabalho 0.03 · marcos, metas e vitória 0.02 · estaleiro 0.01 · eventos, encomendas e especialistas 0.01 · combate 0.01 · rivais 0.00 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 13.6 ms (limite 50 ms): comando e vistas 13.6 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 2.6 · serviços 2.9 · módulos, poluição e beleza 0.0 · armazéns 2.7 · produção 1.9 · grupos de casas 0.4 |
| salvar | 68 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1246 ms |
| quadro com tudo visível | 10 ms (103 FPS) — NVIDIA GeForce RTX 5060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22639 janelas |
| multidão saindo de casa (rotas novas) | 233 quadros, 1070 ms; 1392 rotas, 0.47 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.22 ms por quadro |
| dia inteiro em 60 s a 1x, Baixa, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 114.1 / 62.1 / 49.0 FPS / 26 ms em 6845 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Baixa (p50 / p95 / p99) | 8.5 / 11.4 / 14.5 ms; GPU média 8.3 ms (p99 11.6); CPU do render média 0.9 ms |
| tick por quadro no Baixa (média / p99 / pior) | 0.07 / 1.53 / 10.77 ms |
| pipelines compiladas no dia, Baixa (desenho / superfície / malha / especialização) | 0 / 0 / 0 / 22 |
| dia inteiro em 60 s a 1x, Média, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 68.9 / 47.2 / 32.8 FPS / 42 ms em 4136 quadros (meta 60 FPS), a partir das 11:00 |
| quadro no Média (p50 / p95 / p99) | 13.7 / 19.6 / 19.9 ms; GPU média 14.0 ms (p99 19.3); CPU do render média 1.4 ms |
| tick por quadro no Média (média / p99 / pior) | 0.11 / 1.68 / 3.30 ms |
| pipelines compiladas no dia, Média (desenho / superfície / malha / especialização) | 10 / 38 / 0 / 52 |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 48.6 / 39.4 / 35.7 FPS / 28 ms em 2917 quadros (meta 60 FPS), a partir das 11:59 |
| quadro no Alta (p50 / p95 / p99) | 21.8 / 24.4 / 24.9 ms; GPU média 20.1 ms (p99 24.2); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 1.73 / 3.18 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 5 / 46 / 0 / 51 |
| dia inteiro em 60 s a 1x, Ultra, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 29.8 / 8.5 / 0.8 FPS / 1297 ms em 1787 quadros (meta 60 FPS), a partir das 13:00 |
| quadro no Ultra (p50 / p95 / p99) | 35.7 / 40.6 / 42.9 ms; GPU média 32.3 ms (p99 42.3); CPU do render média 2.3 ms |
| tick por quadro no Ultra (média / p99 / pior) | 0.29 / 1.94 / 51.15 ms |
| pipelines compiladas no dia, Ultra (desenho / superfície / malha / especialização) | 2 / 29 / 0 / 51 |

### 2026-10-25 17:47:44 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · d3d12 · (1920, 1080) · VSync ligado |
| jogo novo: arquipélago, terreno, água e árvores | 8010 ms (semente 1840, 93919 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 427 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 7158 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.04 / 1.15 / 1.93 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.31 · produção 0.26 · população 0.22 · necessidades 0.08 · navios 0.04 · riscos 0.03 · força de trabalho 0.03 · marcos, metas e vitória 0.02 · estaleiro 0.01 · eventos, encomendas e especialistas 0.01 · combate 0.01 · rivais 0.00 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 14.0 ms (limite 50 ms): comando e vistas 14.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 2.6 · serviços 2.8 · módulos, poluição e beleza 0.0 · armazéns 2.8 · produção 1.9 · grupos de casas 0.4 |
| salvar | 61 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1358 ms |
| quadro com tudo visível | 9 ms (107 FPS) — NVIDIA GeForce RTX 5060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22639 janelas |
| multidão saindo de casa (rotas novas) | 233 quadros, 1070 ms; 1381 rotas, 0.47 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.23 ms por quadro |
| dia inteiro em 60 s a 1x, Baixa, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 116.7 / 61.3 / 40.8 FPS / 37 ms em 7002 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Baixa (p50 / p95 / p99) | 8.3 / 11.1 / 14.3 ms; GPU média 8.2 ms (p99 11.4); CPU do render média 0.9 ms |
| tick por quadro no Baixa (média / p99 / pior) | 0.06 / 1.52 / 12.48 ms |
| pipelines compiladas no dia, Baixa (desenho / superfície / malha / especialização) | 0 / 0 / 0 / 22 |
| dia inteiro em 60 s a 1x, Média, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 68.5 / 45.1 / 33.0 FPS / 36 ms em 4108 quadros (meta 60 FPS), a partir das 10:59 |
| quadro no Média (p50 / p95 / p99) | 13.7 / 19.5 / 20.1 ms; GPU média 14.3 ms (p99 19.9); CPU do render média 1.2 ms |
| tick por quadro no Média (média / p99 / pior) | 0.11 / 1.68 / 3.22 ms |
| pipelines compiladas no dia, Média (desenho / superfície / malha / especialização) | 10 / 38 / 0 / 52 |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 48.3 / 38.1 / 31.0 FPS / 34 ms em 2900 quadros (meta 60 FPS), a partir das 11:59 |
| quadro no Alta (p50 / p95 / p99) | 21.8 / 24.5 / 25.2 ms; GPU média 20.5 ms (p99 25.0); CPU do render média 1.4 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 1.74 / 3.26 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 5 / 48 / 0 / 51 |
| dia inteiro em 60 s a 1x, Ultra, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 29.6 / 6.3 / 0.5 FPS / 1964 ms em 1780 quadros (meta 60 FPS), a partir das 13:00 |
| quadro no Ultra (p50 / p95 / p99) | 35.4 / 39.9 / 42.9 ms; GPU média 32.4 ms (p99 42.6); CPU do render média 2.3 ms |
| tick por quadro no Ultra (média / p99 / pior) | 0.28 / 2.27 / 48.65 ms |
| pipelines compiladas no dia, Ultra (desenho / superfície / malha / especialização) | 2 / 31 / 0 / 53 |

## Fase 33 — Por cima do mundo

Mesma carga e mesmo PC da medição da Fase 32 (RTX 5060, 1080p, VSync ligado, Vulkan, `-- --benchmark
--todos-os-niveis`), com a grade no chão, a prévia com o modelo e os ícones de estado agregados de longe.

| Nível | FPS médio (Fase 32 → 33) | 1% low | GPU média | CPU do render |
|---|---|---|---|---|
| baixo | 114,1 → 147,1 | 62,1 → 60,3 | 8,3 → 5,6 ms | 0,9 → 0,5 ms |
| médio | 68,9 → 91,5 | 47,2 → 54,2 | 14,0 → 10,3 ms | 1,4 → 0,6 ms |
| alto | 48,6 → **62,2** | 39,4 → 49,3 | 20,1 → 15,6 ms | 1,6 → 0,7 ms |
| ultra | 29,8 → 37,1 | 8,5 → 23,8 | 32,3 → 26,4 ms | 2,3 → 0,8 ms |

- **Correção (mesmo dia, 19:34): esta rodada não se repetiu.** O mesmo build da Fase 33, exportado de novo e medido
  outra vez no mesmo PC, deu baixo 113,8, médio 69,2, alto **49,1** e ultra 30,4 FPS (GPU média 8,2 / 14,0 / 20,0 /
  32,3 ms), igual à Fase 32. Os ícones agregados **não** trouxeram o ganho da tabela acima; o que mudou naquela rodada
  não foi descoberto. Vale a regra: um número de FPS só entra depois de repetido.
- **Tick**: 1,09 ms de média (1,07 na Fase 32): a regra dos ícones é da apresentação e não toca na simulação. Obra com
  a ilha cheia em 14,2 ms (13,6).
- **Ultra**: o pior quadro caiu para 141 ms (de 154 a 1.964 ms), mas o pior tick ainda chegou a 131 ms; a travada
  continua sem investigação.

### 2026-10-25 18:22:08 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| jogo novo: arquipélago, terreno, água e árvores | 3815 ms (semente 1840, 93919 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 471 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 7601 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.09 / 1.44 / 2.19 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.33 · produção 0.28 · população 0.23 · necessidades 0.09 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.02 · estaleiro 0.01 · eventos, encomendas e especialistas 0.01 · combate 0.01 · rivais 0.00 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 14.2 ms (limite 50 ms): comando e vistas 14.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 2.8 · serviços 2.9 · módulos, poluição e beleza 0.0 · armazéns 2.8 · produção 2.0 · grupos de casas 0.4 |
| salvar | 68 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1316 ms |
| quadro com tudo visível | 6 ms (163 FPS) — NVIDIA GeForce RTX 5060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 13 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22639 janelas |
| multidão saindo de casa (rotas novas) | 249 quadros, 1227 ms; 1381 rotas, 0.53 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Baixa, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 147.1 / 60.3 / 47.4 FPS / 35 ms em 8829 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Baixa (p50 / p95 / p99) | 6.0 / 9.0 / 14.9 ms; GPU média 5.6 ms (p99 8.4); CPU do render média 0.5 ms |
| tick por quadro no Baixa (média / p99 / pior) | 0.05 / 1.49 / 11.03 ms |
| pipelines compiladas no dia, Baixa (desenho / superfície / malha / especialização) | 0 / 0 / 0 / 28 |
| dia inteiro em 60 s a 1x, Média, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 91.5 / 54.2 / 43.8 FPS / 33 ms em 5490 quadros (meta 60 FPS), a partir das 10:59 |
| quadro no Média (p50 / p95 / p99) | 10.0 / 15.2 / 16.6 ms; GPU média 10.3 ms (p99 15.1); CPU do render média 0.6 ms |
| tick por quadro no Média (média / p99 / pior) | 0.08 / 1.56 / 2.71 ms |
| pipelines compiladas no dia, Média (desenho / superfície / malha / especialização) | 5 / 13 / 0 / 24 |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 62.2 / 49.3 / 44.2 FPS / 23 ms em 3730 quadros (meta 60 FPS), a partir das 12:00 |
| quadro no Alta (p50 / p95 / p99) | 17.8 / 18.8 / 19.5 ms; GPU média 15.6 ms (p99 18.8); CPU do render média 0.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.12 / 1.59 / 3.09 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 7 / 13 / 0 / 22 |
| dia inteiro em 60 s a 1x, Ultra, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 37.1 / 23.8 / 10.8 FPS / 141 ms em 2228 quadros (meta 60 FPS), a partir das 13:00 |
| quadro no Ultra (p50 / p95 / p99) | 29.0 / 33.5 / 36.0 ms; GPU média 26.4 ms (p99 35.2); CPU do render média 0.8 ms |
| tick por quadro no Ultra (média / p99 / pior) | 0.26 / 1.70 / 131.29 ms |
| pipelines compiladas no dia, Ultra (desenho / superfície / malha / especialização) | 7 / 14 / 0 / 24 |

## Fase 34 — Chão sem xadrez

Mesmo PC e mesma carga (RTX 5060, 1080p, VSync ligado, Vulkan, `-- --benchmark --todos-os-niveis`), comparada com a
repetição da Fase 33 (a primeira rodada dela não vale, ver acima).

| Nível | FPS médio (Fase 33 → 34) | 1% low | GPU média | Hex-tiling |
|---|---|---|---|---|
| baixo | 113,8 → 108,9 | 61,7 → 56,4 | 8,2 → 8,6 ms | desligado |
| médio | 69,2 → 63,8 | 45,1 → 47,0 | 14,0 → 15,2 ms | ligado |
| alto | 49,1 → 46,2 | 40,3 → 34,0 | 20,0 → 21,2 ms | ligado |
| ultra | 30,4 → 29,2 | 20,2 → 20,3 | 32,3 → 33,7 ms | ligado |

O custo do terreno sozinho, efeito por efeito (`tools/terrain_cost.tscn`: só o arquipélago da semente 1840, sol e
céu simples, câmera a 55° olhando o centro da ilha principal; `antigo` é o shader da Fase 33):

### 2026-10-25 19:29:24 — NVIDIA GeForce RTX 5060

| Variante | GPU a 40 m / 120 m / 300 m (ms) |
|---|---|
| completo | 1.49 / 1.52 / 1.25 |
| sem hex-tiling | 1.02 / 1.15 / 1.26 |
| sem ruído nas bordas | 1.48 / 1.50 / 1.22 |
| sem macro-variação | 1.49 / 1.49 / 1.21 |
| sem reamostragem de longe | 1.46 / 1.44 / 1.19 |
| sem triplanar | 1.48 / 1.51 / 1.24 |
| tudo desligado | 0.95 / 1.03 / 1.13 |
| antigo | 1.00 / 1.03 / 1.06 |

- **O caro é o hex-tiling**: ~0,5 ms de perto (40 e 120 m) e nada a 300 m, onde ele já não vale. Ruído nas bordas,
  macro-variação, reamostragem de longe e triplanar custam juntos menos de 0,1 ms. No jogo inteiro a GPU subiu
  0,4 ms no baixo (sem hex-tiling) e 1,2 a 1,4 ms nos outros: a cidade e a água por cima mudam a conta, mas a ordem
  bate.
- **Jogo novo**: 4,3 s (3,9 na Fase 33), o bake das texturas de dados (~0,5 s). Carregar: 1,37 s (1,32). Tick
  igual (1,04 ms).
- **Decisão pendente do dono do produto**: em que níveis o hex-tiling entra. Ele custa ~1,2 ms no alto, que já está
  abaixo dos 60 FPS (46 FPS, GPU em ~21 ms); a reamostragem de longe sozinha já tira o xadrez visto do alto.

### 2026-10-25 19:02:55 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| jogo novo: arquipélago, terreno, água e árvores | 4267 ms (semente 1840, 93919 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 426 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 7035 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.04 / 1.20 / 1.90 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.32 · produção 0.27 · população 0.22 · necessidades 0.09 · navios 0.04 · riscos 0.03 · força de trabalho 0.03 · marcos, metas e vitória 0.02 · estaleiro 0.01 · eventos, encomendas e especialistas 0.01 · combate 0.01 · rivais 0.00 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 14.0 ms (limite 50 ms): comando e vistas 14.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 2.9 · serviços 2.9 · módulos, poluição e beleza 0.0 · armazéns 2.9 · produção 1.9 · grupos de casas 0.4 |
| salvar | 63 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1366 ms |
| quadro com tudo visível | 11 ms (95 FPS) — NVIDIA GeForce RTX 5060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1904 na rua (teto 2000); 22639 janelas |
| multidão saindo de casa (rotas novas) | 226 quadros, 1061 ms; 1362 rotas, 0.47 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.21 ms por quadro |
| dia inteiro em 60 s a 1x, Baixa, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 108.9 / 56.4 / 50.2 FPS / 20 ms em 6536 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Baixa (p50 / p95 / p99) | 8.8 / 12.0 / 16.6 ms; GPU média 8.6 ms (p99 12.1); CPU do render média 0.9 ms |
| tick por quadro no Baixa (média / p99 / pior) | 0.07 / 1.57 / 9.75 ms |
| pipelines compiladas no dia, Baixa (desenho / superfície / malha / especialização) | 0 / 0 / 0 / 22 |
| dia inteiro em 60 s a 1x, Média, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 63.8 / 47.0 / 38.1 FPS / 30 ms em 3827 quadros (meta 60 FPS), a partir das 10:59 |
| quadro no Média (p50 / p95 / p99) | 15.3 / 20.1 / 20.4 ms; GPU média 15.2 ms (p99 19.8); CPU do render média 1.1 ms |
| tick por quadro no Média (média / p99 / pior) | 0.12 / 1.58 / 2.62 ms |
| pipelines compiladas no dia, Média (desenho / superfície / malha / especialização) | 10 / 40 / 0 / 52 |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 46.2 / 34.0 / 32.1 FPS / 33 ms em 2775 quadros (meta 60 FPS), a partir das 11:59 |
| quadro no Alta (p50 / p95 / p99) | 22.9 / 25.3 / 29.0 ms; GPU média 21.2 ms (p99 28.6); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 1.64 / 3.12 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 5 / 45 / 0 / 52 |
| dia inteiro em 60 s a 1x, Ultra, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 29.2 / 20.3 / 7.1 FPS / 141 ms em 1752 quadros (meta 60 FPS), a partir das 12:59 |
| quadro no Ultra (p50 / p95 / p99) | 36.7 / 41.3 / 42.8 ms; GPU média 33.7 ms (p99 42.3); CPU do render média 1.5 ms |
| tick por quadro no Ultra (média / p99 / pior) | 0.34 / 1.72 / 127.55 ms |
| pipelines compiladas no dia, Ultra (desenho / superfície / malha / especialização) | 2 / 30 / 0 / 52 |

## Fase 39 — prédios assentados (26/10/2026)

**Medido no PC do dono sem nada na tela dele**: o Godot roda numa área de trabalho escondida do Windows
(`F:\ferramentas\desktop_oculto.ps1`, `CreateDesktop`): a RTX 5060 desenha a janela de 1920 × 1080, que nunca
aparece. Os números desse jeito saem bem acima dos da tela de verdade (o alto a ~85 FPS e a GPU em ~11 ms, contra ~46
FPS e ~21 ms na Fase 34, medidos na tela, com o dono olhando): **só valem comparados entre si**, antes e depois da fase,
no mesmo método. Por isso a referência foi medida de novo, no commit anterior à fase (num worktree), com o mesmo
benchmark.

O benchmark ganhou a linha de objetos, draw calls e primitivas no quadro com tudo visível (o roteiro pede medir as draw
calls na Fase 39).

| Medida (alto, área de trabalho escondida) | Antes (a044b03) | Fase 39 |
|---|---|---|
| objetos · draw calls · primitivas | 2.904 · 1.101 · 20,38 M | 2.914 · 1.248 · 20,71 M |
| dia inteiro: FPS médio / 1% low / 0,1% low / pior quadro | 86,2 / 43,3 / 35,1 / 32 ms | 85,0 / 44,3 / 38,6 / 27 ms |
| quadro p50 / p95 / p99; GPU média; CPU do render | 11,0 / 15,6 / 21,2 ms; 10,8; 1,2 ms | 11,1 / 15,9 / 21,0 ms; 11,1; 1,2 ms |
| construir um prédio com a ilha cheia | 17,7 ms | 17,9 ms |
| montar tudo / carregar | 9.146 / 1.595 ms | 9.535 / 1.943 ms |

- O plinto de cada prédio no barranco como nó próprio somava ~585 objetos e ~710 draw calls (o benchmark monta a cidade
  no relevo da semente 1840): agora todos os plintos vão numa malha só.
- Montar e carregar sobem ~0,4 s: as variações de telhado (3 × 3 × 2 por classe, 74 malhas para 600 casas, ~18 ms cada
  na primeira vez). Construir com a ilha cheia não mudou.

### 2026-10-26 06:07:02 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| jogo novo: arquipélago, terreno, água e árvores | 5666 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 582 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9535 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.29 / 1.50 / 2.51 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.39 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.9 ms (limite 50 ms): comando e vistas 17.9 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.2 · produção 2.6 · grupos de casas 0.5 |
| salvar | 77 ms (56 KB) |
| carregar (inclui refazer as vistas) | 1943 ms |
| quadro com tudo visível | 11 ms (87 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2914 · 1248 · 20710120 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 312 quadros, 1524 ms; 1410 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 85.0 / 44.3 / 38.6 FPS / 27 ms em 5099 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.1 / 15.9 / 21.0 ms; GPU média 11.1 ms (p99 15.9); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.92 / 13.67 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 10 / 11 / 0 / 51 |

## Fase 40 — campos em colcha (26/10/2026)

O benchmark principal não tem fazendas: a medida é a de `tools/fields_cost.tscn` (um bairro rural de 7 fazendas com 39
campos e pastos na semente 1840, alto, área de trabalho escondida), no commit da Fase 39 (num worktree) e com a fase.

| Medida | Antes (2426982) | Fase 40 |
|---|---|---|
| montar a CropView / refazer depois de uma obra | 4,6 / — ms | 27,0 / 6,9 ms |
| a 110 m: quadro / GPU | 9,33 / 8,98 ms | 9,28 / 8,94 ms |
| a 110 m: objetos · draw calls | 1.126 · 878 | 1.014 · 766 |
| a 420 m: quadro / GPU | 6,38 / 6,04 ms | 6,36 / 6,02 ms |
| a 420 m: objetos · draw calls | 875 · 631 | 839 · 595 |

- As caixas do campo e do pasto saíram (menos objetos); a terra de todos os campos é uma malha só, e as sebes e os muros
  vão em MultiMesh sem sombra.
- A primeira montagem calcula o terreno sob cada planta e leira (~27 ms); depois fica em cache pelo lote, e refazer a
  vista a cada obra custa ~7 ms (sem tela, antes da fase: 5,5 ms).

## Fase 41 — mata e recheio (26/10/2026)

Área de trabalho escondida, alto, comparado com a Fase 39 (a 40 não mexe na carga do benchmark: ele não tem fazendas).

| Medida | Fase 39 | Fase 41 |
|---|---|---|
| jogo novo / carregar | 5.666 / 1.943 ms | 6.062 / 2.433 ms |
| construir um prédio com a ilha cheia | 17,9 ms | 17,8 ms |
| dia inteiro: FPS médio / 1% low / 0,1% low / pior quadro | 85,0 / 44,3 / 38,6 / 27 ms | 82,9 / 44,0 / 37,1 / 28 ms |
| quadro p50 / p95 / p99; GPU média | 11,1 / 15,9 / 21,0; 11,1 ms | 11,6 / 16,1 / 21,2; 11,4 ms |

- O recheio do arquipélago (28.564 peças) custa ~0,45 s no jogo novo e no carregar; a GPU sobe ~0,3 ms (as copas com
  tufos e o recheio perto da câmera).

### 2026-10-26 06:49:32 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| jogo novo: arquipélago, terreno, água e árvores | 6062 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 582 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9535 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.29 / 1.45 / 2.40 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.39 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.8 ms (limite 50 ms): comando e vistas 17.8 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.2 · produção 2.5 · grupos de casas 0.5 |
| salvar | 79 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2433 ms |
| quadro com tudo visível | 11 ms (87 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2876 · 1210 · 17748740 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 320 quadros, 1528 ms; 1389 rotas, 0.69 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.30 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 82.9 / 44.0 / 37.1 FPS / 28 ms em 4974 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.6 / 16.1 / 21.2 ms; GPU média 11.4 ms (p99 16.1); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.89 / 13.86 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 57 |

## Fase 42 — quadro estável e carregamento real (26/10/2026)

Área de trabalho escondida, alto. A linha nova mede o arquipélago da semente 1840 gerado em série (como a partida faz sem
o menu) e com uma ilha por thread (o jogo novo pelo menu, com a cortina mostrando o progresso): ~977 → ~431 ms, com o
pior quadro de 15 ms enquanto as threads trabalham (a janela não congela na geração). O resto do jogo novo (~5 s) é
montar as vistas, na thread principal. Tick e obra iguais aos da Fase 41.

### 2026-10-26 06:57:26 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 977 / 431 ms (15 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6053 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 585 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9525 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.28 / 1.46 / 2.34 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.38 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.2 ms (limite 50 ms): comando e vistas 18.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.8 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.6 · grupos de casas 0.5 |
| salvar | 76 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2446 ms |
| quadro com tudo visível | 12 ms (86 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2876 · 1210 · 17748740 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 319 quadros, 1536 ms; 1424 rotas, 0.67 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.33 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 82.5 / 44.4 / 38.8 FPS / 27 ms em 4953 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.6 / 16.0 / 21.1 ms; GPU média 11.4 ms (p99 16.1); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.88 / 13.82 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 58 |

## Fase 43 — interface enxuta (26/10/2026)

Área de trabalho escondida, alto: só interface, sem regressão (82,4 FPS, GPU 11,4 ms, obra 18,8 ms, iguais aos da Fase
42 dentro do ruído). Capturas da HUD em 80, 100, 150 e 200% com `tools/capture_phase43.tscn`: a escala de verdade é
limitada pela largura da janela (a HUD pede 1.920 px lógicos), e 200% cabe inteiro a partir de 4K.

### 2026-10-26 07:14:41 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 976 / 435 ms (14 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6416 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 584 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9595 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.29 / 1.55 / 2.41 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.39 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.8 ms (limite 50 ms): comando e vistas 18.8 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 4.0 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.6 · grupos de casas 0.5 |
| salvar | 77 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2413 ms |
| quadro com tudo visível | 11 ms (87 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2877 · 1211 · 17748742 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 313 quadros, 1524 ms; 1408 rotas, 0.67 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.32 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 82.4 / 45.1 / 40.8 FPS / 25 ms em 4944 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.6 / 16.0 / 21.2 ms; GPU média 11.4 ms (p99 16.1); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.89 / 14.04 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 58 |

## Fase 46 — calçamento e esquinas (26/10/2026)

Área de trabalho escondida, alto, contra o commit da Fase 45 (e5b4f32) rodado na mesma sessão (o "antes" vale também
como a medida da Fase 45): todas as medidas antigas iguais dentro do ruído, porque a cidade do benchmark é de terra
(85,3 contra 86,3 FPS e 84,9 contra 84,6 em duas rodadas de cada; GPU 11,0–11,1 ms nos dois; obra 18–19 ms nos dois). A
linha nova, no fim, calça as 2.812 células da cidade: na Fase 45 (ladrilhos) 2812 células: 75 / 70 ms; 14.5 ms (2916 objetos · 1146 draw calls · 60768418 primitivas); na Fase 46 (grade dual), abaixo.
Calçar tudo de uma vez fica mais caro (só ao carregar ou trocar o mundo); a rua nova, mais barata; o quadro, igual.
### 2026-10-26 08:24:11 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 1009 / 440 ms (17 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6129 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 590 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9586 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.29 / 1.45 / 2.56 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.39 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.1 ms (limite 50 ms): comando e vistas 18.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 2.6 · grupos de casas 0.5 |
| salvar | 76 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2421 ms |
| quadro com tudo visível | 11 ms (93 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2877 · 1211 · 17748742 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 311 quadros, 1537 ms; 1403 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 84.9 / 43.3 / 37.0 FPS / 29 ms em 5093 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.3 / 15.5 / 21.3 ms; GPU média 11.1 ms (p99 15.5); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.89 / 14.14 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 58 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 437 / 40 ms; 14.3 ms (2964 objetos · 1194 draw calls · 60198026 primitivas) |

## Fase 47 — QoL de interface (26/10/2026)

Área de trabalho escondida, alto: a fase só mexe na interface e lê a simulação sob demanda, e nada muda (tick 1,27 ms
de média, obra com a ilha cheia 18,1 ms, 84,7 FPS e GPU 11,1 ms no dia inteiro, iguais aos da Fase 46). A linha nova
mede a dica que decompõe no pior caso, com a cidade do benchmark: um bem somando todas as ilhas 0,18 ms e o dinheiro
(10 mil moradores, 600 casas, 234 prédios) 1,5 ms — só quando o mouse para em cima, nunca no tick.
### 2026-10-26 08:47:44 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 998 / 439 ms (17 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6113 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 598 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9629 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.27 / 1.51 / 2.47 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.38 · produção 0.33 · população 0.26 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.1 ms (limite 50 ms): comando e vistas 18.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.5 · grupos de casas 0.5 |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.51 ms |
| salvar | 78 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2476 ms |
| quadro com tudo visível | 11 ms (93 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2887 · 1214 · 17749082 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 320 quadros, 1546 ms; 1397 rotas, 0.70 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.32 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 84.7 / 43.6 / 38.6 FPS / 29 ms em 5080 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.2 / 15.5 / 21.4 ms; GPU média 11.1 ms (p99 15.5); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.86 / 12.93 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 58 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 434 / 39 ms; 14.3 ms (2974 objetos · 1197 draw calls · 60198366 primitivas) |

## Fase 48 — Godot 4.8-beta1, ensaio no ramo godot-4.8 (26/10/2026)

Área de trabalho escondida, alto, mesma sessão: o main na 4.7.2 e o ramo godot-4.8 na 4.8-beta1, com as sombras de
contato e o AO de vários quiques ligados no alto. A 4.8 desenha o mesmo (2.891 objetos, 1.213 draw calls) com a GPU
0,4 ms acima (11,4 contra 11,0 ms) e 81,9 contra 85,2 FPS no dia inteiro; tick, obra e carregar iguais; o pior quadro do
dia foi 76 ms (contra 32), a investigar na estável. Na primeira rodada a 4.8 deu um falso 172 FPS: lia o mouse num
canto da área de trabalho escondida e o pan pela borda levava a câmera para o mar (consertado: o pan só vale depois de
um movimento real do mouse). Na 4.7.2, na mesma sessão: 85,2 FPS, GPU 11,0 ms, obra 18,2 ms.
### Godot 4.8-beta1 (ramo godot-4.8) — 2026-10-26 09:47:28 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 1414 / 435 ms (28 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6968 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 607 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9752 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.27 / 1.93 / 2.46 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.38 · produção 0.32 · população 0.27 · necessidades 0.10 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas e especialistas 0.01 · combate 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.5 ms (limite 50 ms): comando e vistas 17.5 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.3 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.3 · grupos de casas 0.5 |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.17 / 1.58 ms |
| salvar | 76 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2493 ms |
| quadro com tudo visível | 12 ms (84 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2891 · 1213 · 17752026 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 314 quadros, 1548 ms; 1398 rotas, 0.71 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.31 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 81.9 / 41.8 / 22.8 FPS / 76 ms em 4916 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.6 / 15.9 / 21.1 ms; GPU média 11.4 ms (p99 15.8); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.82 / 11.92 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 58 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 444 / 43 ms; 14.5 ms (2977 objetos · 1196 draw calls · 60189362 primitivas) |

## Fase 49 — desfazer e planta (26/10/2026)

Área de trabalho escondida, alto: a linha nova mede a obra pelo histórico de desfazer (o caminho do jogador agora) e o
desfazer dela com a ilha cheia: 14,6 / 15,3 ms (limite 50 ms; a obra direta segue em 18 ms, ambas com as vistas). O
histórico guarda cópias rasas dos dicionários de prédios e carroças e só o retângulo da ação; nada no tick (1,28 ms),
salvar 74 ms (56 KB, sem plantas), carregar e quadro iguais.
### 2026-10-26 10:10:05 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 996 / 449 ms (19 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6305 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 591 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9540 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.28 / 1.43 / 2.41 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.38 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.0 ms (limite 50 ms): comando e vistas 18.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.5 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 14.6 / 15.3 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.55 ms |
| salvar | 74 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2454 ms |
| quadro com tudo visível | 11 ms (91 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2898 · 1221 · 17750440 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 316 quadros, 1507 ms; 1392 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 84.9 / 45.3 / 40.7 FPS / 25 ms em 5095 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.2 / 15.5 / 20.9 ms; GPU média 11.1 ms (p99 15.5); CPU do render média 1.1 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.84 / 12.43 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 58 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 429 / 39 ms; 14.2 ms (2985 objetos · 1204 draw calls · 60190658 primitivas) |

## Fase 50 — kit de época, o caminho (26/10/2026)

Área de trabalho escondida, alto: sem nenhuma peça no repositório, o gancho do BuildingKit (a busca da peça no
spec_for de cada prédio) não muda nada — montar tudo 9,5 s, carregar 2,46 s, obra 17,9 ms, 85,1 FPS e GPU 11,0 ms, iguais
aos da Fase 49.
### 2026-10-26 10:22:27 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 1002 / 443 ms (18 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 6153 ms (semente 1840, 94484 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 598 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9546 ms |
| carroças na rua depois de 2 min | 147 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.28 / 1.43 / 2.35 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.39 · produção 0.33 · população 0.27 · necessidades 0.11 · navios 0.04 · riscos 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · combate 0.01 · eventos, encomendas e especialistas 0.01 · rivais 0.01 · estatísticas 0.00 · economia 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.9 ms (limite 50 ms): comando e vistas 17.9 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.5 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 14.4 / 15.4 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.68 ms |
| salvar | 73 ms (56 KB) |
| carregar (inclui refazer as vistas) | 2460 ms |
| quadro com tudo visível | 11 ms (91 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 2898 · 1221 · 17750440 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 5 / 0 / 11 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22629 janelas |
| multidão saindo de casa (rotas novas) | 315 quadros, 1505 ms; 1375 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 85.1 / 42.9 / 35.9 FPS / 30 ms em 5106 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 11.2 / 15.5 / 21.4 ms; GPU média 11.0 ms (p99 15.5); CPU do render média 1.2 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.11 / 1.85 / 12.91 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 12 / 11 / 0 / 57 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 452 / 39 ms; 14.3 ms (2985 objetos · 1204 draw calls · 60190658 primitivas) |

## Travamento no monitor do dono: ritmo dos quadros (26/10/2026)

O dono sentiu o jogo travando. Benchmark do jogo exportado na tela de verdade (monitor principal de 180 Hz, VSync ligado,
alto): nenhuma congelada (pior quadro 26 ms, tick ~0 nos picos), mas o ritmo irregular — a ~77 FPS cada quadro fica 2 ou
3 batidas do monitor na tela, sem padrão, e o movimento treme. Com o limite automático novo (o maior divisor da taxa do
monitor até 75: 60 FPS em 180 Hz), cada quadro fica sempre 3 batidas:

| Na tela de 180 Hz, alto | média | desvio | quadros 25% acima da média |
|---|---|---|---|
| sem limite | 12,9 ms | 2,6 ms | 12,3% |
| limite 90 (metade de 180) | 13,1 ms | 2,4 ms | 10,6% |
| automático (60) | 16,7 ms | 1,1 ms | 1,1% |

O benchmark mede sem limite como sempre (os números das fases seguem comparáveis); `-- --limite N` mede com um.

## Fase 51 — fotos e retratos nos menus (26/10/2026)

Área de trabalho escondida, alto: só interface (64 fotos de 320 × 240 e 7 retratos carregados sob demanda) — 81,9 FPS,
GPU 11,5 ms, obra 18,3 ms e carregar 2,46 s, dentro do ruído das fases anteriores.

## Fase 52 — ilhas v3 no jeito do Anno (26/10/2026)

Área de trabalho escondida, alto, semente 1840 agora no v3 (o padrão dos jogos novos; antes era o v1): gerar o
arquipélago 787 → 2.637 ms em série e 343 → 1.247 ms em threads, pior quadro durante 17 ms (a mesma conta de ruído do v2
por canto, mais forma; pular a terra nos cantos de mar tirou ~11%; o jogo novo gera atrás da cortina); jogo novo 7,6 s;
obra 16,4 ms; carregar 3,96 s; quadro com tudo visível 11–13 ms e o dia inteiro a 76,7–87,1 FPS de média em duas rodadas
(GPU 10,7–11,9 ms), dentro do ruído da Fase 51 (81,9 FPS, GPU 11,5 ms).

## Fase 53 — cor no jeito do Anno (26/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3): quadro com tudo visível 11 ms (89 FPS), dia inteiro 87,9 FPS de
média (1% low 45,5), GPU média 10,6 ms: o tratamento de cor no shader do terreno não custou nada medível (Fase 52: GPU
10,7–11,9 ms).

## Fase 54 — costa lisa (26/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3): quadro com tudo visível 11 ms (90 FPS), dia inteiro 87,6 FPS de
média (1% low 45,2), GPU média 10,7 ms; jogo novo 8,0 s (7,6 s na Fase 52: a distância até a costa agora olha os oito
vizinhos de cada canto) e carregar 3,84 s. Quadro igual.

## Fase 55 — malha fina na linha d'água (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3): quadro com tudo visível 11 ms (91 FPS), mesmas 1106 draw calls,
dia inteiro 88,9 FPS de média (1% low 46,9), GPU média 10,6 ms; jogo novo 8,7 s (8,0 s na Fase 54: a subgrade dos
quadrados da costa sai em GDScript; nesta rodada o tick e a carga também mediram um pouco mais lentos) e carregar
3,83 s. Quadro igual.
## Fase 56 — rocha nos rochedos e nas falésias (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), duas rodadas: quadro com tudo visível 13 ms (78 FPS), 2776
objetos e 1126 draw calls (+20 da rocha), dia inteiro 77,9 e 77,5 FPS de média, GPU média 11,8 ms; jogo novo 8,9 s.
Na mesma hora, com a `RockView` desligada: 13 ms (77 FPS), dia inteiro 78,8 FPS, GPU 11,5 ms. A queda contra a Fase 55
(91 FPS de manhã) é da máquina nesta hora, não da rocha, que custa até ~0,3 ms de GPU.
## Fase 57 — pedras soltas com a rocha gerada (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), duas rodadas: quadro com tudo visível 18 ms (54 FPS), 2759
objetos e 1109 draw calls (17 a menos que na Fase 56: as pedras de cada trecho cabem em menos malhas), dia inteiro 55,6
e 55,5 FPS de média (p50 16,0 ms), GPU média 10,7 e 10,8 ms; jogo novo 8,9 s, carregar 3,92 s. Na mesma hora, o
commit da Fase 56 sem mudança nenhuma: 19 ms (54 FPS), dia inteiro 55,6 FPS, GPU 10,9 ms. A queda é da máquina nesta
hora (o quadro preso perto de 16 ms com a GPU folgada), não da fase, que é neutra.
## Fase 58 — coqueiro gerado no código (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), duas rodadas: 2745 a 2759 objetos e 1107 a 1109 draw calls (o
mesmo da Fase 57), GPU média 11,5 e 10,7 ms; dia inteiro 78,8 e 40,6 FPS de média (p50 12,2 e 21,7 ms) com a GPU igual:
a máquina oscilou muito nesta tarde, de rodada para rodada, e a GPU é o número que vale para a fase. Jogo novo 8,8 e
10,0 s. "Árvores desenhadas" passa a 28837: o `instance_count` contava parte das camadas de longe, renomeadas pelo
Godot (os 47010 das fases anteriores estavam inflados; ver `docs/plano_fase58.md`).
## Fase 59 — mata tropical (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3): 28837 árvores desenhadas (as mesmas), 2759 objetos e 1109 draw
calls (a ilha tropical fica fora do quadro com tudo visível), GPU média 10,7 ms (p99 14,2), igual à Fase 58; dia
inteiro 51,9 FPS (p50 19,1 ms), com a máquina ainda oscilando nesta tarde; jogo novo 8,7 s, carregar 3,82 s.
## Fase 60 — sub-bosque tropical (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), duas rodadas: 2745 a 2759 objetos e 1107 a 1109 draw calls (as
mesmas), jogo novo 21,7 e 23,1 s, GPU média 22,5 e 22,8 ms, dia inteiro 36,0 e 35,5 FPS. Na mesma hora, o commit da
Fase 59 sem mudança nenhuma: jogo novo 22,8 s, GPU 23,0 ms, dia inteiro 35,1 FPS. A fase é neutra; a máquina inteira
(CPU e GPU) mediu ~2,5 vezes mais lenta nesta hora, com o plano de energia em alto desempenho e a CPU no relógio
cheio — causa fora do jogo (talvez o papel de parede animado em execução disputando a GPU), a conferir com o dono.
## Fase 61 — helicônias (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), com a máquina ainda no estado lento da Fase 60: 2759 objetos e
1109 draw calls (os mesmos), jogo novo 21,8 s, GPU média 21,9 ms, dia inteiro 36,6 FPS — no nível do commit da Fase 59
medido nesse estado (GPU 23,0 ms, 35,1 FPS). Neutra.
## Fase 62 — malha fina na face da falésia (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento: com a falésia refinada, 15 547 741
primitivas no quadro com tudo visível (+20 256), 1107 draw calls (as mesmas), GPU média 21,9 ms, jogo novo 24,4 e 23,9 s,
dia inteiro 36,7 FPS. Na mesma hora com `terrain_cliff_refine_relief_m` = 0 (desligada): 15 527 485 primitivas, GPU 22,0
ms, jogo novo 23,2 s, dia inteiro 36,5 FPS. Custo: ~1 s no jogo novo nesta máquina lenta (as subgrades e as normais
pela subgrade em GDScript; ~0,4 s na velocidade normal) e nada na GPU.
## Fase 63 — jornal (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), com a máquina de volta ao normal: tick médio 1,27 ms (p95 1,48;
a etapa "eventos, encomendas, jornal e especialistas" 0,01 ms — o benchmark roda com os eventos desligados, como o
robô), 2759 objetos e 1109 draw calls, dia inteiro 87,6 FPS (1% low 47,4), GPU média 10,8 ms, jogo novo 10,1 s. O
jornal não toca o desenho; o FPS de volta aos ~88 da manhã confirma que a lentidão das Fases 60 a 62 era da máquina.
## Fase 64 — baleias e golfinhos (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), com a máquina de novo no estado lento das Fases 60 a 62 (jogo novo
23,4 s): 2755 objetos e 1117 draw calls (+8: as duas camadas de bichos e os esguichos), GPU média 22,5 ms e dia inteiro
35,8 FPS — no nível das Fases 60 a 62 medidas nesse estado (GPU 21,9 a 23,0 ms). Neutra.
## Fase 65 — festa na cidade (27/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento: os mesmos 2755 objetos e 1117 draw
calls (o benchmark roda sem eventos: nenhuma festa no quadro), GPU média 22,2 ms, dia inteiro 36,5 FPS. Neutra.
## Fase 66 — prefeitura e políticas (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento: tick médio 1,30 ms (p95 1,84;
1,27 na Fase 63), construir um prédio com a ilha cheia 15,1 ms (o recálculo ganha o laço das prefeituras, vazio no
benchmark), os mesmos 2755 objetos e 1117 draw calls, GPU 22,2 ms, dia inteiro 36,2 FPS. Neutra.
## Fase 67 — zoológico e museu (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento: tick médio 1,30 ms (p95 1,40),
construir com a ilha cheia 15,3 ms, os mesmos 2755 objetos e 1117 draw calls, GPU 22,0 ms, dia inteiro 36,7 FPS.
Neutra (o benchmark não constrói zoológico nem museu).
## Fase 68 — atratividade e turistas (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento: tick médio 1,31 ms (p95 1,44; o
benchmark roda sem eventos, então o turismo não paga e o sistema sai logo), construir com a ilha cheia 15,4 ms (o
recálculo ganha a soma da atratividade), 2769 objetos e 1119 draw calls (+2 na rodada; nada desta fase desenha), GPU
21,8 ms, dia inteiro 36,8 FPS. Neutra.
## Fase 69 — expedições (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento: tick médio 1,32 ms (p95 1,56; sem
expedição, o sistema sai logo), construir com a ilha cheia 15,0 ms, os mesmos 2769 objetos e 1119 draw calls, GPU 22,3
ms, dia inteiro 36,1 FPS. Neutra.
## Fase 70 — ferrovia e petróleo (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento. A primeira rodada deu um pior
quadro de 2.138 ms (1% low 6,6 FPS): as manchas dos campos de petróleo, que já existem no mundo do benchmark, compilavam
o material na primeira vez que entravam na tela. Com o trilho e um campo de petróleo no rascunho do WarmUp (atrás da
cortina), a segunda rodada: pior quadro 426 ms (no nível das Fases 64 a 69), dia inteiro 35,6 FPS, GPU 22,5 ms, tick
médio 1,37 ms, os mesmos 2755 objetos e 1117 draw calls (as manchas ficam fora do quadro com tudo visível).
## Fase 71 — o trem no trilho (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento. O mundo do benchmark não tem trilho,
então não há trem: tick médio 1,32 ms, os mesmos 2755 objetos e 1117 draw calls, GPU 21,8 ms, dia inteiro 36,9 FPS
(pior quadro 157 ms). Neutra.
## Fase 72 — desfazer o trilho (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento. O histórico de desfazer não roda no
benchmark: tick médio 1,31 ms, 2769 objetos e 1119 draw calls (a variação de sempre do quadro com tudo visível), GPU
21,9 ms, dia inteiro 36,6 FPS (pior quadro 260 ms). Neutra.
## Fase 73 — o cavalo-de-pau (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3), máquina ainda no estado lento. O mundo do benchmark não tem poço
de petróleo: tick médio 1,33 ms, os mesmos 2755 objetos e 1117 draw calls, GPU 23,2 ms, dia inteiro 35,0 FPS (pior
quadro 432 ms, no nível das Fases 64 a 70). Neutra.
## Fase 74 — recintos e vitrines (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark não tem zoológico nem museu. A máquina voltou
ao estado rápido nesta rodada (o ~2,5× mais lento vinha desde a Fase 60): GPU 11,9 ms, dia inteiro 77,6 FPS (1% low
40,2, pior quadro 28 ms), tick médio 1,39 ms, 2769 objetos e 1119 draw calls (a variação de sempre). A diferença é da
máquina, não da fase: nada desta fase entra no mundo do benchmark. Neutra.

## Fase 75 — bichos no cercado (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark não tem zoológico. A máquina voltou ao estado
lento das Fases 60–73: GPU 22,9 ms, dia inteiro 34,8 FPS (1% low 15,3, pior quadro 272 ms), tick médio 1,34 ms,
construir com a ilha cheia 16,8 ms, 2755 objetos e 1117 draw calls (a variação de sempre). A diferença para a Fase 74 é
da máquina: nada desta fase entra no mundo do benchmark (o passeio só existe com bicho posto num zoológico). Neutra.

## Fase 76 — fumaça do trem (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark não tem trilho nem trem. Máquina no estado
lento, igual à Fase 75: GPU 22,5 ms, dia inteiro 35,4 FPS (1% low 15,3, pior quadro 140 ms), tick médio 1,34 ms,
construir com a ilha cheia 16,5 ms, 2755 objetos e 1117 draw calls (iguais aos da Fase 75). Neutra.

## Fase 77 — chão e bebedouro no cercado (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark não tem zoológico. Máquina no estado lento:
GPU 23,4 ms, dia inteiro 34,4 FPS (1% low 18,8, pior quadro 112 ms), tick médio 1,34 ms, construir com a ilha cheia
16,4 ms, 2755 objetos e 1117 draw calls (iguais aos das Fases 75 e 76). Neutra.

## Fase 78 — tanques da usina a petróleo (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark não tem usina a petróleo. Máquina no estado
lento: GPU 24,1 ms, dia inteiro 33,8 FPS (1% low 17,2, pior quadro 131 ms), tick médio 1,32 ms, construir com a ilha
cheia 15,8 ms, 2755 objetos e 1117 draw calls (iguais aos das Fases 75 a 77). Neutra.

## Fase 79 — o bicho vai beber (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark não tem zoológico. Máquina no estado lento:
GPU 22,8 ms, dia inteiro 34,9 FPS (1% low 16,3, pior quadro 115 ms), tick médio 1,34 ms, construir com a ilha cheia
16,0 ms, 2769 objetos e 1119 draw calls (a variação de sempre: 2755–2769). Neutra.

## Fase 80 — turistas na rua (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). O mundo do benchmark tem os eventos ligados, mas nenhum prédio com
beleza (atratividade zero): nenhum turista; 2000 pedestres na multidão e 1902 na rua (1901 antes), multidão na CPU
0,28 ms por quadro. Máquina no estado lento: GPU 23,0 ms, dia inteiro 34,6 FPS, tick médio 1,34 ms, construir com a ilha
cheia 15,8 ms, 2769 objetos e 1119 draw calls. Neutra; o custo dos turistas (até 30 por ilha) fica sem medida aqui.

## Fase 81 — festa cheia (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem atratividade nem festa no mundo do benchmark: 2000 pedestres,
1901 na rua, nenhum turista. Máquina no estado lento: GPU 23,8 ms, dia inteiro 34,4 FPS (1% low 11,6, pior quadro
345 ms, uma travada isolada), tick médio 1,32 ms, construir com a ilha cheia 16,2 ms, 2755 objetos e 1117 draw calls.
Neutra.

## Fase 82 — ver os fogos (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem atratividade nem festa no mundo do benchmark: 2000 pedestres,
1900 na rua, nenhum turista. Máquina no estado lento: GPU 22,9 ms, dia inteiro 34,8 FPS (1% low 18,2, pior quadro
142 ms), tick médio 1,33 ms, construir com a ilha cheia 17,1 ms, 2755 objetos e 1117 draw calls. Neutra.

## Fase 83 — moradores na festa (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark: 2000 pedestres, 1900 na rua.
Máquina no estado rápido (não comparável às duas entradas de antes, no lento): GPU 10,8 ms, dia inteiro 86,3 FPS (1% low
42,9, pior quadro 27 ms), tick médio 1,39 ms, construir com a ilha cheia 16,7 ms, 2769 objetos e 1119 draw calls (14 objetos e 2
draw calls a mais que na Fase 82, sem festa no mundo; a causa não foi investigada). Neutra.

## Fase 84 — palmas e cota da festa (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark (ninguém usa a animação nova; o VAT
dos pedestres ganhou 60 linhas e o shader, a tabela de 8 animações): 2000 pedestres, 1900 na rua. Máquina no estado
rápido, como na Fase 83: GPU 11,0 ms (10,8), dia inteiro 84,3 FPS (86,3; 1% low 41,1, pior quadro 37 ms), tick médio
1,42 ms (1,39), construir com a ilha cheia 17,9 ms (16,7), 2769 objetos e 1119 draw calls (iguais). Dentro da variação
entre rodadas; neutra.

## Fase 85 — palmas nos estouros (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark (nenhum estouro, nenhuma palma); o
som da festa é gerado uma vez ao montar a partida (~21 ms, medido num teste). Máquina no estado rápido: GPU 10,8 ms,
dia inteiro 86,6 FPS (1% low 45,2, pior quadro 27 ms), tick médio 1,32 ms, construir com a ilha cheia 16,6 ms, jogo novo
10,4 s (10,4 na Fase 84), carregar 3,75 s (3,82), 2769 objetos e 1119 draw calls (iguais). Neutra.

## Fase 86 — foguete e assobio (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark (nenhum foguete no ar; os 8
foguetes da `FestivalView` ficam escondidos). Máquina no estado rápido: GPU 10,9 ms, dia inteiro 86,7 FPS (1% low 45,0,
pior quadro 28 ms), tick médio 1,33 ms, construir com a ilha cheia 16,3 ms, jogo novo 10,5 s, carregar 3,72 s, 2769
objetos e 1119 draw calls (iguais à Fase 85). Neutra.

## Fase 87 — formas e vivas (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark (nenhum estouro; a gravação das
vivas é carregada ao montar a partida e não toca). Máquina no estado rápido: GPU 11,0 ms, dia inteiro 85,9 FPS (1% low
45,7, pior quadro 27 ms), tick médio 1,34 ms, construir com a ilha cheia 16,1 ms, jogo novo 10,4 s, carregar 3,80 s,
2769 objetos e 1119 draw calls (iguais). Neutra.

## Fase 88 — duas etapas e vivas calmas (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark (os 6 sub-emissores das bombas
ficam parados; a segunda gravação é carregada ao montar a partida e não toca). Máquina no estado rápido: GPU 10,9 ms,
dia inteiro 86,3 FPS (1% low 44,2, pior quadro 33 ms), tick médio 1,34 ms, construir com a ilha cheia 16,1 ms, jogo
novo 10,3 s, carregar 3,79 s, 2769 objetos e 1119 draw calls (iguais). Neutra.

## Fase 89 — grand finale (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). Sem festa no mundo do benchmark (as 14 bombas e os 12 foguetes, eram
6 e 8, ficam parados). Máquina no estado rápido: GPU 10,8 ms, dia inteiro 86,4 FPS (1% low 43,3, pior quadro 32 ms),
tick médio 1,35 ms, construir com a ilha cheia 16,4 ms, jogo novo 10,4 s, carregar 3,78 s, 2769 objetos e 1119 draw
calls (iguais). Neutra.

## Fase 91 — travadas do ultra (28/10/2026)

Área de trabalho escondida, **ultra**, semente 1840 (v3), três rodadas seguidas: 61,8 / 63,9 / 64,1 FPS de média, 1%
low 33,9 / 39,8 / 41,6, pior quadro 85 / 32 / 28 ms (p99 24,3 e 22,6 ms nas rodadas 1 e 3), GPU ~15 ms. Nenhuma das
travadas de ~2 s da Fase 32. O JSON dos quadros passou ao formato 2 (hora e pipelines compiladas por quadro): 189
compilações no dia, quase todas no anoitecer (18h18 e 18h48) e às 2h42, nenhuma num quadro acima de 25 ms.

## Fase 92 — medidas que faltam (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v3). **VSync desligado** (`-- --sem-vsync`), 1080p: 86,4 FPS (1% low
44,0, 0,1% low 36,0, pior quadro 35 ms), GPU 10,8 ms. **3D nos pixels do 4K** (`-- --4k`, 200% de uma janela de 1080p;
a janela de 3840×2160 o Windows encolhe para a altura da tela): 46,5 FPS (1% low 35,9, pior quadro 33 ms), GPU 21,1 ms.
**Executável exportado** (release, `Society.exe -- --benchmark`): 89,1 FPS (1% low 54,6, 0,1% low 48,2, pior quadro
21 ms), jogo novo 8,7 s, carregar 3,1 s; pipelines iguais às do editor (5 / 11 montando a cidade, 10 / 11 / 0 / 63 no
dia): o shader baker não mudou nada. A linha "frota" passa a dizer "10 navios em 5 rotas; 2 ilhas sem lugar de
entreposto" (antes, 7 rotas, duas delas para ilhas sem porto).

## Fase 93 — porto em toda ilha (28/10/2026)

Área de trabalho escondida, alto, semente 1840, agora no **terreno v4** (o padrão do jogo novo). A frota volta a "10
navios em 7 rotas", sem ilha de fora (na Fase 92, 5 rotas e 2 ilhas sem lugar de entreposto). Gerar o arquipélago: em
série 3.019 ms (2.784 no v3), em threads 1.230 ms (1.202), pior quadro 21 ms. Jogo novo 10,6 s, carregar 4,0 s, 28.830
árvores (7 a menos: os portos aplainados), 2737 objetos e 1087 draw calls. Dia inteiro 87,4 FPS (1% low 43,7, pior quadro
29 ms), tick médio 1,33 ms, construir com a ilha cheia 16,3 ms. Neutra.

## Fase 94 — som e câmera do grand finale (28/10/2026)

Área de trabalho escondida, alto, semente 1840 (v4). Sem festa no mundo do benchmark (o rufar é gerado ao montar a
partida e não toca). Dia inteiro 88,1 FPS (1% low 45,4, pior quadro 32 ms), tick médio 1,31 ms, construir com a ilha
cheia 16,1 ms, jogo novo 10,7 s, carregar 4,0 s, 2737 objetos e 1087 draw calls (iguais à Fase 93). Neutra.

## Fase 95 — telhado de telhas (29/10/2026)

Área de trabalho escondida, alto, semente 1840 (v4), **com o Anno 1800 aberto ao lado** (aberto nesta sessão para olhar as
casas; 12,8 GB de RAM e a GPU dividida), então os números absolutos não valem: o tick subiu para 1,7 ms e o jogo novo para
13,7 s sem nada a ver com o telhado. A/B nas mesmas condições, minutos de distância: **sem a Fase 95** 37,2 FPS (GPU 23,9
ms, 1% low 22,7), **com a Fase 95** 38,0 FPS (GPU 23,6 ms, 1% low 22,7) — igual dentro do ruído. Primitivas no quadro
com tudo visível 15.574.385 → 15.615.617 (+0,26%, as hastes redondas); draw calls iguais (1087 e 1085, pela hora do
quadro). Neutra; repetir sem o Anno aberto.

## Fase 96 — casa em mais de um volume (29/10/2026)

Área de trabalho escondida, alto, semente 1840 (v4), sem o Anno aberto, mas com a máquina no **estado lento** (GPU ~23 ms,
jogo novo ~25,5 s nas duas rodadas). A/B nas mesmas condições: **sem a Fase 96** 34,9 FPS (GPU 23,3 ms, 1% low 20,1,
pior quadro 116 ms), carregar 7,6 s, 1085 draw calls, 15.615.617 primitivas; **com a Fase 96** 34,8 FPS (GPU 23,5 ms,
1% low 22,4, pior quadro 53 ms), carregar 10,3 s, 1137 draw calls (+5%), 15.380.371 primitivas (−1,5%: a ala tira
paredes). O quadro fica igual; o carregar sobe com as formas de casa em dobro (com e sem ala) montadas na primeira vez.
Tick 1,33 ms nas duas.

## Fase 97 — cúpulas e torreões (29/10/2026)

Área de trabalho escondida, alto, semente 1840 (v4), ainda no **estado lento** (GPU ~23,6 ms, jogo novo 26,1 s). Comparado
com a rodada da Fase 96 nas mesmas condições: 34,5 FPS (antes 34,8; 1% low 19,6, pior quadro 142 ms), GPU 23,6 ms (23,5),
carregar 10,6 s (10,3), 1137 draw calls e 15.380.371 primitivas, iguais: a cidade do benchmark não tem teatro,
universidade nem casa de investidor alta, então a cúpula e o torreão não aparecem nela. Neutra.

## Fase 98 — abóbadas e tonéis (29/10/2026)

Mesmas condições da Fase 97 (área de trabalho escondida, alto, semente 1840, **estado lento**, jogo novo 26,6 s): 34,3 FPS
(antes 34,5; 1% low 17,5, pior quadro 131 ms), GPU 23,7 ms (23,6), carregar 10,5 s (10,6), primitivas 15.408.463
(+0,2%: abóbadas, tonéis e chaminés redondas). As draw calls do quadro com tudo visível caíram de 1137 para 975 (a chaminé
redonda é uma malha só para todas, como a caixa; a diferença acompanha a hora do quadro, como nas Fases 95 e 96). Neutra.

## Fase 99 — arcos (29/10/2026)

Mesmas condições (área de trabalho escondida, alto, semente 1840, **estado lento**, jogo novo 26,7 s): 34,6 FPS (antes
34,3), GPU 23,4 ms (23,7), p95 37,7 ms (igual), carregar 10,5 s, 975 draw calls e 15.401.099 primitivas (iguais: a cidade
do benchmark não tem serviço de pedra, casa de investidor nem mercado com a arcada à vista). Um pior quadro isolado de
321 ms nesta rodada (0,1% low 5,2 FPS; na Fase 98, 131 ms), sem nada novo no caminho dele; repetir quando a máquina sair do
estado lento.

## Fase 100 — fumaça das casas (29/10/2026)

Mesmas condições (área de trabalho escondida, alto, semente 1840, **estado lento**, jogo novo 26,8 s): 36,3 FPS (antes
34,6), GPU 22,4 ms (23,4), p95 36,3 ms (37,7), pior quadro 105 ms, carregar 10,4 s. O MultiMesh das baforadas soma um objeto
e uma draw call (2724 · 976) e 4.690 primitivas no quadro com tudo visível. A melhora está dentro do ruído do estado lento:
as baforadas não pesam.

## Fase 101 — toldos listrados (29/10/2026)

Mesmas condições (área de trabalho escondida, alto, semente 1840, **estado lento**, jogo novo 26,0 s): 36,0 FPS (antes
36,3), GPU 22,5 ms (22,4), p95 36,4 ms, pior quadro 122 ms, carregar 10,3 s; objetos, draw calls e primitivas do quadro
com tudo visível iguais (a cidade do benchmark não tem padaria, açougue, taverna nem casa de artesão à vista). Neutra.

## Fase 102 — enxaimel saliente (29/10/2026)

Área de trabalho escondida, alto, semente 1840. A máquina **saiu do estado lento no meio da rodada** (p50 15,2 ms contra
~27 nas anteriores; GPU média 16,3 ms), então o FPS médio (52,0) e o pior quadro (208 ms) não se comparam com as Fases 95
a 101. O que se compara: objetos e draw calls do quadro com tudo visível iguais (2724 · 976); primitivas 15.405.789 →
15.520.521 (+0,7%: o enxaimel e o balanço nas casas dos operários da cidade do benchmark); carregar 10,3 → 11,1 s (as
formas de casa com e sem o avanço). Repetir num estado estável.

## Fase 103 — claraboias (29/10/2026)

Área de trabalho escondida, alto, semente 1840, com a máquina de volta ao **estado rápido** (jogo novo 11,2 s): 86,5 FPS,
1% low 45,1, 0,1% low 40,4, pior quadro 26 ms, p50/p95/p99 11,1/14,9/20,9 ms, GPU 10,8 ms, carregar 4,6 s. É o mesmo
patamar da Fase 92 no estado rápido (alto com VSync desligado, 86 FPS): as formas das Fases 95 a 103 juntas não pesaram.
Objetos e draw calls do quadro com tudo visível 2738 · 978 (as claraboias das fábricas da cidade do benchmark), primitivas
15.520.925 (+404).

## Fase 104 — lampião, grade e chaminé de tijolo (29/10/2026)

Mesmas condições da Fase 103 (área de trabalho escondida, alto, semente 1840, **estado rápido**, jogo novo 11,3 s): 87,3 FPS
(antes 86,5), 1% low 46,2, pior quadro 26 ms, p50/p95/p99 10,9/14,6/20,3 ms, GPU 10,8 ms (igual), carregar 4,6 s.
Objetos e draw calls iguais (2738 · 978); primitivas 15.520.925 → 15.582.625 (+0,4%: as chaminés de tijolo com os potes e
os lampiões). Neutra; fecha o roteiro da rua habitada no mesmo patamar da Fase 92.

## Fase 105 — árvores de quintal (29/10/2026)

Área de trabalho escondida, alto, semente 1840, de volta ao **estado lento** (jogo novo 28,2 s; p50 26,8 ms): 36,8 FPS, GPU
21,8 ms, pior quadro 317 ms (um só; 0,1% low 5,6), carregar 10,9 s; não se compara com as Fases 103 e 104, medidas no estado
rápido, mas está no patamar das rodadas lentas das Fases 99 a 101 (34,3 a 36,3 FPS). Objetos, draw calls e primitivas do
quadro com tudo visível iguais aos da Fase 104 (2724 · 976 · ~15,58 milhões): a cidade do benchmark não tem quintal com
recheio à vista. Neutra; repetir no estado rápido.

## Fase 106 — cais de pedra (29/10/2026)

Área de trabalho escondida, alto, semente 1840, **estado lento** (jogo novo 28,1 s): 36,2 FPS (antes 36,8), GPU 21,8 ms
(igual), p50/p95/p99 26,8/36,0/37,9 ms (iguais), carregar 10,9 s. O cais soma 10 objetos e 10 draw calls no quadro com
tudo visível (2734 · 986: as plataformas e os capeamentos dos entrepostos da cidade do benchmark) e 29.640 primitivas.
O 1% low caiu (11,1 contra 19,5) por três quadros soltos de 313 a 508 ms. O arquivo de quadros mostra, nos três e no de
317 ms da Fase 105, nenhuma pipeline compilada, GPU de 15 a 29 ms, CPU do render de 1 a 2 ms e tick de 0 a 3 ms: a parada
é fora do trabalho que o jogo mede (o sistema ou o driver no estado lento), não o cais. Repetir no estado rápido.

## Fase 107 — barcos de pesca (30/10/2026)

Área de trabalho escondida, alto, semente 1840, **estado lento** (jogo novo 28,1 s): 36,9 FPS (antes 36,2), 1% low 25,9,
0,1% low 24,6, pior quadro 41 ms (desta vez sem as paradas soltas da Fase 106, o que reforça que elas eram de fora do
jogo), GPU 21,9 ms, carregar 10,7 s. Os barcos das cabanas de pesca da cidade do benchmark somam 14 objetos e 2 draw calls
(2748 · 988). Neutra.

## Fase 108 — farol (30/10/2026)

Área de trabalho escondida, alto, semente 1840, **estado lento** (jogo novo 28,3 s): 36,5 FPS (antes 36,9), GPU 21,9 ms,
p50/p95/p99 26,8/35,8/37,8 ms (iguais), carregar 11,3 s. Três quadros soltos (160, 342 e 179 ms) baixam o 1% low para
15,3: nenhum com pipeline compilada, CPU do render ~1 ms e tick zero; um deles com a GPU em 154 ms ao meio-dia, quando o
facho nem aparece. O mesmo padrão das Fases 105 e 106 no estado lento, fora do trabalho do jogo. Neutra.

## Fase 109 — largo calçado (30/10/2026)

Área de trabalho escondida, alto, semente 1840, **estado lento** (jogo novo 28,2 s): 36,6 FPS (antes 36,5), GPU 22,0 ms,
p50/p95/p99 26,9/35,9/38,3 ms, pior quadro 171 ms, carregar 11,3 s. Objetos e draw calls 2739 · 991 (o MultiMesh das lajes);
primitivas iguais (a cidade do benchmark não tem serviço de pedra com largo à vista). Neutra; fecha o roteiro cidade e
porto no patamar das rodadas lentas desde a Fase 99.

## Fase 110 — brilho do sol no mar (30/10/2026)

Área de trabalho escondida, alto, semente 1840, de volta ao **estado rápido** (jogo novo 11,3 s): 86,5 FPS, 1% low 44,3,
0,1% low 39,2, pior quadro 27 ms, p50/p95/p99 11,0/14,8/21,3 ms, GPU 10,8 ms, carregar 5,2 s. É o patamar da Fase 104 no
estado rápido (87,3 FPS, GPU 10,8 ms): a cintilação e as Fases 105 a 109 juntas não pesaram. Neutra.

## Fase 111 — terreiro tropical (30/10/2026)

Estado rápido (jogo novo 11,3 s): 86,6 FPS (antes 86,5), 1% low 44,6, pior quadro 32 ms, GPU 10,8 ms, carregar 5,2 s;
objetos, draw calls e primitivas iguais (o terreiro é só a máscara, sem malha). Neutra.

## Fase 112 — coqueiros na rua tropical (30/10/2026)

Estado rápido (jogo novo 11,3 s): 86,7 FPS (antes 86,6), 1% low 45,0, pior quadro 27 ms, GPU 10,8 ms, carregar 5,1 s;
objetos, draw calls e primitivas iguais (a cidade do benchmark é temperada). Neutra.

## Fase 113 — alameda (30/10/2026)

Estado rápido (jogo novo 11,3 s): 87,7 FPS (antes 86,7), 1% low 44,2, pior quadro 26 ms, GPU 10,7 ms, carregar 5,1 s. Com
a cidade inteira calçada, o quadro com tudo visível passa de 58.811.300 para 59.107.420 primitivas (+0,5%: as árvores da
alameda) e 14,3 ms, igual; calçar a cidade inteira de uma vez 441 ms e mais uma rua 40 ms, iguais (a busca da alameda
anda só nas células calçadas). Neutra.

## Fase 114 — gradil das casas ricas (30/10/2026)

Estado rápido (jogo novo 11,2 s): 87,9 FPS (antes 87,7), 1% low 44,0, pior quadro 27 ms, GPU 10,7 ms, carregar 5,2 s;
objetos e draw calls iguais; com a cidade calçada, 59.125.852 primitivas (+18 mil: os gradis das casas dos engenheiros).
Neutra; fecha o roteiro sol, trópico e avenida no patamar de antes das Fases 95 a 114 (Fase 92: 86 FPS).

## Fase 115 — carreira do estaleiro (30/10/2026)

Área de trabalho escondida, alto, semente 1840 (jogo novo 11,5 s): 80,8 FPS (antes 87,9), 1% low 42,8, pior quadro 29 ms,
p50/p95/p99 11,8/16,0/22,0 ms, GPU 11,5 ms, carregar 5,2 s; objetos, draw calls e primitivas iguais (a cidade do benchmark
não tem estaleiro, então nada da fase é desenhado). A queda é da máquina, não da fase: ver a repetição na Fase 116.

## Fase 116 — mesas da taverna (30/10/2026)

Mesmo estado da Fase 115 (jogo novo 11,5 s): 79,8 FPS (115: 80,8), 1% low 40,0, pior quadro 32 ms, p50/p95/p99
11,9/16,1/23,2 ms, GPU 11,6 ms (115: 11,5), carregar 5,2 s. O quadro com tudo visível ganha 15 objetos e 15 draw calls (as
camadas das mesas e dos guarda-sóis) e as mesmas primitivas; com a cidade calçada, +720 primitivas (as mesas à vista).
Neutra. A queda desde a Fase 114 é da máquina: na Fase 115 o quadro desenhou exatamente o mesmo (objetos, draw calls e
primitivas iguais) e caiu igual.

## Fase 117 — silos das fazendas (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 80,8 FPS (116: 79,8), 1% low 41,8, pior quadro 33 ms, p50/p95/p99 11,8/16,1/22,2 ms, GPU
11,5 ms, carregar 5,2 s; +10 objetos e draw calls (as duas camadas dos silos), primitivas iguais. Neutra. As primitivas do
quadro com a cidade calçada variam algumas dezenas de milhares de uma rodada para outra (59.107.420 aqui, 59.126.572 na
116) por causa da ocultação: não servem para medir uma peça pequena.

## Fase 118 — chão gasto no pasto (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 81,1 FPS (117: 80,8), 1% low 41,5, pior quadro 29 ms, p50/p95/p99 11,8/16,0/22,5 ms, GPU
11,4 ms, carregar 5,2 s; +5 objetos e draw calls (a camada dos cochos), primitivas iguais; calçar a cidade inteira 446 ms e
mais uma rua 40 ms, iguais (as manchas entram na máscara só na área do pasto que mudou). Neutra.

## Fase 119 — poças de luz à noite (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 80,3 FPS (118: 81,1), 1% low 42,1, pior quadro 30 ms, p50/p95/p99 11,8/16,0/22,5 ms, GPU
11,5 ms, carregar 5,2 s. O quadro com tudo visível é de dia, quando a camada das poças fica escondida: objetos, draw calls e
primitivas iguais aos da 118; o dia inteiro passa pela noite com as poças acesas e a média não mudou. Neutra; fecha o
roteiro fazenda, taverna e estaleiro no patamar em que a máquina está desde a Fase 115 (~80 FPS, GPU ~11,5 ms).

## Fase 120 — postes e fios (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,8 FPS (119: 80,3), 1% low 40,5, pior quadro 29 ms, p50/p95/p99 12,2/16,6/22,8 ms, GPU
11,8 ms (119: 11,5), carregar 5,2 s. A cidade do benchmark não tem usina: nenhum poste é desenhado (+5 objetos e draw calls
da camada vazia, primitivas iguais às da 119). A diferença é da máquina, dentro do que ela varia entre rodadas.

## Fase 121 — gavião sobre a cidade (30/10/2026)

Mesmo estado (jogo novo 11,7 s): 77,6 FPS (120: 77,8), 1% low 41,9, pior quadro 28 ms, p50/p95/p99 12,2/16,6/22,5 ms, GPU
11,8 ms, carregar 5,3 s; +5 objetos e draw calls e +315 primitivas (o gavião sobre a cidade do benchmark). Neutra.

## Fase 122 — pedras no rio (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,2 FPS (121: 77,6), 1% low 40,4, pior quadro 35 ms, p50/p95/p99 12,2/16,7/22,6 ms, GPU
11,9 ms, carregar 5,3 s; +20 objetos e draw calls (as quatro camadas das pedras) e +78 mil primitivas (as pedras à vista no
quadro com tudo visível). Neutra.

## Fase 123 — borrifo nas falésias (30/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,2 FPS (122: 77,2), 1% low 40,0, pior quadro 31 ms, p50/p95/p99 12,3/16,6/23,2 ms, GPU
11,9 ms, carregar 5,2 s; objetos, draw calls e primitivas iguais aos da 122 (o trajeto do benchmark não passa perto das
falésias, e os jatos parados não desenham). Neutra.

## Fase 124 — mansarda dos investidores (30/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,7 FPS (123: 77,2), 1% low 40,9, pior quadro 29 ms, p50/p95/p99 12,2/16,6/22,8 ms, GPU
11,8 ms, carregar 5,3 s; objetos, draw calls e primitivas iguais (a cidade do benchmark não tem investidores). Neutra;
fecha o roteiro fios, riacho e mansarda no patamar em que a máquina está desde a Fase 120 (~77,5 FPS, GPU ~11,8 ms).

## Fase 125 — recife de coral (30/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,9 FPS (124: 77,7), 1% low 40,6, pior quadro 32 ms, p50/p95/p99 12,2/16,5/22,6 ms, GPU
11,8 ms, carregar 5,3 s; objetos, draw calls e primitivas iguais (o recife é só o shader da água, que já era desenhado).
Neutra.

## Fase 126 — alpendre tropical (30/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,0 FPS (125: 77,9), 1% low 39,4, pior quadro 36 ms, p50/p95/p99 12,3/16,7/23,2 ms, GPU
11,8 ms, carregar 5,3 s; objetos, draw calls e primitivas iguais (a cidade do benchmark é temperada). Neutra.

## Fase 127 — cisternas no cais (30/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,9 FPS (126: 77,0), 1% low 41,4, pior quadro 29 ms, p50/p95/p99 12,2/16,6/22,4 ms, GPU
11,8 ms, carregar 5,3 s; +5 objetos e draw calls e +23 mil primitivas (as cisternas dos entrepostos da cidade do
benchmark). Neutra.

## Fase 128 — jazidas à vista (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 76,9 FPS (127: 77,9), 1% low 39,6, pior quadro 36 ms, p50/p95/p99 12,3/16,6/23,4 ms, GPU
11,9 ms, carregar 5,3 s; +25 objetos e draw calls (as cinco camadas: quatro de afloramento e a do minério) e +441 mil
primitivas (+2,8%: os afloramentos de todas as jazidas livres do arquipélago, que o quadro com tudo visível pega de
longe). Dentro da variação da máquina; se pesar, os afloramentos podem ganhar alcance de visibilidade por ilha.

## Fase 129 — sombra das nuvens (30/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,5 FPS (128: 76,9), 1% low 40,2, pior quadro 45 ms (um quadro solto; o p99 ficou em
22,8 ms), p50/p95/p99 12,2/16,9/22,8 ms, GPU 11,8 ms, carregar 5,3 s; objetos, draw calls e primitivas iguais (a sombra é
uma conta a mais nos shaders do terreno e da água). Neutra; fecha o roteiro recife, alpendre e nuvens no patamar em que a
máquina está desde a Fase 120 (~77,5 FPS, GPU ~11,8 ms).

## Fase 130 — telhado de sapê (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,0 FPS (129: 77,5), 1% low 40,7, pior quadro 29 ms, p50/p95/p99 12,3/16,7/23,1 ms, GPU
11,9 ms, carregar 5,4 s; objetos, draw calls e primitivas iguais (o sapê é a mesma malha com outra conta no shader do kit).
Neutra.

## Fase 131 — bueiros na rua calçada (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,4 FPS (130: 77,0), 1% low 42,1, pior quadro 28 ms, p50/p95/p99 12,3/16,7/22,2 ms, GPU
11,9 ms, carregar 5,3 s; +1 objeto e draw call (a camada das tampas) e, com a cidade calçada, +200 mil primitivas (as
tampas das ruas da cidade do benchmark). Neutra.

## Fase 132 — bomba d'água (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,0 FPS (131: 77,4), 1% low 41,6, pior quadro 28 ms, p50/p95/p99 12,3/16,8/22,4 ms, GPU
12,0 ms, carregar 5,3 s; +5 objetos e draw calls (a camada das bombas), primitivas iguais no quadro com tudo visível.
Neutra.

## Fase 133 — bandeirolas da feira (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,0 FPS (132: 77,0), 1% low 41,3, pior quadro 32 ms, p50/p95/p99 12,3/16,8/22,6 ms, GPU
12,0 ms, carregar 5,3 s; objetos, draw calls e primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem
mercado; a camada vazia não desenha). Neutra.

## Fase 134 — ardósia nos prédios de pedra (31/10/2026)

Mesmo estado (jogo novo 12,9 s, uma rodada mais lenta só ali; carregar 5,3 s, igual): 76,7 FPS (133: 77,0), 1% low 41,9,
pior quadro 32 ms, p50/p95/p99 12,4/16,8/22,4 ms, GPU 12,0 ms; objetos, draw calls e primitivas iguais (a ardósia é a mesma
malha com outra conta no shader do kit). Neutra; fecha o roteiro sapê, bueiro e ardósia e os quatro ciclos pedidos pelo
dono (Fases 115 a 134) no patamar em que a máquina está desde a Fase 120 (~77 FPS, GPU ~12 ms).

## Fase 135 — galinhas no quintal (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 76,3 FPS (134: 76,7), 1% low 39,4, pior quadro 31 ms, p50/p95/p99 12,3/17,1/23,6 ms, GPU
11,9 ms, carregar 5,3 s; +1 objeto e draw call e +29.760 primitivas no quadro com tudo visível (o MultiMesh das galinhas dos
quintais dos camponeses da cidade do benchmark). Neutra.

## Fase 136 — vagoneta e rejeito (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 76,0 FPS (135: 76,3), 1% low 39,3, pior quadro 34 ms, p50/p95/p99 12,4/17,0/23,5 ms, GPU
12,0 ms, carregar 5,4 s; primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem mina; +10 objetos e
draw calls de variação, sem nada novo desenhado). Neutra.

## Fase 137 — boca do forno acesa (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 76,5 FPS (136: 76,0), 1% low 38,9, pior quadro 35 ms, p50/p95/p99 12,4/16,9/23,0 ms, GPU
12,0 ms, carregar 5,3 s; primitivas iguais no quadro com tudo visível (+7 objetos e draw calls, sem boca de forno à vista
na cidade do benchmark). Neutra.

## Fase 138 — telhado de chapa ondulada (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 76,6 FPS (137: 76,5), 1% low 39,8, pior quadro 28 ms, p50/p95/p99 12,3/17,0/23,8 ms, GPU
11,9 ms, carregar 5,4 s; objetos, draw calls e primitivas iguais (a chapa é a mesma malha com outra conta no shader do kit).
Neutra.

## Fase 139 — redes de pesca (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 77,2 FPS (138: 76,6), 1% low 39,9, pior quadro 30 ms, p50/p95/p99 12,3/16,7/23,3 ms, GPU
11,9 ms, carregar 5,3 s; objetos, draw calls e primitivas iguais (a cidade do benchmark não tem cabana de pesca). Neutra;
fecha o roteiro galinha, forno e mina no patamar de ~77 FPS e GPU ~12 ms.

## Fase 140 — clareira do lenhador (31/10/2026)

Primeira rodada com o corte refeito para todos os lenhadores de todas as ilhas a cada prédio construído: montar tudo 12,5 s
(139: 9,7) e construir com a ilha cheia 28,6 ms (139: 17,7), +130 objetos (camadas por lenhador). Corrigida (só um lenhador
que entra ou sai refaz o corte, só na ilha dele, no quadro seguinte; camadas por trecho), mesmo estado (jogo novo 11,5 s):
77,8 FPS (139: 77,2), 1% low 39,0, pior quadro 34 ms, p50/p95/p99 12,2/16,6/23,5 ms, GPU 11,9 ms, montar tudo 10,1 s,
construir com a ilha cheia 18,1 ms, carregar 5,3 s; +17 objetos e draw calls e +52.165 primitivas no quadro com tudo
visível (os tocos e as toras dos lenhadores da cidade do benchmark). Neutra.

## Fase 141 — árvore seca (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,9 FPS (140: 77,8), 1% low 38,8, pior quadro 33 ms, p50/p95/p99 12,2/16,7/23,8 ms, GPU
11,9 ms, carregar 5,3 s, construir com a ilha cheia 17,7 ms; objetos, draw calls e primitivas iguais no quadro com tudo
visível (o recheio só desenha perto da câmera). Neutra.

## Fase 142 — botes no porto (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 76,4 FPS (141: 77,9), 1% low 39,5, pior quadro 32 ms, p50/p95/p99 12,4/16,8/23,7 ms, GPU
12,1 ms, carregar 5,3 s, construir com a ilha cheia 17,5 ms; +15 objetos e draw calls e +12.000 primitivas no quadro com
tudo visível (os botes, os remadores e os remos diante dos entrepostos do benchmark). Neutra (a rodada da 141 foi das mais
rápidas do patamar).

## Fase 143 — cerca de estacas (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 76,7 FPS (142: 76,4), 1% low 39,3, pior quadro 31 ms, p50/p95/p99 12,3/16,8/23,4 ms, GPU
12,1 ms, carregar 5,4 s, construir com a ilha cheia 17,7 ms; objetos e draw calls iguais e +501.816 primitivas no quadro com
tudo visível (as estacas das casas dos operários da cidade do benchmark, dentro da malha de cada casa). Neutra.

## Fase 144 — boias no porto (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 77,3 FPS (143: 76,7), 1% low 39,4, pior quadro 34 ms, p50/p95/p99 12,3/16,8/23,7 ms, GPU
12,0 ms, carregar 5,4 s, construir com a ilha cheia 17,5 ms; +10 objetos e draw calls e +30.720 primitivas no quadro com
tudo visível (as boias diante dos entrepostos do benchmark). Neutra; fecha o roteiro toco, bote e boia no patamar de ~77 FPS
e GPU ~12 ms.

## Fase 145 — relógio da igreja (31/10/2026)

Duas rodadas no mesmo estado (jogo novo 11,5 e 11,6 s): 75,1 e 75,7 FPS (144: 77,3), 1% low 38,8 e 39,4, pior quadro 36 e
31 ms, p50/p95/p99 12,5/17,1/23,8 ms, GPU 12,1–12,2 ms (144: 12,0), carregar 5,4 s, construir com a ilha cheia 17,4–17,7 ms;
+4 objetos e draw calls (os mostradores e ponteiros da igreja da cidade do benchmark) e primitivas iguais no quadro com tudo
visível. Dentro da faixa do patamar desde a Fase 120 (75 a 78 FPS); a refatoração do lugar do modelo
(`BuildingView.model_place`) não muda o desenho.

## Fase 146 — grade e lampiões no cais (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 76,3 FPS (145: 75,1 e 75,7), 1% low 39,5, pior quadro 35 ms, p50/p95/p99 12,4/17,1/23,5 ms,
GPU 12,0 ms, carregar 5,4 s, construir com a ilha cheia 17,6 ms; +15 objetos e draw calls e +91.800 primitivas no quadro com
tudo visível (as grades e os lampiões dos cais de pedra do benchmark). Neutra.

## Fase 147 — mastros no cais (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 75,6 FPS (146: 76,3), 1% low 39,5, pior quadro 29 ms, p50/p95/p99 12,4/17,1/23,7 ms, GPU
12,1 ms, carregar 5,4 s, construir com a ilha cheia 17,8 ms; objetos, draw calls e primitivas iguais no quadro com tudo
visível (os mastros ficam nas pontas do cais, fora do quadro medido). Neutra.

## Fase 148 — cavalete do lenhador (31/10/2026)

Primeira rodada com o corte da clareira refeito a cada estrada e derrubada de árvores: montar tudo 10,6 s (147: 10,2), 75,2
FPS. Com o recálculo adiado para o quadro seguinte (juntando os pedidos), mesmo estado (jogo novo 11,6 s): 76,2 FPS (147:
75,6), 1% low 39,9, pior quadro 32 ms, p50/p95/p99 12,4/17,1/23,2 ms, GPU 12,0 ms, montar tudo 9,6 s, carregar 5,4 s,
construir com a ilha cheia 17,5 ms; +3 objetos e draw calls e +41.493 primitivas no quadro com tudo visível (os terreiros dos
lenhadores da cidade do benchmark). Neutra.

## Fase 149 — cata-vento no pasto (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 75,3 FPS (148: 76,2), 1% low 39,1, pior quadro 33 ms, p50/p95/p99 12,6/17,2/23,6 ms, GPU
12,2 ms, montar tudo 9,5 s, carregar 5,4 s, construir com a ilha cheia 17,3 ms; +10 objetos e draw calls e primitivas iguais
no quadro com tudo visível (as torres e as rodas dos pastos da cidade do benchmark, fora do quadro medido). Neutra, dentro da
faixa do patamar (75 a 78 FPS); fecha o roteiro relógio, cais e cata-vento.

## Fase 150 — coluna de anúncios (31/10/2026)

Primeira rodada com a busca das esquinas andando célula por célula pela ilha inteira em GDScript: carregar 5,6 s (149: 5,4)
e construir com a ilha cheia 18,6 ms (149: 17,3). Com a busca pelo `find` das células calçadas (como a alameda), mesmo
estado (jogo novo 11,6 s): 75,0 FPS (149: 75,3), 1% low 39,6, pior quadro 31 ms, p50/p95/p99 12,6/17,1/23,4 ms, GPU 12,2 ms,
montar tudo 9,8 s, carregar 5,5 s, construir com a ilha cheia 17,7 ms; +5 objetos e draw calls e primitivas iguais no quadro
com tudo visível. Neutra.

## Fase 151 — placas das lojas (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 75,3 FPS (150: 75,0), 1% low 39,6, pior quadro 30 ms, p50/p95/p99 12,5/17,1/23,7 ms, GPU
12,2 ms, montar tudo 9,6 s, carregar 5,4 s, construir com a ilha cheia 17,7 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a placa entra na malha de cada loja, e as lojas do benchmark ficam fora do quadro medido). Neutra.

## Fase 152 — balizas com corrente (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 75,3 FPS (151: 75,3), 1% low 39,2, pior quadro 33 ms, p50/p95/p99 12,5/17,2/23,6 ms, GPU
12,2 ms, montar tudo 9,7 s, carregar 5,4 s, construir com a ilha cheia 17,9 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a cidade do benchmark fica na ilha plana, sem largo). Neutra.

## Fase 153 — flores nas sacadas (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 75,1 FPS (152: 75,3), 1% low 40,0, pior quadro 31 ms, p50/p95/p99 12,6/17,1/23,6 ms, GPU
12,2 ms, montar tudo 9,8 s, carregar 5,4 s, construir com a ilha cheia 18,1 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (as floreiras entram na malha de cada casa, e as casas com sacada ficam fora do quadro medido).
Neutra.

## Fase 154 — velocípede encostado (31/10/2026)

Mesmo estado (jogo novo 11,8 s): 75,3 FPS (153: 75,1), 1% low 38,7, pior quadro 38 ms, p50/p95/p99 12,5/17,1/23,7 ms, GPU
12,2 ms, montar tudo 9,7 s, carregar 5,4 s, construir com a ilha cheia 18,1 ms; +5 objetos e draw calls e primitivas iguais
no quadro com tudo visível. Neutra; fecha o roteiro coluna, placa e velocípede e os quatro ciclos do segundo pedido do dono
(Fases 135 a 154), no patamar de 75 a 78 FPS (GPU ~12 ms) em que a máquina está desde a Fase 120.

## Fase 155 — carneirinhos no mar (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 76,5 FPS (154: 75,3), 1% low 38,3, pior quadro 62 ms, p50/p95/p99 12,3/16,8/23,5 ms, GPU
12,1 ms, montar tudo 9,8 s, carregar 5,4 s, construir com a ilha cheia 18,0 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (os carneirinhos são só a conta a mais no shader da água). Neutra; abre o roteiro carneirinho,
papoula e colheita.

## Fase 156 — papoulas no prado (31/10/2026)

Primeira rodada (com o ruído dos canteiros calculado inteiro em cada célula): 82,1 FPS, GPU 11,1 ms, carregar 5,6 s (155:
5,4). O recheio do arquipélago inteiro passava ~80 ms no sorteio dos canteiros (1,5 µs por célula); guardando os quatro nós da
última célula (as vizinhas da mesma fileira repetem) e recusando sem a conta quando nenhum nó passa do limite, 0,8 µs. Com isso,
jogo novo 11,5 s: 84,3 FPS (a máquina no estado rápido), 1% low 41,4, pior quadro 32 ms, p50/p95/p99 11,3/15,3/22,8 ms, GPU
11,0 ms, montar tudo 9,2 s, carregar 5,4 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a cidade do benchmark fica na ilha plana, sem recheio). Neutra.

## Fase 157 — caixas da colheita (31/10/2026)

Mesmo estado (jogo novo 11,5 s): 84,6 FPS (156: 84,3), 1% low 40,3, pior quadro 37 ms, p50/p95/p99 11,1/15,2/22,8 ms, GPU
10,9 ms, montar tudo 9,5 s, carregar 5,5 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível. Neutra (dez peças por campo, escondidas até o fim do ciclo, em dois MultiMesh).

## Fase 158 — carroça de lona (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 84,6 FPS (157: 84,6), 1% low 41,3, pior quadro 29 ms, p50/p95/p99 11,1/15,3/22,6 ms, GPU
10,9 ms, montar tudo 9,3 s, carregar 5,4 s, construir com a ilha cheia 16,9 ms, multidão na CPU 0,29 ms; +5 objetos e draw
calls (a camada das lonas) e primitivas iguais no quadro com tudo visível. Neutra.

## Fase 159 — tijolos secando (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 83,1 FPS (158: 84,6), 1% low 38,6, pior quadro 31 ms, p50/p95/p99 11,2/15,9/24,0 ms, GPU
10,9 ms, montar tudo 9,7 s, carregar 5,5 s, construir com a ilha cheia 18,2 ms (na faixa de 17 a 18 ms das fases de antes);
objetos, draw calls e primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem olaria). Neutra; fecha o
roteiro carneirinho, papoula e colheita.

## Fase 160 — cunhais de pedra (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 83,4 FPS (159: 83,1), 1% low 39,1, pior quadro 33 ms, p50/p95/p99 11,3/15,7/23,2 ms, GPU
11,0 ms, montar tudo 9,4 s, carregar 5,5 s, construir com a ilha cheia 18,3 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (os blocos entram na malha de cada casa, e as casas com cunhal ficam fora do quadro medido). Neutra;
abre o roteiro cunhal, deriva e horta.

## Fase 161 — madeira à deriva (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 83,0 FPS (160: 83,4), 1% low 41,0, pior quadro 28 ms, p50/p95/p99 11,4/15,3/23,1 ms, GPU
11,1 ms, montar tudo 9,3 s, carregar 5,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a cidade do benchmark fica na ilha plana, sem recheio). Neutra.

## Fase 162 — cascalho nas encostas (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 83,6 FPS (161: 83,0), 1% low 39,1, pior quadro 35 ms, p50/p95/p99 11,3/15,5/23,4 ms, GPU
11,0 ms, montar tudo 9,7 s, carregar 5,5 s, construir com a ilha cheia 16,9 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível. Neutra.

## Fase 163 — horta no quintal (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 82,6 FPS (162: 83,6), 1% low 39,5, pior quadro 31 ms, p50/p95/p99 11,3/15,3/23,6 ms, GPU
11,0 ms, montar tudo 9,4 s, carregar 5,6 s (162: 5,5; na oscilação de 0,1 s entre rodadas), construir com a ilha cheia 17,2 ms;
+2 objetos e draw calls e +15 mil primitivas no quadro com tudo visível (as hortas da cidade do benchmark, uma malha só).
Neutra.

## Fase 164 — caldeira das árvores (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 83,6 FPS (163: 82,6), 1% low 39,7, pior quadro 29 ms, p50/p95/p99 11,3/15,5/23,5 ms, GPU
11,0 ms, montar tudo 9,5 s, carregar 5,6 s, construir com a ilha cheia 17,1 ms; +1 objeto e draw call (a camada das caldeiras)
e primitivas iguais no quadro com tudo visível. Neutra; fecha o roteiro cunhal, deriva e horta.

## Fase 165 — chão batido das fábricas (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 83,5 FPS (164: 83,6), 1% low 41,6, pior quadro 28 ms, p50/p95/p99 11,3/15,4/23,0 ms, GPU
11,1 ms, montar tudo 9,3 s, carregar 5,6 s, construir com a ilha cheia 17,7 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (o pátio é só a máscara das estradas, e a cidade do benchmark fica na ilha plana, sem máscara).
Neutra; abre o roteiro chão batido, feno e gaivota.

## Fase 166 — medas de feno (31/10/2026)

Mesmo estado (jogo novo 11,6 s): 81,7 FPS (165: 83,5), 1% low 40,0, pior quadro 28 ms, p50/p95/p99 11,5/15,7/23,3 ms, GPU
11,2 ms, montar tudo 9,4 s, carregar 5,6 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a cidade do benchmark fica na ilha plana, sem medas). Neutra.

## Fase 167 — capim alto nos terrenos vazios (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,8 FPS (166: 81,7), 1% low 39,2, pior quadro 33 ms, p50/p95/p99 11,3/15,7/23,7 ms, GPU
11,1 ms, montar tudo 9,3 s, carregar 5,6 s, construir com a ilha cheia 16,9 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a cidade do benchmark fica na ilha plana, sem recheio). Neutra.

## Fase 168 — gaivotas no cais (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 84,0 FPS (167: 82,8), 1% low 40,6, pior quadro 31 ms, p50/p95/p99 11,3/15,2/23,1 ms, GPU
11,0 ms, montar tudo 9,3 s, carregar 5,6 s, construir com a ilha cheia 17,4 ms; +1 objeto e draw call (a camada das gaivotas
pousadas) e +7 mil primitivas no quadro com tudo visível. Neutra.

## Fase 169 — barril de chuva (31/10/2026)

Primeira rodada, com todos os barris numa malha refeita em GDScript a cada obra: carregar 5,75 s (168: 5,6). Medido à parte,
refazer 300 barris custava ~120 ms; com o barril e o cano em dois MultiMesh (o cano de 1 m esticado até o beiral), 16 ms. Com
isso, jogo novo 11,7 s: 83,0 FPS (168: 84,0), 1% low 40,2, pior quadro 28 ms, p50/p95/p99 11,3/15,3/23,0 ms, GPU 11,1 ms,
montar tudo 9,3 s, carregar 5,7 s, construir com a ilha cheia 17,7 ms; +10 objetos e draw calls (as duas camadas dos barris
nas ilhas) e +10 mil primitivas no quadro com tudo visível. Neutra; fecha o roteiro chão batido, feno e gaivota.

## Fase 170 — barranco de terra vermelha (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,0 FPS (169: 83,0), 1% low 40,0, pior quadro 31 ms, p50/p95/p99 11,4/15,4/23,6 ms, GPU
11,1 ms, montar tudo 9,5 s, carregar 5,7 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (é só um uniforme no material das ilhas tropicais). Neutra; abre o roteiro laterita, lenha e carrinho.

## Fase 171 — lenha na parede (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,4 FPS (170: 82,0), 1% low 39,7, pior quadro 35 ms, p50/p95/p99 11,4/15,3/23,4 ms, GPU
11,1 ms, montar tudo 9,4 s, carregar 5,7 s, construir com a ilha cheia 17,0 ms; +5 objetos e draw calls (a camada das pilhas)
e primitivas iguais no quadro com tudo visível. Neutra.

## Fase 172 — carrinho de mão (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 83,1 FPS (171: 82,4), 1% low 39,3, pior quadro 35 ms, p50/p95/p99 11,3/15,3/23,5 ms, GPU
11,0 ms, montar tudo 9,3 s, carregar 5,8 s (171: 5,7), construir com a ilha cheia 17,1 ms; +5 objetos e draw calls e +31 mil
primitivas no quadro com tudo visível (os carrinhos das oficinas do benchmark). O carregar a mais é a oscilação entre rodadas:
medido à parte, montar os carrinhos de 400 oficinas leva 2 ms e refazer, 0,8 ms. Neutra.

## Fases 173 e 174 — tina de lavar e banco na porta (31/10/2026)

Medidas juntas (as duas são peças pequenas de quintal num MultiMesh cada). Mesmo estado (jogo novo 11,6 s): 83,2 FPS (172:
83,1), 1% low 41,4, pior quadro 27 ms, p50/p95/p99 11,3/15,3/22,9 ms, GPU 11,1 ms, montar tudo 9,3 s, carregar 5,7 s,
construir com a ilha cheia 17,3 ms; +5 objetos e draw calls e +24 mil primitivas no quadro com tudo visível. Neutras; fecham o
roteiro laterita, lenha e carrinho e os quatro ciclos do terceiro pedido do dono (Fases 155 a 174), no patamar de 81 a 85 FPS
(GPU ~11 ms) em que a máquina ficou nesta rodada.

## Fase 175 — espantalho no campo (31/10/2026)

Mesmo estado (jogo novo 11,8 s): 83,3 FPS (174: 83,2), 1% low 40,8, pior quadro 28 ms, p50/p95/p99 11,3/15,4/22,7 ms, GPU
11,1 ms, montar tudo 9,3 s, carregar 5,7 s, construir com a ilha cheia 17,3 ms; +5 objetos e draw calls (a camada dos
espantalhos nas ilhas) e primitivas iguais no quadro com tudo visível (o benchmark não tem campo de trigo nem de batata com
dono à vista). Neutra; abre o roteiro espantalho, cegonha e vaga-lume.

## Fase 176 — cegonha na chaminé (31/10/2026)

Mesmo estado (jogo novo 11,8 s): 83,1 FPS (175: 83,3), 1% low 39,9, pior quadro 32 ms, p50/p95/p99 11,4/15,5/23,3 ms, GPU
11,2 ms, montar tudo 9,3 s, carregar 5,6 s, construir com a ilha cheia 17,0 ms; +10 objetos e draw calls (os ninhos e as
cegonhas nas ilhas) e +263 mil primitivas no quadro com tudo visível. Neutra.

## Fase 177 — postigos nas janelas (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,0 FPS (176: 83,1), 1% low 41,0, pior quadro 36 ms, p50/p95/p99 11,5/15,7/22,7 ms, GPU
11,4 ms (176: 11,2), montar tudo 9,4 s, carregar 5,8 s, construir com a ilha cheia 17,3 ms; objetos e draw calls iguais e +749
mil primitivas no quadro com tudo visível (duas folhas de 12 triângulos por janela em todas as casas dos camponeses,
operários e artesãos). O pouco que a GPU subiu está dentro da oscilação entre rodadas; a malha das casas não muda de número
(os postigos valem para a classe inteira).

## Fase 178 — vaga-lumes no prado (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,0 FPS (177: 82,0), 1% low 40,8, pior quadro 28 ms, p50/p95/p99 11,5/15,6/23,0 ms, GPU
11,3 ms, montar tudo 9,3 s, carregar 5,9 s (177: 5,8; a oscilação de sempre: de dia os vaga-lumes nem são montados),
construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais no quadro com tudo visível (às 10h a camada fica
escondida). O dia inteiro do benchmark passa pela noite com os vaga-lumes acesos sem mudar o FPS médio. Neutra.

## Fase 179 — juncos na margem (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 81,6 FPS (178: 82,0), 1% low 39,8, pior quadro 32 ms, p50/p95/p99 11,6/15,8/23,4 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 5,8 s, construir com a ilha cheia 17,0 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (a câmera dele não passa pelas margens de rio). Neutra; fecha o roteiro espantalho, cegonha e
vaga-lume, no patamar de 81 a 83 FPS (GPU 11,1 a 11,4 ms).

## Fase 180 — borboletas nos canteiros (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,2 FPS (179: 81,6), 1% low 40,9, pior quadro 29 ms, p50/p95/p99 11,5/15,8/23,0 ms, GPU
11,3 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,6 ms; +1 objeto e draw call e +5 mil primitivas no
quadro com tudo visível (as borboletas à vista às 10h). Medido à parte (num teste): os grupos do arquipélago levavam ~48 ms a
cada obra (no quadro seguinte); com o hash aritmético e a refação só da ilha que mudou, a ilha principal leva ~2,4 ms, e os
vaga-lumes da Fase 178 (~10 ms no arquipélago inteiro à noite) ganharam o mesmo. Neutra; abre o roteiro borboleta, correio e
galo.

## Fase 181 — caixa de correio (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,0 FPS (180: 82,2), 1% low 41,3, pior quadro 36 ms, p50/p95/p99 11,5/15,8/22,6 ms, GPU
11,3 ms, montar tudo 9,3 s, carregar 5,8 s; +5 objetos e draw calls (a camada das caixas nas ilhas) e primitivas quase iguais
no quadro com tudo visível. Construir com a ilha cheia deu 20,5 ms (o de sempre fica entre 17 e 18): a medida é o comando e o
que as vistas fazem na hora, e a vista nova só escuta a troca de estradas (o mercado do benchmark não mexe nelas). Conferido
de novo na Fase 182.

## Fase 182 — galo do cata-vento (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 81,6 FPS (181: 82,0), 1% low 40,5, pior quadro 29 ms, p50/p95/p99 11,5/15,7/22,9 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 6,0 s (181: 5,8), construir com a ilha cheia 17,0 ms (os 20,5 ms da 181 eram oscilação);
+10 objetos e draw calls (a haste e o galo nas ilhas) e primitivas iguais no quadro com tudo visível (o benchmark não tem
fazenda à vista). O carregar vem subindo devagar neste ciclo (5,7 s na 177, 6,0 s agora): fica de olho.

## Fase 183 — barco na areia (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 82,1 FPS (182: 81,6), 1% low 40,2, pior quadro 35 ms, p50/p95/p99 11,5/15,6/23,0 ms, GPU
11,3 ms, montar tudo 9,2 s, carregar 5,7 s (182: 6,0: era a oscilação entre rodadas), construir com a ilha cheia 17,0 ms; +10
objetos e draw calls (os barcos e os remos nas ilhas) e primitivas iguais no quadro com tudo visível. Neutra.

## Fase 184 — limo na pedra (31/10/2026)

Mesmo estado (jogo novo 11,7 s): 81,2 FPS (183: 82,1), 1% low 40,6, pior quadro 34 ms, p50/p95/p99 11,6/15,9/22,8 ms, GPU
11,4 ms, montar tudo 9,4 s, carregar 5,8 s, construir com a ilha cheia 17,4 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (só o material das rochas do mar mudou). Neutra; fecha o roteiro borboleta, correio e galo, no
patamar de 81 a 82 FPS (GPU 11,3 a 11,4 ms).

## Fase 185 — hera nas paredes (01/11/2026)

Mesmo estado (jogo novo 11,7 s): 81,4 FPS (184: 81,2), 1% low 41,1, pior quadro 29 ms, p50/p95/p99 11,6/15,9/23,0 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 5,8 s, construir com a ilha cheia 17,0 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (é um parâmetro de instância e um trecho do shader do kit). Neutra; abre o roteiro hera, estaca e
arco-íris.

## Fase 186 — estacas na água (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 81,6 FPS (185: 81,4), 1% low 41,6, pior quadro 31 ms, p50/p95/p99 11,6/15,8/22,6 ms, GPU
11,4 ms, montar tudo 9,2 s, carregar 5,9 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls e +48 mil primitivas
no quadro com tudo visível (os feixes diante dos entrepostos do benchmark). Neutra.

## Fase 187 — placa na encruzilhada (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,9 FPS (186: 81,6), 1% low 40,0, pior quadro 30 ms, p50/p95/p99 11,6/15,9/23,4 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,8 s, construir com a ilha cheia 17,1 ms; +10 objetos e draw calls (os postes e as
tábuas nas ilhas) e +3 mil primitivas no quadro com tudo visível. Neutra no quadro; o FPS médio vem descendo devagar neste
pedido (83 na Fase 175, 81 agora, GPU de 11,1 para 11,5 ms), cada fase somando um pouco de objetos e primitivas.

## Fase 188 — arco-íris (01/11/2026)

Mesmo estado (jogo novo 11,7 s): 81,5 FPS (187: 80,9), 1% low 40,4, pior quadro 29 ms, p50/p95/p99 11,5/15,7/23,4 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais no
quadro com tudo visível (o anel só aparece depois da chuva). Neutra.

## Fase 189 — focas nas pedras (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 81,2 FPS (188: 81,5), 1% low 41,2, pior quadro 29 ms, p50/p95/p99 11,6/15,7/22,8 ms, GPU
11,5 ms, montar tudo 9,2 s, carregar 5,8 s, construir com a ilha cheia 16,9 ms; +10 objetos e draw calls (os corpos e as
cabeças nas ilhas) e +347 mil primitivas no quadro com tudo visível (os grupos da costa da câmera do benchmark). Neutra; fecha
o roteiro hera, estaca e arco-íris.

## Fase 190 — colmeias de palha (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,8 FPS (189: 81,2), 1% low 40,5, pior quadro 30 ms, p50/p95/p99 11,7/15,9/23,1 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,8 s, construir com a ilha cheia 17,0 ms; +6 objetos e draw calls (o banco e as abelhas
nas ilhas) e primitivas iguais no quadro com tudo visível. Neutra; abre o roteiro colmeia, pombal e varal.

## Fase 191 — pombal (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 81,0 FPS (190: 80,8), 1% low 39,9, pior quadro 30 ms, p50/p95/p99 11,6/16,0/23,2 ms, GPU
11,5 ms, montar tudo 9,2 s, carregar 5,8 s, construir com a ilha cheia 17,4 ms; +10 objetos e draw calls (os pombais e os
pombos nas ilhas) e primitivas iguais no quadro com tudo visível. Neutra.

## Fase 192 — roupa sobre a rua (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 81,1 FPS (191: 81,0), 1% low 40,8, pior quadro 29 ms, p50/p95/p99 11,7/15,8/23,1 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,5 ms; +2 objetos e draw calls e +49 mil primitivas
no quadro com tudo visível (os varais das ruas de operários do benchmark). Neutra.

## Fase 193 — carroça de feno parada (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,4 FPS (192: 81,1), 1% low 40,0, pior quadro 29 ms, p50/p95/p99 11,8/16,0/23,5 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,2 ms; +10 objetos e draw calls (as carroças e as
cargas nas ilhas) e primitivas iguais no quadro com tudo visível. Neutra no quadro (GPU igual); o FPS médio segue descendo
devagar com os objetos a mais deste pedido.

## Fase 194 — escada do cais (01/11/2026)

Mesmo estado (jogo novo 11,9 s): 80,4 FPS (193: 80,4), 1% low 40,8, pior quadro 28 ms, p50/p95/p99 11,8/16,0/23,1 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 6,0 s, construir com a ilha cheia 17,0 ms; +10 objetos e draw calls (os degraus e as
argolas nas ilhas) e +26 mil primitivas no quadro com tudo visível. Neutra; fecha o roteiro colmeia, pombal e varal e os
quatro ciclos do quarto pedido do dono (Fases 175 a 194). Ao longo deles o FPS médio desceu de ~83 para ~80,5 e a GPU de 11,1
para 11,5 ms, com +100 objetos e draw calls (5 por vista nova, uma camada por ilha) e +1,5 milhão de primitivas no quadro com
tudo visível; montar, carregar e construir ficaram onde estavam.

## Fase 195 — cemitério da igreja (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 81,5 FPS (194: 80,4), 1% low 41,0, pior quadro 28 ms, p50/p95/p99 11,6/15,9/22,8 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,1 ms; +20 objetos e draw calls (as três pedras e o
muro, quatro camadas) e primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem igreja). Neutra; abre o
roteiro cemitério, pato e rede.

## Fase 196 — patos na água (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,1 FPS (195: 81,5), 1% low 39,9, pior quadro 30 ms, p50/p95/p99 11,8/16,0/23,3 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,0 ms; +2 objetos e draw calls (as duas camadas, sem
sombra) e +35 mil primitivas no quadro com tudo visível. A primeira versão da busca dos bandos levava 226 ms e punha ~0,25 s
no jogo novo e no carregar; com a busca refeita (12 ms) os dois voltaram. Neutra.

## Fase 197 — casinha do cão (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 79,7 FPS (196: 80,1), 1% low 39,0, pior quadro 38 ms, p50/p95/p99 11,8/16,1/23,8 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 6,0 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (as casas do benchmark encostam umas nas outras e não sobra a célula do lado).
Neutra (GPU igual).

## Fase 198 — bancos no cais (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,2 FPS (197: 79,7), 1% low 40,6, pior quadro 33 ms, p50/p95/p99 11,7/16,0/23,1 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,5 ms; +5 objetos e draw calls (a camada) e +6 mil
primitivas no quadro com tudo visível. Neutra.

## Fase 199 — rede na varanda (01/11/2026)

Mesmo estado (jogo novo 11,9 s): 79,8 FPS (198: 80,2), 1% low 40,3, pior quadro 35 ms, p50/p95/p99 11,8/16,6/22,9 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 5,9 s, construir com a ilha cheia 17,5 ms; +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (o benchmark não tem casa com alpendre). Neutra; fecha o roteiro cemitério, pato e
rede.

## Fase 200 — gato na porta (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,5 FPS (199: 79,8), 1% low 40,2, pior quadro 36 ms, p50/p95/p99 11,7/16,0/23,3 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 6,0 s, construir com a ilha cheia 17,1 ms; +2 objetos e draw calls (as duas camadas, sem
sombra) e +71 mil primitivas no quadro com tudo visível (~120 gatos na cidade do benchmark). A primeira versão ficou em 78,7
FPS, 1% low 36,8 e p95 17,5 (sem o gato, na mesma hora: 80,1, 40,6 e 16,3): as cabeças viravam na CPU a cada quadro e a vista
se refazia a cada `building_state_changed`, que dispara a cada troca de estado das fábricas. Com o giro no shader e só o
`house_upgraded`, neutra; a rede da Fase 199 ouvia o mesmo sinal e foi corrigida junto.

## Fase 201 — poço da vila (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,1 FPS (200: 80,5), 1% low 40,2, pior quadro 36 ms, p50/p95/p99 11,8/16,0/22,9 ms, GPU
11,6 ms, montar tudo 9,3 s, carregar 6,1 s, construir com a ilha cheia 17,3 ms; +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (a cidade do benchmark é plana e de operários). Neutra.

## Fase 202 — secadouro de peixe (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 79,7 FPS (201: 80,1), 1% low 40,5, pior quadro 35 ms, p50/p95/p99 11,8/16,1/22,8 ms, GPU
11,6 ms, montar tudo 9,3 s, carregar 6,0 s, construir com a ilha cheia 17,8 ms; +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (o benchmark não tem cabana de pesca). Neutra.

## Fase 203 — carrinho de feira (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,5 FPS (202: 79,7), 1% low 40,3, pior quadro 28 ms, p50/p95/p99 11,7/16,0/23,1 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 6,3 s (na faixa de 5,9 a 6,3 das últimas rodadas), construir com a ilha cheia 17,5 ms;
+5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo visível (a cidade do benchmark é plana). Neutra.

## Fase 204 — guarda-sol de palha (01/11/2026)

Mesmo estado (jogo novo 11,9 s): 80,8 FPS (203: 80,5), 1% low 40,2, pior quadro 32 ms, p50/p95/p99 11,7/16,0/23,1 ms, GPU
11,4 ms, montar tudo 9,3 s, carregar 6,0 s, construir com a ilha cheia 16,8 ms; +5 objetos e draw calls (a camada) e +5 mil
primitivas no quadro com tudo visível. Antes da memória das buscas junto da rua o carregar estava em 6,4 s (as listas das
células tomadas, das bombas e dos carrinhos eram refeitas várias vezes, cada uma pelos ~800 prédios da cidade); com ela voltou
a 6,0. Neutra; fecha o roteiro gato, poço e carrinho.

## Fase 205 — estandartes na fachada (01/11/2026)

Mesmo estado (jogo novo 11,9 s): 80,0 FPS (204: 80,8), 1% low 40,6, pior quadro 29 ms, p50/p95/p99 11,8/16,1/23,0 ms, GPU
11,5 ms, montar tudo 9,4 s, carregar 6,0 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem esses serviços). Neutra; abre o roteiro
estandarte, bebedouro e lanterna.

## Fase 206 — bebedouro de cavalos (01/11/2026)

Mesmo estado (jogo novo 12,0 s): 80,1 FPS (205: 80,0), 1% low 40,5, pior quadro 34 ms, p50/p95/p99 11,8/16,0/23,0 ms, GPU
11,5 ms, montar tudo 9,4 s, carregar 6,1 s, construir com a ilha cheia 17,6 ms; +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem taverna em terra com relevo). Neutra.

## Fase 207 — pinheiro-anão na encosta (01/11/2026)

Mesmo estado (jogo novo 11,8 s): 80,3 FPS (206: 80,1), 1% low 39,7, pior quadro 35 ms, p50/p95/p99 11,8/16,1/23,4 ms, GPU
11,5 ms, montar tudo 9,3 s, carregar 6,1 s, construir com a ilha cheia 17,4 ms; +1 objeto e draw call e +7 mil primitivas no
quadro com tudo visível (os pinheiros nos trechos à vista). Neutra.

## Fase 208 — rama de tecido (01/11/2026)

**A máquina entrou no estado lento** (o dono usando o PC): 71,5 FPS, 1% low 38,0, p50/p95/p99 13,2/17,6/24,7 ms, GPU 12,6 ms,
CPU do render 1,6 ms, tick 0,14 ms (tudo mais lento junto). No mesmo estado, **sem a rama** (A/B): 71,8 FPS, GPU 12,5 ms.
Montar tudo 9,4 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e primitivas iguais
no quadro com tudo visível (a cidade do benchmark não tem tecelagem). Neutra.

## Fase 209 — lanterna nas carroças (01/11/2026)

A máquina seguiu no estado lento da Fase 208: 71,6 FPS (sem a lanterna, no mesmo estado: 71,8), 1% low 38,6, p50/p95/p99
13,2/17,7/24,6 ms, GPU 12,6 ms, montar tudo 9,4 s, carregar 6,0 s, construir com a ilha cheia 17,7 ms; +10 objetos e draw
calls (as duas superfícies a mais da malha das carroças) e +66 mil primitivas no quadro com tudo visível (200 carroças). A
primeira versão, com a lanterna em duas camadas próprias reposicionadas a cada quadro, deu 71,1. Neutra; fecha o roteiro
estandarte, bebedouro e lanterna.

## Fase 210 — pombos na cumeeira (01/11/2026)

A máquina seguiu no estado lento: 71,5 FPS (sem os pombos, no mesmo estado: 71,5), 1% low 37,8, p50/p95/p99 13,3/17,9/24,7 ms,
GPU 12,6 ms (sem: 12,5), montar tudo 9,3 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; +1 objeto e draw call e +47 mil
primitivas no quadro com tudo visível. A primeira malha do pombo (bolas de muitas faces) punha +110 mil primitivas e GPU 12,8 ms
(~1 FPS); a de bolas de 6 × 3 faces é neutra. Abre o roteiro pombo, mó e buxo.

## Fase 211 — mós no moinho (01/11/2026)

A máquina seguiu no estado lento: 71,0 FPS (210: 71,5), 1% low 37,0, p50/p95/p99 13,3/18,1/24,9 ms, GPU 12,7 ms, montar tudo
9,3 s, carregar 6,3 s, construir com a ilha cheia 17,8 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem moinho). Neutra.

## Fase 212 — buxo na porta (01/11/2026)

A máquina seguiu no estado lento: 71,3 FPS (211: 71,0), 1% low 38,4, p50/p95/p99 13,3/18,0/24,5 ms, GPU 12,6 ms, montar tudo
9,3 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark é de operários). Neutra.

## Fase 213 — lenha da padaria (01/11/2026)

A máquina seguiu no estado lento: 70,9 FPS (212: 71,3), 1% low 38,1, p50/p95/p99 13,4/18,0/24,5 ms, GPU 12,7 ms, montar tudo
9,4 s, carregar 6,1 s, construir com a ilha cheia 17,5 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem padaria). Neutra.

## Fase 214 — escada de mão (01/11/2026)

A máquina seguiu no estado lento: 71,5 FPS (213: 70,9), 1% low 38,1, p50/p95/p99 13,3/17,9/24,8 ms, GPU 12,6 ms, montar tudo
9,3 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (as casas do benchmark encostam umas nas outras). Neutra; fecha o roteiro pombo, mó e buxo e os quatro ciclos do
quinto pedido do dono (Fases 195 a 214). Ao longo deles o FPS médio ficou em ~80 com a máquina no estado rápido (195 a 207) e
caiu para ~71 quando ela passou ao lento (208 em diante, o dono usando o PC); os A/B das Fases 200, 208, 209 e 210 mostraram as
fases neutras no mesmo estado. Montar, carregar e construir ficaram onde estavam (o carregar subiu 0,4 s nas Fases 201 a 204 e
voltou com a memória das buscas junto da rua).

## Fase 215 — tábuas secando na serraria (01/11/2026)

A máquina voltou ao estado rápido: 78,6 FPS (214, no lento: 71,5), 1% low 40,1, p50/p95/p99 12,0/17,4/23,5 ms, GPU 11,8 ms,
montar tudo 9,4 s, carregar 6,2 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada) e +0,31 milhão de
primitivas no quadro com tudo visível (as pilhas das serrarias da cidade do benchmark, ~1.700 triângulos por célula). Neutra;
abre o roteiro tábua, cortina e andorinha.

## Fase 216 — monte de carvão na usina (01/11/2026)

A máquina seguiu no estado rápido: 78,6 FPS (215: 78,6), 1% low 39,5, p50/p95/p99 11,9/17,4/23,7 ms, GPU 11,7 ms, montar tudo
9,5 s, carregar 6,1 s, construir com a ilha cheia 17,3 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem usina a carvão). Neutra.

## Fase 217 — cortinas nas janelas (01/11/2026)

A máquina seguiu no estado rápido: 78,0 FPS (216: 78,6), 1% low 37,8, p50/p95/p99 11,9/17,6/24,1 ms, GPU 11,8 ms (216: 11,7),
montar tudo 9,4 s, carregar 6,1 s, construir com a ilha cheia 17,5 ms; objetos e draw calls iguais (as cortinas vão na malha
das casas) e +0,19 milhão de primitivas no quadro com tudo visível (seis triângulos por janela). O 0,1% low (28,5) e o pior
quadro (42 ms) caíram porque uma importação do projeto rodou junto no fim da medida; a Fase 218 confere. Neutra.

## Fase 218 — andorinhas no campanário (01/11/2026)

A máquina seguiu no estado rápido: 77,5 FPS (217: 78,0), 1% low 39,5, 0,1% low 35,4, pior quadro 29 ms (os lows da 217 voltaram:
a queda lá era a importação junto), p50/p95/p99 12,1/17,6/23,7 ms, GPU 11,9 ms, montar tudo 9,4 s, carregar 6,2 s, construir
com a ilha cheia 17,5 ms; objetos, draw calls e primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem
igreja, e o bando sem torre fica escondido). Neutra.

## Fase 219 — balanço e gangorra na escola (01/11/2026)

A máquina seguiu no estado rápido: 78,1 FPS (218: 77,5), 1% low 39,5, p50/p95/p99 12,0/17,4/23,9 ms, GPU 11,8 ms, montar tudo
9,3 s, carregar 6,1 s, construir com a ilha cheia 17,3 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem escola). A busca de lado comum (`SideYard`) não mudou montar nem carregar. Neutra;
fecha o roteiro tábua, cortina e andorinha.

## Fase 220 — bomba de incêndio no quartel (01/11/2026)

A máquina seguiu no estado rápido: 77,3 FPS (219: 78,1), 1% low 39,3, p50/p95/p99 12,2/17,5/23,9 ms, GPU 11,9 ms, montar tudo
9,4 s, carregar 6,3 s, construir com a ilha cheia 17,3 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem quartel). Neutra; abre o roteiro bomba, barril e lençol.

## Fase 221 — barris na cervejaria (01/11/2026)

A máquina seguiu no estado rápido: 77,2 FPS (220: 77,3), 1% low 38,5, p50/p95/p99 12,3/17,6/23,9 ms, GPU 11,9 ms, montar tudo
9,5 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (as pilhas da cidade do benchmark ficam fora do quadro medido). A primeira rodada deu o carregar em 6,5 s: cada
pátio de lado refazia as buscas dos de antes; com elas guardadas (`SideYard.remember`) voltou a 6,1. Neutra.

## Fase 222 — covos no cais (01/11/2026)

A máquina seguiu no estado rápido: 78,1 FPS (221: 77,2), 1% low 39,3, p50/p95/p99 12,1/17,3/24,1 ms, GPU 11,9 ms, montar tudo
9,5 s, carregar 6,2 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada) e +0,10 milhão de primitivas no
quadro com tudo visível (as pilhas dos cais das colônias). A primeira malha (arcos de seis lanços, o cabo em catorze, as boias
de dez lados) punha +0,16 milhão e deu 76,9 FPS; com menos faces, neutra.

## Fase 223 — lençóis no hospital (01/11/2026)

A máquina seguiu no estado rápido: 76,8 FPS (222: 78,1; a mesma cena, só +5 objetos sem nada a desenhar: o vaivém é da
máquina), 1% low 39,1, p50/p95/p99 12,4/17,4/23,9 ms, GPU 12,0 ms, montar tudo 9,6 s, carregar 6,1 s, construir com a ilha
cheia 17,8 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem
hospital). Neutra.

## Fase 224 — relógio de sol no largo (01/11/2026)

A máquina seguiu no estado rápido: 77,1 FPS (223: 76,8), 1% low 38,9, p50/p95/p99 12,3/17,5/24,0 ms, GPU 12,0 ms, montar tudo
9,4 s, carregar 6,2 s, construir com a ilha cheia 17,0 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem serviço com largo). Neutra; fecha o roteiro bomba, barril e lençol.

## Fase 225 — lanterna na popa (01/11/2026)

A máquina seguiu no estado rápido: 77,0 FPS (224: 77,1), 1% low 39,5, p50/p95/p99 12,3/17,5/23,6 ms, GPU 12,0 ms, montar tudo
9,5 s (a frota, 1,13 s, igual), carregar 6,1 s, construir com a ilha cheia 17,8 ms; +11 objetos e draw calls (a armação e o vidro
das lanternas dos navios à vista) e +868 primitivas no quadro com tudo visível. A primeira rodada deu montar tudo em 9,7 s; com o
casco lido uma vez para a lanterna e o cordame e as malhas da lanterna divididas, 9,5. Neutra; abre o roteiro lanterna, lã e
morcego.

## Fase 226 — fardos de lã (01/11/2026)

A máquina seguiu no estado rápido: 77,2 FPS (225: 77,0), 1% low 39,0, p50/p95/p99 12,2/17,5/23,9 ms, GPU 11,9 ms, montar tudo
9,4 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem fazenda de ovelhas). Neutra.

## Fase 227 — lamaçal do chiqueiro (01/11/2026)

A máquina seguiu no estado rápido: 77,1 FPS (226: 77,2), 1% low 39,5, p50/p95/p99 12,3/17,4/23,8 ms, GPU 12,0 ms, montar tudo
9,4 s, carregar 6,2 s, construir com a ilha cheia 17,4 ms; +1 objeto e draw call (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem fazenda de porcos). Neutra.

## Fase 228 — barris de petróleo (01/11/2026)

A máquina seguiu no estado rápido: 77,3 FPS (227: 77,1), 1% low 38,8, p50/p95/p99 12,3/17,4/24,2 ms, GPU 11,9 ms, montar tudo
9,4 s, carregar 6,1 s, construir com a ilha cheia 17,6 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark não tem poço de petróleo). Neutra.

## Fase 229 — morcegos ao anoitecer (01/11/2026)

A máquina seguiu no estado rápido: 77,3 FPS (228: 77,3), 1% low 39,2, p50/p95/p99 12,3/17,4/23,6 ms, GPU 12,0 ms, montar tudo
9,5 s, carregar 6,1 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais no quadro com tudo visível (a
cidade do benchmark não tem igreja, e o bando sem torre fica escondido). Neutra; fecha o roteiro lanterna, lã e morcego.

## Fase 230 — sinal no trilho (01/11/2026)

A máquina começou a passar ao estado lento: 75,5 FPS (229: 77,3), 1% low 38,2, p50/p95/p99 12,5/18,0/24,0 ms, GPU 12,2 ms, montar
tudo 9,5 s, carregar 6,1 s, construir com a ilha cheia 16,9 ms; +6 objetos e draw calls (as duas camadas) e primitivas iguais no
quadro com tudo visível (a cidade do benchmark não tem trilho). O A/B sem a vista, logo depois, deu 71,4 FPS e GPU 12,7 ms: a queda
é da máquina, não do sinal. Neutra; abre o roteiro sinal, cormorão e castanha.

## Fase 231 — cormorões nas estacas (01/11/2026)

A máquina passou ao estado lento: 70,8 FPS (sem os cormorões, no mesmo estado: 71,2), 1% low 36,8, p50/p95/p99 13,5/17,7/25,4 ms,
GPU 12,9 ms (sem: 12,9), montar tudo 9,4 s, carregar 6,2 s, construir com a ilha cheia 17,0 ms; +1 objeto e draw call e +3 mil
primitivas no quadro com tudo visível (os cormorões dos cais das colônias). A primeira rodada, com a sombra dos cormorões ligada,
deu 70,3 FPS e GPU 13,1 ms; sem a sombra, neutra.

## Fase 232 — tapete na janela (01/11/2026)

A máquina seguiu no estado lento: 69,9 FPS (231: 70,8), 1% low 37,7, p50/p95/p99 13,6/18,2/24,8 ms, GPU 12,9 ms (231: 12,9), montar
tudo 9,4 s, carregar 6,1 s, construir com a ilha cheia 17,5 ms; +1 objeto e draw call e +6 mil primitivas no quadro com tudo
visível (os tapetes das casas de operários da cidade do benchmark). A primeira malha (a franja em nove fios, com sombra) punha +50
mil primitivas e GPU 13,0 ms; com cinco fios e sem sombra, neutra.

## Fase 233 — cabines de banho (01/11/2026)

A máquina seguiu no estado lento: 69,5 FPS (232: 69,9), 1% low 36,6, p50/p95/p99 13,7/18,3/25,1 ms, GPU 13,0 ms (232: 12,9), montar
tudo 9,4 s, carregar 6,1 s, construir com a ilha cheia 17,5 ms; +5 objetos e draw calls (a camada) e +68 mil primitivas no quadro
com tudo visível (as cabines das praias das colônias, a maior parte nas rodas de raios). Neutra dentro do vaivém do estado lento.

## Fase 234 — fogareiro de castanhas (01/11/2026)

A máquina seguiu no estado lento: 71,2 FPS (233: 69,5), 1% low 38,0, p50/p95/p99 13,5/18,0/24,9 ms, GPU 12,9 ms, montar tudo 9,4 s,
carregar 6,2 s, construir com a ilha cheia 17,2 ms; +6 objetos e draw calls (as duas camadas) e primitivas iguais no quadro com
tudo visível (a cidade do benchmark é de ruas de terra). Neutra; fecha o roteiro sinal, cormorão e castanha e os quatro ciclos do
sexto pedido do dono (Fases 215 a 234). Ao longo deles o FPS médio ficou entre ~77 e ~79 com a máquina no estado rápido (215 a
229) e caiu para ~70 quando ela passou ao lento (230 em diante); os A/B das Fases 230 e 231 mostraram as fases neutras no mesmo
estado. Montar, carregar e construir ficaram onde estavam (o carregar subiu 0,3 s na Fase 221 e voltou com as buscas de lado
guardadas).

## Fase 235 — cervos na beira da mata (01/11/2026)

A máquina seguiu no estado lento: 70,2 FPS (234: 71,2), 1% low 36,5, p50/p95/p99 13,5/18,1/25,6 ms, GPU 13,0 ms (234: 12,9),
montar tudo 9,4 s, carregar 6,3 s, construir com a ilha cheia 17,2 ms; +15 objetos e draw calls (as três camadas, com as passadas
de sombra) e +360 mil primitivas no quadro com tudo visível (os rebanhos das colônias, com a sombra). Neutra dentro do vaivém do
estado lento (233: 69,5 FPS e GPU 13,0).

## Fase 236 — âncora no cais (01/11/2026)

A máquina seguiu no estado lento: 70,1 FPS (235: 70,2), 1% low 36,7, p50/p95/p99 13,5/18,0/25,5 ms, GPU 13,0 ms, montar tudo 9,4 s,
carregar 6,3 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada, com as passadas de sombra) e +22 mil
primitivas no quadro com tudo visível (as âncoras dos cais das colônias). Neutra.

## Fase 237 — marco de légua (01/11/2026)

A máquina seguiu no estado lento: 70,9 FPS (236: 70,1), 1% low 36,6, p50/p95/p99 13,4/18,0/25,4 ms, GPU 12,9 ms, montar tudo 9,4 s,
carregar 6,3 s, construir com a ilha cheia 17,0 ms; +5 objetos e draw calls (a camada) e +5 mil primitivas no quadro com tudo
visível (a cidade do benchmark quase não tem estrada reta e comprida fora da vila). Neutra.

## Fase 238 — bandeira na prefeitura (01/11/2026)

A máquina seguiu no estado lento: 70,1 FPS (237: 70,9), 1% low 35,5, p50/p95/p99 13,6/18,1/25,7 ms, GPU 13,0 ms, montar tudo 9,6 s
(237: 9,4; a vista só olha as prefeituras, e a cidade do benchmark não tem nenhuma: vaivém da máquina), carregar 6,3 s, construir
com a ilha cheia 17,1 ms; objetos, draw calls e primitivas iguais no quadro com tudo visível. Neutra.

## Fase 239 — algas na praia (01/11/2026)

A máquina seguiu no estado lento: 70,0 FPS (238: 70,1), 1% low 36,6, p50/p95/p99 13,6/18,1/25,7 ms, GPU 13,0 ms, montar tudo 9,3 s,
carregar 6,3 s, construir com a ilha cheia 17,4 ms; objetos, draw calls e primitivas iguais no quadro com tudo visível (o quadro
fica longe das praias: o recheio só aparece até 220 m). Neutra; fecha o roteiro cervo, âncora e marco.

## Fase 240 — lagar no vinhedo (01/11/2026)

A máquina seguiu no estado lento: 70,5 FPS (239: 70,0), 1% low 35,9, p50/p95/p99 13,6/18,0/25,8 ms, GPU 13,0 ms, montar tudo 9,4 s,
carregar 6,3 s, construir com a ilha cheia 17,4 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível (a cidade do benchmark não tem vinhedo). Neutra.

## Fase 241 — terreiro de café (01/11/2026)

A máquina seguiu no estado lento: 70,1 FPS (240: 70,5), 1% low 36,2, p50/p95/p99 13,6/18,1/25,7 ms, GPU 13,0 ms, montar tudo 9,3 s,
carregar 6,3 s, construir com a ilha cheia 17,9 ms (240: 17,4; o vaivém das últimas fases vai de 17,0 a 17,9); +5 objetos e draw
calls (a camada) e primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem cafezal). Neutra.

## Fase 242 — tabaco secando (01/11/2026)

A máquina seguiu no estado lento: 70,4 FPS (241: 70,1), 1% low 36,7, p50/p95/p99 13,6/18,0/25,4 ms, GPU 13,0 ms, montar tudo 9,3 s,
carregar 6,4 s, construir com a ilha cheia 17,3 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível (a cidade do benchmark não tem plantação de tabaco). Neutra.

## Fase 243 — vigas de aço empilhadas (01/11/2026)

A máquina seguiu no estado lento: 69,7 FPS (242: 70,4), 1% low 35,3, p50/p95/p99 13,7/18,0/26,0 ms, GPU 13,1 ms, montar tudo 9,4 s,
carregar 6,4 s; construir com a ilha cheia deu 19,7 ms nesta rodada (242: 17,3), mas o laço de medida sem tela (`-- --so-tick`)
com o mesmo código deu 17,1 ms, como nas fases de antes: vaivém da máquina. +5 objetos e draw calls (a camada) e primitivas
iguais no quadro com tudo visível (a cidade do benchmark não tem fábrica de vigas). Neutra.

## Fase 244 — estacas de lúpulo (01/11/2026)

A máquina seguiu no estado lento: 70,3 FPS (243: 69,7), 1% low 36,7, p50/p95/p99 13,6/18,0/25,4 ms, GPU 13,0 ms, montar tudo 9,4 s,
carregar 6,3 s, construir com a ilha cheia 17,0 ms (o 19,7 da Fase 243 foi vaivém); +5 objetos e draw calls (a camada) e
primitivas iguais no quadro com tudo visível (a cidade do benchmark não tem fazenda de lúpulo). Neutra; fecha o roteiro lagar,
terreiro e estacas.

## Fase 245 — coelhos no prado (01/11/2026)

A máquina seguiu no estado lento: 70,0 FPS (244: 70,3), 1% low 37,1, p50/p95/p99 13,6/18,2/25,6 ms, GPU 13,1 ms, montar tudo 9,3 s,
carregar 6,4 s, construir com a ilha cheia 17,2 ms; +1 objeto e draw call e +74 mil primitivas no quadro com tudo visível (os
coelhos, sem sombra). Neutra. A primeira rodada saiu inválida (carregar 3,0 s, o dia a partir das 07:00 e erros de compilação no
log): o `scatter_view.gd` da fase seguinte foi editado com ela rodando, e o Godot carrega os scripts sob demanda.

## Fase 246 — tronco caído com cogumelos (01/11/2026)

A máquina seguiu no estado lento: 70,9 FPS (245: 70,0), 1% low 36,0, p50/p95/p99 13,5/18,0/25,3 ms, GPU 12,9 ms, montar tudo 9,4 s,
carregar 6,3 s, construir com a ilha cheia 17,3 ms; +1 objeto e draw call e +8 mil primitivas no quadro com tudo visível (os
troncos da mata perto da cidade do benchmark). Neutra.

## Fase 247 — madeira curvada no estaleiro (01/11/2026)

A máquina seguiu no estado lento: 69,9 FPS (246: 70,9), 1% low 36,2, p50/p95/p99 13,6/18,1/25,7 ms, GPU 13,0 ms, montar tudo 9,4 s,
carregar 6,3 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível (a cidade do benchmark não tem estaleiro). Neutra.

## Fase 248 — caixotes de vidro (01/11/2026)

A máquina seguiu no estado lento: 70,3 FPS (247: 69,9), 1% low 37,7, p50/p95/p99 13,6/18,0/25,3 ms, GPU 13,0 ms, montar tudo 9,3 s,
carregar 6,4 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível (a cidade do benchmark não tem vidraria). Neutra.

## Fase 249 — montes de pedra nos campos (01/11/2026)

A máquina seguiu no estado lento: 69,9 FPS (248: 70,3), 1% low 36,6, p50/p95/p99 13,6/18,1/25,4 ms, GPU 13,0 ms, montar tudo 9,4 s,
carregar 6,4 s, construir com a ilha cheia 17,4 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível. Neutra; fecha o roteiro coelho, cogumelo e pedra.

## Fase 250 — balança de carga no armazém (01/11/2026)

A máquina voltou ao estado rápido: 77,9 FPS (249, no lento: 69,9), 1% low 39,3, p50/p95/p99 12,2/16,3/24,1 ms, GPU 11,8 ms, montar
tudo 9,3 s, carregar 6,4 s, construir com a ilha cheia 18,5 ms (o vaivém das últimas fases, de 17,0 a 19,7); +5 objetos e draw
calls (a camada) e +8 mil primitivas no quadro com tudo visível (as balanças dos armazéns da cidade do benchmark). Neutra.

## Fase 251 — cabras nas encostas (01/11/2026)

A máquina seguiu no estado rápido: 77,5 FPS (250: 77,9), 1% low 39,5, p50/p95/p99 12,2/16,5/23,9 ms, GPU 11,9 ms (250: 11,8), montar
tudo 9,3 s, carregar 6,4 s, construir com a ilha cheia 17,6 ms; +15 objetos e draw calls (as três camadas, com as passadas de
sombra) e +386 mil primitivas no quadro com tudo visível (os grupos das encostas das colônias, com a sombra, como os cervos da
Fase 235). Neutra.

## Fase 252 — carruagem à porta do teatro (01/11/2026)

A máquina seguiu no estado rápido: 78,1 FPS (251: 77,5), 1% low 38,9, p50/p95/p99 12,1/16,4/24,2 ms, GPU 11,8 ms, montar tudo 9,3 s,
carregar 6,4 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível (a cidade do benchmark não tem teatro). Neutra.

## Fase 253 — cestos de batata (01/11/2026)

A máquina seguiu no estado rápido: 78,1 FPS (252: 78,1), 1% low 39,0, p50/p95/p99 12,1/16,4/24,1 ms, GPU 11,8 ms, montar tudo 9,2 s,
carregar 6,3 s, construir com a ilha cheia 17,1 ms; +5 objetos e draw calls (a camada) e primitivas iguais no quadro com tudo
visível (a cidade do benchmark não tem fazenda de batata). Neutra.

## Fase 254 — canoas na margem do rio (01/11/2026)

A máquina seguiu no estado rápido: 77,7 FPS (253: 78,1), 1% low 39,2, p50/p95/p99 12,2/16,3/24,1 ms, GPU 11,9 ms, montar tudo 9,3 s,
carregar 6,3 s, construir com a ilha cheia 17,2 ms; +5 objetos e draw calls (a camada) e +600 primitivas no quadro com tudo
visível. Neutra. A primeira rodada deu carregar 6,6 s: a busca das margens varria a vizinhança de cada ponto da rede e custava
~160 ms a cada refazer (na carga e no quadro seguinte a cada obra); partindo das células de rio pelo `find` nativo, ~36 ms, com as
mesmas canoas. Fecha o roteiro balança, cabra e canoa e os quatro ciclos do sétimo pedido do dono (Fases 235 a 254).

## Fase 255 — ar limpo e tom vivo (01/11/2026)

Primeira do ciclo da cor viva: 77,0 FPS (254: 77,7), 1% low 37,8, p50/p95/p99 12,3/16,7/24,8 ms, GPU 11,9 ms (254: 11,9), montar
tudo 9,6 s, carregar 6,4 s, construir com a ilha cheia 18,2 ms; objetos, draw calls e primitivas iguais. Neutra: a névoa
volumétrica segue ligada no alto (só a densidade caiu), e a gradação é a mesma passada de ajuste do Environment.

## Fase 256 — copas verdes (01/11/2026)

76,5 FPS (255: 77,0), 1% low 38,2, p50/p95/p99 12,3/16,6/24,1 ms, GPU 12,0 ms (255: 11,9), montar tudo 9,4 s, carregar 6,4 s,
construir com a ilha cheia 17,0 ms; objetos, draw calls e primitivas iguais. Neutra: a luz própria das folhas é uma conta a mais
no fragmento da folhagem.

## Fase 257 — grama viva (01/11/2026)

76,3 FPS (256: 76,5), 1% low 37,4, p50/p95/p99 12,4/16,8/24,5 ms, GPU 12,0 ms (256: 12,0), montar tudo 9,4 s, carregar 6,5 s,
construir com a ilha cheia 17,4 ms; objetos e primitivas iguais. Neutra: duas contas a mais no fragmento do terreno.

## Fase 258 — telhado e parede com cor (01/11/2026)

76,8 FPS (257: 76,3), 1% low 38,1, p50/p95/p99 12,3/16,7/24,6 ms, GPU 11,9 ms (257: 12,0), montar tudo 9,4 s, carregar 6,4 s,
construir com a ilha cheia 17,0 ms; objetos e draw calls iguais. Neutra: só números de cor e um peso a mais no shader do kit.

## Fase 259 — praia dourada (01/11/2026)

77,7 FPS (258: 76,8), 1% low 39,4, p50/p95/p99 12,2/16,5/24,1 ms, GPU 11,9 ms, montar tudo 9,4 s, carregar 6,5 s, construir com a
ilha cheia 17,1 ms; objetos e primitivas iguais. Neutra. Fecha o roteiro da cor viva: do começo ao fim do ciclo, o FPS e a GPU
ficaram onde estavam (Fase 254: 77,7 FPS, GPU 11,9 ms).

## Fase 260 — hora dourada (01/11/2026)

Primeira do ciclo cor viva II: 76,0 FPS (259: 77,7), 1% low 38,1, p50/p95/p99 12,3/16,5/24,9 ms, GPU 12,0 ms (259: 11,9), montar
tudo 9,4 s, carregar 6,4 s, construir com a ilha cheia 17,0 ms; objetos e primitivas iguais. Neutra: uma conta por quadro na
CPU e o `smoothstep` no lugar do `night_light` na folhagem.

## Fase 261 — rocha cinza (01/11/2026)

76,2 FPS (260: 76,0), 1% low 37,7, p50/p95/p99 12,4/16,7/24,5 ms, GPU 12,0 ms (260: 12,0), montar tudo 9,4 s, carregar 6,4 s,
construir com a ilha cheia 17,2 ms; objetos e primitivas iguais. Neutra: as pedras soltas trocaram o `StandardMaterial3D` pelo
shader da rocha (o mesmo número de materiais) e duas contas a mais na pedra e no terreno. O pior quadro dessa rodada (56 ms) não
se repetiu nas outras medidas do ciclo.

## Fase 262 — campos coloridos (01/11/2026)

76,2 FPS (261: 76,2), 1% low 38,0, p50/p95/p99 12,4/16,4/24,6 ms, GPU 12,0 ms, montar tudo 9,4 s, carregar 6,5 s, construir com a
ilha cheia 17,6 ms; objetos e primitivas iguais. Neutra: só a cor das leiras, que já se escrevia por instância a cada degrau.

## Fase 263 — noite azul (01/11/2026)

76,1 FPS (262: 76,2), 1% low 38,4, p50/p95/p99 12,4/16,5/24,7 ms, GPU 12,0 ms, montar tudo 9,3 s, carregar 6,4 s, construir com a
ilha cheia 17,5 ms; objetos e primitivas iguais. Neutra: só um termo a mais na conta da exposição por quadro.

## Fase 264 — sombra aberta (01/11/2026)

76,5 FPS (263: 76,1), 1% low 38,7, p50/p95/p99 12,4/16,5/24,3 ms, GPU 12,0 ms, montar tudo 9,5 s, carregar 6,5 s, construir com a
ilha cheia 17,2 ms; objetos e primitivas iguais. Neutra: a força do SSAO não muda o custo dele. Fecha o roteiro cor viva II
(Fases 260 a 264): do começo ao fim do ciclo o FPS ficou entre 76 e 78 e a GPU em 12,0 ms.

## Fase 265 — garças no rio (02/11/2026)

Primeira do ciclo garça, ruína e cruzeiro: 76,4 FPS (264: 76,5), 1% low 37,9, p50/p95/p99 12,3/16,7/24,8 ms, GPU 12,0 ms, montar
tudo 9,3 s, carregar 6,4 s, construir com a ilha cheia 17,8 ms; +1 objeto e draw call (a camada) e +350 primitivas no quadro com
tudo visível. Neutra.

## Fase 266 — ruínas de muro (02/11/2026)

77,4 FPS (265: 76,4), 1% low 38,6, p50/p95/p99 12,2/16,3/24,2 ms, GPU 11,9 ms, montar tudo 9,4 s, carregar 6,4 s, construir com a
ilha cheia 17,7 ms; +1 objeto e draw call e +780 primitivas no quadro com tudo visível (as ruínas por perto). Neutra.

## Fase 267 — espinheiro florido (02/11/2026)

76,9 FPS (266: 77,4), 1% low 39,8, p50/p95/p99 12,3/16,5/23,8 ms, GPU 12,0 ms, montar tudo 9,4 s, carregar 6,5 s, construir com a
ilha cheia 17,4 ms; +1 objeto e draw call e +31 mil primitivas no quadro com tudo visível (os espinheiros da beira das matas por
perto). Neutra.

## Fase 268 — casco naufragado (02/11/2026)

76,7 FPS (267: 76,9), 1% low 37,9, p50/p95/p99 12,3/16,5/24,5 ms, GPU 11,9 ms, montar tudo 9,3 s, carregar 6,4 s, construir com a
ilha cheia 17,5 ms; +5 objetos e draw calls (a camada, com as passadas de sombra) e +21 mil primitivas no quadro com tudo visível.
Neutra.

## Fase 269 — cruzeiro no morro (02/11/2026)

76,2 FPS (268: 76,7), 1% low 37,9, p50/p95/p99 12,4/16,7/24,6 ms, GPU 12,1 ms, montar tudo 9,4 s, carregar 6,5 s, construir com a
ilha cheia 16,9 ms; +5 objetos e draw calls (a camada, com as passadas de sombra) e +7 mil primitivas no quadro com tudo visível.
Neutra. Fecha o roteiro garça, ruína e cruzeiro (Fases 265 a 269).

## Fase 270 — corvos no campo (02/11/2026)

Primeira do ciclo corvo, dedaleira e nenúfar: 76,1 FPS (269: 76,2), 1% low 38,2, p50/p95/p99 12,4/16,4/24,8 ms, GPU 12,0 ms, montar
tudo 9,4 s, carregar 6,6 s, construir com a ilha cheia 17,1 ms; +1 objeto e draw call (a camada) e primitivas iguais no quadro com
tudo visível (os campos da cidade do benchmark já cresceram). Neutra.

## Fase 271 — dedaleiras (02/11/2026)

76,3 FPS (270: 76,1), 1% low 38,6, p50/p95/p99 12,3/16,3/24,7 ms, GPU 11,9 ms, montar tudo 9,4 s, carregar 6,5 s, construir com a
ilha cheia 17,4 ms; objetos e primitivas iguais no quadro com tudo visível (nenhuma por perto). Neutra.

## Fase 272 — anel de cogumelos (02/11/2026)

75,6 FPS (271: 76,3), 1% low 37,3, p50/p95/p99 12,4/16,7/24,7 ms, GPU 12,1 ms, montar tudo 9,4 s, carregar 6,6 s (271: 6,5),
construir com a ilha cheia 17,4 ms; objetos e primitivas iguais. Neutra (o carregar fica no vaivém de 6,4 a 6,6 s das últimas
fases; cada regra nova do recheio soma um sorteio por célula da lista dela).

## Fase 273 — andorinhas no fio (02/11/2026)

75,1 FPS (272: 75,6), 1% low 37,9, p50/p95/p99 12,6/16,9/24,7 ms, GPU 12,2 ms (272: 12,1), montar tudo 9,4 s, carregar 6,6 s,
construir com a ilha cheia 17,2 ms; +1 objeto e draw call (a camada) e primitivas iguais (a cidade do benchmark não tem usina).
Neutra: a camada não desenha nada nessa cidade; o FPS e a GPU estão no vaivém do estado da máquina (de 75 a 78 neste pedido).

## Fase 274 — girassóis (02/11/2026)

76,5 FPS (273: 75,1), 1% low 38,3, p50/p95/p99 12,3/16,6/24,6 ms, GPU 12,0 ms, montar tudo 9,4 s, carregar 6,5 s, construir com a
ilha cheia 17,7 ms; objetos e primitivas iguais no quadro com tudo visível. Neutra. Fecha o roteiro corvo, dedaleira e girassol e
os quatro ciclos do oitavo pedido do dono (Fases 255 a 274): do começo ao fim o FPS ficou entre 75 e 78 e a GPU entre 11,9 e
12,2 ms.

## Fase 275 — abeto em camadas (02/11/2026)

Primeira do ciclo da mata: 76,9 FPS (274: 76,5), 1% low 37,3, p50/p95/p99 12,3/16,6/24,3 ms, GPU 12,0 ms, jogo novo 12,3 s (28830
árvores desenhadas, iguais), montar tudo 9,5 s, carregar 6,5 s, construir com a ilha cheia 17,6 ms; +17 objetos e draw calls no
quadro com tudo visível (os trechos com abeto e pinheiro ganham uma camada) e primitivas iguais. O pior quadro do dia (55 ms, 274:
31) foi um só, sem repetir no p99. Neutra.

## Fase 276 — copas na medida (02/11/2026)

78,9 FPS (275: 76,9), 1% low 39,4, p50/p95/p99 11,9/16,1/24,1 ms, GPU 11,5 ms (275: 12,0), jogo novo 12,3 s com 17249 árvores
desenhadas (eram 28830), montar tudo 9,1 s, carregar 6,5 s, construir com a ilha cheia 17,5 ms; objetos e draw calls iguais e
~0,4 milhão de primitivas a menos no quadro com tudo visível. Melhor: menos árvores desenhadas (uma por célula, e só em parte
delas, na mata temperada) e copas menores.

## Fase 277 — bétula (02/11/2026)

78,1 FPS (276: 78,9), 1% low 38,7, p50/p95/p99 12,1/16,2/24,0 ms, GPU 11,7 ms (276: 11,5), jogo novo 12,3 s (17249 árvores
desenhadas, iguais), montar tudo 9,2 s, carregar 6,4 s, construir com a ilha cheia 17,2 ms; +20 objetos e draw calls no quadro
com tudo visível (os trechos com bétula ganham a camada dela) e primitivas iguais. Neutra.

## Fase 278 — orla da mata (02/11/2026)

77,2 FPS (277: 78,1), 1% low 38,4, p50/p95/p99 12,1/16,5/24,2 ms, GPU 11,8 ms (277: 11,7), jogo novo 12,3 s com 19236 árvores
desenhadas (+1987 da orla), montar tudo 9,5 s, carregar 6,4 s, construir com a ilha cheia 17,4 ms; objetos e draw calls iguais
(as árvores novas usam as camadas da mata) e +0,08 milhão de primitivas. Neutra.

## Fase 279 — folhas recortadas (02/11/2026)

Duas rodadas: 74,8 e 75,3 FPS (278: 77,2), 1% low 37,4 e 37,9, p50/p95/p99 12,6/17,0/24,9 e 12,6/16,9/24,7 ms, GPU 12,2 e 12,1
ms (278: 11,8), jogo novo 13,4 e 12,4 s, montar tudo 9,7 s, carregar 6,4 s, construir com a ilha cheia 17,7 ms; objetos, draw
calls e primitivas iguais. O custo do recorte (o `discard` tira a profundidade antecipada das copas de perto) e dos cachos fica
em +0,3 a 0,4 ms de GPU, abaixo do limite de 0,5 ms do roteiro: vale em todos os níveis. O ciclo da mata (Fases 275 a 279) fecha
com a GPU onde estava antes dele (274: 12,0 ms), porque a Fase 276 tirou 0,5 ms.

## Fase 280 — mar fundo (02/11/2026)

Primeira do ciclo do mar e do rio: 76,2 FPS (279: 75,3), 1% low 38,9, p50/p95/p99 12,4/16,7/24,2 ms, GPU 12,0 ms (279: 12,1),
jogo novo 12,4 s, montar tudo 9,4 s, carregar 6,4 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas
iguais. Neutra (só as cores da água e uma mistura a mais no shader dela).

## Fase 281 — rebentação fina (02/11/2026)

76,6 FPS (280: 76,2), 1% low 38,2, p50/p95/p99 12,4/16,4/24,1 ms, GPU 12,0 ms, jogo novo 12,3 s, montar tudo 9,5 s, carregar
6,5 s, construir com a ilha cheia 17,1 ms; objetos, draw calls e primitivas iguais. Neutra.

## Fase 282 — água de noite (02/11/2026)

77,2 FPS (281: 76,6), 1% low 38,6, p50/p95/p99 12,3/16,3/24,0 ms, GPU 11,9 ms, jogo novo 12,4 s, montar tudo 9,5 s, carregar
6,5 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais. Neutra.

## Fase 283 — rio escuro (02/11/2026)

Três rodadas. Com as sondas do canal em toda a água: 75,4 e 75,6 FPS, GPU 12,2 e 12,1 ms (282: 11,9). Com elas só perto da terra:
76,1 FPS, 1% low 38,2, p50/p95/p99 12,5/16,7/24,9 ms, GPU 12,0 ms, jogo novo 12,3 s, montar tudo 9,6 s, carregar 6,5 s, construir
com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra.

## Fase 284 — marulho (02/11/2026)

75,9 FPS (283: 76,1), 1% low 38,6, p50/p95/p99 12,5/16,6/24,6 ms, GPU 12,1 ms (283: 12,0), jogo novo 12,4 s, montar tudo 9,5 s,
carregar 6,4 s, construir com a ilha cheia 18,3 ms (no vaivém de 17 a 18 ms); objetos, draw calls e primitivas iguais. Neutra.
Fecha o ciclo do mar e do rio (Fases 280 a 284) com a GPU onde ele começou (279: 12,1 ms).

## Fase 285 — manchas do prado (02/11/2026)

Primeira do ciclo do prado: 74,8 FPS (284: 75,9), 1% low 38,2, p50/p95/p99 12,6/16,9/24,7 ms, GPU 12,2 ms (284: 12,1), jogo novo
12,4 s, montar tudo 9,5 s, carregar 6,5 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais. Neutra
(dois ruídos e uma leitura de textura a mais por pixel de terreno, ~0,1 ms).

## Fase 286 — tapete de capim (02/11/2026)

74,9 FPS (285: 74,8), 1% low 38,1, p50/p95/p99 12,7/16,8/24,2 ms, GPU 12,3 ms (285: 12,2), jogo novo 12,3 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais no quadro com tudo visível (com a
câmera alta o tapete fica escondido). O trajeto passa quase só pela vila: o custo com a câmera em cima do prado aberto saiu do
`tools/grass_cost.tscn` (~32 mil tufos): +0,39 ms de GPU a 30 m, +0,34 a 60 m e +0,17 a 110 m. Montar um bloco leva ~0,7 ms na
CPU, três por quadro com a câmera andando.

## Fase 287 — flores miúdas (02/11/2026)

74,1 FPS (286: 74,9), 1% low 38,0, p50/p95/p99 12,8/17,1/24,4 ms, GPU 12,3 ms (286: 12,3), jogo novo 12,6 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra. Sobre o prado aberto
(`tools/grass_cost.tscn`) o tapete com as flores custa +0,32 a 0,43 ms de GPU (286: +0,17 a 0,39).

## Fase 288 — papoulas soltas (02/11/2026)

74,6 FPS (287: 74,1), 1% low 38,5, p50/p95/p99 12,7/17,0/24,5 ms, GPU 12,3 ms, jogo novo 12,4 s, montar tudo 9,5 s, carregar
6,5 s, construir com a ilha cheia 17,1 ms; objetos, draw calls e primitivas iguais. Neutra.

## Fase 289 — beira do barranco (02/11/2026)

73,8 FPS (288: 74,6), 1% low 37,3, p50/p95/p99 12,8/17,0/25,1 ms, GPU 12,3 ms (288: 12,3), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,6 ms; objetos, draw calls e primitivas iguais. Neutra na GPU; o FPS segue a descida
lenta do ciclo do prado (de 75,9 na Fase 284 a 73,8), com a GPU de 12,1 a 12,3 ms: as manchas, as flores e a beira no terreno e o
tapete, que no trajeto do benchmark quase não aparece.

## Fase 290 — estratos na rocha (02/11/2026)

Três rodadas: 73,4, 73,7 e 73,2 FPS, GPU 12,5 ms nas três (289: 12,3), jogo novo 12,3 s, montar tudo 9,5 s, carregar 6,5 s,
construir com a ilha cheia 17,1 a 17,3 ms; objetos, draw calls e primitivas iguais. A/B na mesma hora: a Fase 289 (worktree no
commit anterior) deu 74,5 FPS e GPU 12,4 ms. Os estratos custam ~0,1 ms; o resto foi a máquina mais lenta nessa hora.

## Fase 291 — musgo nas saliências (02/11/2026)

73,2 FPS (290: 73,2 a 73,7), 1% low 37,7, p50/p95/p99 12,9/17,3/24,6 ms, GPU 12,5 ms (290: 12,5), jogo novo 12,5 s, montar tudo
9,5 s, carregar 6,5 s, construir com a ilha cheia 17,4 ms; objetos, draw calls e primitivas iguais. Neutra.

## Fase 292 — praia de seixos (02/11/2026)

73,0 FPS (291: 73,2), 1% low 36,9, p50/p95/p99 13,0/17,0/24,8 ms, GPU 12,6 ms (291: 12,5), jogo novo 12,3 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,0 ms; objetos, draw calls e primitivas iguais. Neutra (a busca da rocha e o
Voronoi só na areia).

## Fase 293 — espuma nas pedras (02/11/2026)

73,4 FPS (292: 73,0), 1% low 38,1, p50/p95/p99 12,8/17,2/24,7 ms, GPU 12,5 ms (292: 12,6), jogo novo 12,3 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,1 ms; objetos, draw calls e primitivas iguais. Neutra.

## Fase 294 — abetos na rocha (02/11/2026)

72,9 FPS (293: 73,4), 1% low 38,3, p50/p95/p99 13,0/17,1/24,5 ms, GPU 12,6 ms (293: 12,5), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,4 s, construir com a ilha cheia 16,9 ms; +1 objeto e draw call (a camada) no quadro com tudo visível. Neutra. Fecha os
quatro ciclos da ideação de 02/11/2026 (Fases 275 a 294): a GPU foi de 12,0 ms (274) a 12,6 ms, com 0,5 ms a menos na Fase 276 e
os custos medidos do recorte das folhas (+0,3 a 0,4), dos estratos (~0,1) e o resto no vaivém da máquina, que ficou mais lenta
ao longo do dia (A/B da Fase 290).

### 2026-11-02 15:58:28 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3008 / 1282 ms (24 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12417 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1085 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9408 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.54 / 2.91 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.2 / 17.5 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.53 ms |
| salvar | 85 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6509 ms |
| quadro com tudo visível | 13 ms (78 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 303 quadros, 1407 ms; 1386 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 74.7 / 37.7 / 30.4 FPS / 38 ms em 4480 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.7 / 16.8 / 24.7 ms; GPU média 12.4 ms (p99 16.3); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.97 / 15.45 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 441 / 39 ms; 16.3 ms (3588 objetos · 1712 draw calls · 63434205 primitivas) |

## Fase 295 — espuma em trechos (02/11/2026)

74,7 FPS (294: 72,9), 1% low 37,7, p50/p95/p99 12,7/16,8/24,7 ms, GPU 12,4 ms (294: 12,6), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra (um ruído de valor a mais só
na faixa das bandas).

### 2026-11-02 16:03:01 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3000 / 1285 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12393 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1095 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9421 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.31 / 1.62 / 2.74 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.1 ms (limite 50 ms): comando e vistas 17.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.2 / 17.0 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.51 ms |
| salvar | 84 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6488 ms |
| quadro com tudo visível | 13 ms (78 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 314 quadros, 1422 ms; 1398 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.32 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 74.3 / 38.1 / 31.6 FPS / 33 ms em 4456 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.7 / 16.8 / 24.3 ms; GPU média 12.5 ms (p99 16.3); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.95 / 14.74 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 447 / 41 ms; 16.3 ms (3588 objetos · 1711 draw calls · 63453357 primitivas) |

## Fase 296 — água picada de perto (02/11/2026)

74,3 FPS (295: 74,7), 1% low 38,1, p50/p95/p99 12,7/16,8/24,3 ms, GPU 12,5 ms (295: 12,4), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,1 ms; objetos, draw calls e primitivas iguais. Neutra (quatro senos e um ruído só
na água até 90 m da câmera).

### 2026-11-02 16:08:04 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2995 / 1278 ms (29 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12419 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1081 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9416 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.89 / 2.71 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.2 ms (limite 50 ms): comando e vistas 17.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.2 / 17.1 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.49 ms |
| salvar | 87 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6505 ms |
| quadro com tudo visível | 13 ms (77 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 312 quadros, 1404 ms; 1403 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 74.1 / 38.1 / 32.6 FPS / 31 ms em 4447 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.8 / 16.8 / 24.4 ms; GPU média 12.5 ms (p99 16.4); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.00 / 15.19 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 436 / 39 ms; 16.4 ms (3588 objetos · 1711 draw calls · 63453357 primitivas) |

## Fase 297 — fiapos de espuma nas pedras (02/11/2026)

74,1 FPS (296: 74,3), 1% low 38,1, p50/p95/p99 12,8/16,8/24,4 ms, GPU 12,5 ms (296: 12,5), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 16:14:48 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3006 / 1295 ms (25 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12480 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1084 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9481 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.34 / 1.54 / 2.78 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.9 / 17.1 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.49 ms |
| salvar | 87 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6478 ms |
| quadro com tudo visível | 13 ms (74 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 310 quadros, 1431 ms; 1416 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 73.5 / 36.8 / 28.3 FPS / 43 ms em 4408 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.9 / 17.1 / 24.8 ms; GPU média 12.6 ms (p99 16.7); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.03 / 14.93 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 441 / 39 ms; 16.4 ms (3588 objetos · 1712 draw calls · 63434205 primitivas) |

## Fase 298 — mar escuro de longe (02/11/2026)

73,5 FPS (297: 74,1), 1% low 36,8, p50/p95/p99 12,9/17,1/24,8 ms, GPU 12,6 ms (297: 12,5), jogo novo 12,5 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra (dois fatores pela distância).

### 2026-11-02 16:19:42 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3018 / 1304 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12323 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1112 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9511 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.34 / 1.52 / 2.75 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.2 ms (limite 50 ms): comando e vistas 17.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.4 / 17.2 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.54 ms |
| salvar | 91 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6431 ms |
| quadro com tudo visível | 13 ms (77 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 312 quadros, 1406 ms; 1368 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 73.1 / 37.2 / 28.5 FPS / 43 ms em 4385 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.9 / 17.3 / 24.8 ms; GPU média 12.6 ms (p99 16.8); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.99 / 14.89 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 455 / 39 ms; 16.5 ms (3588 objetos · 1711 draw calls · 63453357 primitivas) |

## Fase 299 — fundo à vista no raso (02/11/2026)

73,1 FPS (298: 73,5), 1% low 37,2, p50/p95/p99 12,9/17,3/24,8 ms, GPU 12,6 ms (298: 12,6), jogo novo 12,3 s, montar tudo 9,5 s,
carregar 6,4 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais. Neutra (o fundo só debaixo d'água
nas temperadas). Fecha o roteiro mar e costa II (Fases 295 a 299): GPU de 12,6 (294) a 12,6 ms.

### 2026-11-02 16:39:35 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3029 / 1276 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12349 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1097 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9435 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.59 / 2.75 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.9 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.1 / 17.2 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.48 ms |
| salvar | 85 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6528 ms |
| quadro com tudo visível | 13 ms (78 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1907 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 323 quadros, 1439 ms; 1397 rotas, 0.67 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 73.2 / 38.0 / 33.5 FPS / 31 ms em 4391 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.9 / 17.2 / 24.8 ms; GPU média 12.6 ms (p99 16.8); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.98 / 15.30 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 435 / 39 ms; 16.6 ms (3588 objetos · 1712 draw calls · 63434205 primitivas) |

## Fase 300 — telhas gastas (02/11/2026)

73,2 FPS (299: 73,1), 1% low 38,0, p50/p95/p99 12,9/17,2/24,8 ms, GPU 12,6 ms (299: 12,6), jogo novo 12,3 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 16:48:10 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3007 / 1267 ms (24 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12371 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1088 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9435 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.45 / 2.70 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.2 ms (limite 50 ms): comando e vistas 17.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.2 / 17.1 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.51 ms |
| salvar | 85 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6434 ms |
| quadro com tudo visível | 13 ms (75 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1903 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 306 quadros, 1420 ms; 1392 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 74.5 / 38.5 / 33.5 FPS / 31 ms em 4471 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.7 / 16.9 / 24.4 ms; GPU média 12.5 ms (p99 16.5); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.00 / 15.26 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 442 / 40 ms; 16.5 ms (3588 objetos · 1712 draw calls · 63434205 primitivas) |

## Fase 301 — chão de vila (02/11/2026)

74,5 FPS (300: 73,2), 1% low 38,5, p50/p95/p99 12,7/16,9/24,4 ms, GPU 12,5 ms (300: 12,6), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,4 s, construir com a ilha cheia 17,2 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 16:52:39 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2996 / 1277 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12286 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1085 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9383 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.47 / 2.70 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.5 ms (limite 50 ms): comando e vistas 17.4 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.7 / 17.0 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.50 ms |
| salvar | 88 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6420 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 315 quadros, 1411 ms; 1405 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 73.3 / 38.4 / 33.7 FPS / 31 ms em 4400 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.9 / 17.0 / 24.6 ms; GPU média 12.6 ms (p99 16.6); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.01 / 14.98 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 444 / 39 ms; 16.6 ms (3588 objetos · 1711 draw calls · 63452637 primitivas) |

## Fase 302 — sujeira nas paredes (02/11/2026)

73,3 FPS (301: 74,5), 1% low 38,4, p50/p95/p99 12,9/17,0/24,6 ms, GPU 12,6 ms (301: 12,5), jogo novo 12,3 s, montar tudo 9,4 s,
carregar 6,4 s, construir com a ilha cheia 17,5 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 17:04:33 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3002 / 1289 ms (24 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12355 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1142 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9454 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.69 / 2.77 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.1 ms (limite 50 ms): comando e vistas 17.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 18.0 / 17.3 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.56 ms |
| salvar | 88 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6521 ms |
| quadro com tudo visível | 13 ms (77 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3434 · 1674 · 20034368 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 316 quadros, 1406 ms; 1394 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 73.3 / 37.1 / 31.0 FPS / 34 ms em 4398 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 12.9 / 17.2 / 24.7 ms; GPU média 12.7 ms (p99 16.8); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.02 / 14.76 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 436 / 40 ms; 16.6 ms (3588 objetos · 1712 draw calls · 63434925 primitivas) |

## Fase 303 — telhado de tábuas (02/11/2026)

73,3 FPS (302: 73,3), 1% low 37,1, p50/p95/p99 12,9/17,2/24,7 ms, GPU 12,7 ms (302: 12,6), jogo novo 12,4 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,1 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 21:46:09 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3008 / 1277 ms (22 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12417 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1111 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9481 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.49 / 2.83 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.5 ms (limite 50 ms): comando e vistas 17.5 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.8 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 17.8 / 16.8 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.53 ms |
| salvar | 90 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6522 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3436 · 1676 · 20059328 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 320 quadros, 1417 ms; 1408 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.26 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.5 / 38.0 / 30.5 FPS / 42 ms em 4349 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.0 / 17.4 / 24.5 ms; GPU média 12.7 ms (p99 16.9); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.97 / 15.54 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 442 / 39 ms; 16.8 ms (3590 objetos · 1713 draw calls · 63477597 primitivas) |

## Fase 304 — muro dos quintais (02/11/2026)

72,5 FPS (303: 73,3), 1% low 38,0, p50/p95/p99 13,0/17,4/24,5 ms, GPU 12,7 ms (303: 12,7), jogo novo 12,4 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,5 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 22:16:48 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3025 / 1293 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12394 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1098 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9444 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.38 / 1.89 / 3.00 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.43 · produção 0.33 · população 0.30 · necessidades 0.11 · riscos 0.05 · navios 0.05 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.7 / 16.9 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.50 ms |
| salvar | 85 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6538 ms |
| quadro com tudo visível | 14 ms (73 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3436 · 1676 · 20059328 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 311 quadros, 1401 ms; 1391 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.0 / 37.3 / 32.4 FPS / 32 ms em 4321 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.1 / 17.4 / 24.9 ms; GPU média 12.7 ms (p99 16.9); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.00 / 15.60 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 442 / 39 ms; 16.7 ms (3590 objetos · 1714 draw calls · 63459165 primitivas) |

## Fase 305 — tom por árvore (02/11/2026)

72,0 FPS (304: 72,5), 1% low 37,3, p50/p95/p99 13,1/17,4/24,9 ms, GPU 12,7 ms (304: 12,7), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 22:22:52 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2989 / 1289 ms (25 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12369 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1100 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9425 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.34 / 1.59 / 2.75 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.4 ms (limite 50 ms): comando e vistas 17.4 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.4 / 16.9 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.51 ms |
| salvar | 86 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6498 ms |
| quadro com tudo visível | 13 ms (74 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3436 · 1676 · 20059328 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 314 quadros, 1423 ms; 1410 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.31 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.5 / 37.6 / 31.4 FPS / 33 ms em 4350 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.1 / 17.5 / 24.7 ms; GPU média 12.8 ms (p99 17.0); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.97 / 14.94 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 443 / 40 ms; 16.8 ms (3590 objetos · 1713 draw calls · 63478317 primitivas) |

## Fase 306 — chão da mata (02/11/2026)

72,5 FPS (305: 72,0), 1% low 37,6, p50/p95/p99 13,1/17,5/24,7 ms, GPU 12,8 ms (305: 12,7), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,4 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 22:28:11 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2985 / 1278 ms (30 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12441 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1089 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9433 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.34 / 1.49 / 2.74 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.05 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.4 ms (limite 50 ms): comando e vistas 17.4 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.7 / 17.0 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.53 ms |
| salvar | 88 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6540 ms |
| quadro com tudo visível | 14 ms (74 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3436 · 1676 · 20059328 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1903 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 311 quadros, 1407 ms; 1404 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.6 / 37.3 / 32.2 FPS / 32 ms em 4298 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.5 / 24.9 ms; GPU média 12.9 ms (p99 17.0); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.99 / 15.31 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 438 / 39 ms; 16.8 ms (3590 objetos · 1714 draw calls · 63459885 primitivas) |

## Fase 307 — sub-bosque (02/11/2026)

71,6 FPS (306: 72,5), 1% low 37,3, p50/p95/p99 13,2/17,5/24,9 ms, GPU 12,9 ms (306: 12,8), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,4 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 22:32:45 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2997 / 1315 ms (28 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12516 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1097 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9574 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.37 / 1.93 / 4.22 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.43 · produção 0.33 · população 0.30 · necessidades 0.11 · riscos 0.05 · navios 0.05 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.1 ms (limite 50 ms): comando e vistas 18.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.9 · serviços 3.9 · módulos, poluição e beleza 0.1 · armazéns 3.4 · produção 2.8 · grupos de casas 0.7 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 17.0 / 17.2 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.54 ms |
| salvar | 85 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6569 ms |
| quadro com tudo visível | 14 ms (74 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3436 · 1676 · 20059328 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1905 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 322 quadros, 1441 ms; 1405 rotas, 0.67 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.2 / 36.1 / 29.4 FPS / 36 ms em 4273 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.7 / 25.3 ms; GPU média 12.9 ms (p99 17.0); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 2.01 / 15.37 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 440 / 39 ms; 16.8 ms (3590 objetos · 1714 draw calls · 63459165 primitivas) |

## Fase 308 — abetos de longe (02/11/2026)

71,2 FPS (307: 71,6), 1% low 36,1, p50/p95/p99 13,2/17,7/25,3 ms, GPU 12,9 ms (307: 12,9), jogo novo 12,5 s, montar tudo 9,6 s,
carregar 6,6 s, construir com a ilha cheia 18,1 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 22:40:44 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2989 / 1300 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12449 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1095 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9447 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.47 / 2.73 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 16.9 ms (limite 50 ms): comando e vistas 16.9 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.2 · produção 2.6 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.4 / 17.1 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.48 ms |
| salvar | 86 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6504 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3437 · 1677 · 20059712 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 316 quadros, 1410 ms; 1405 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.35 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.8 / 38.5 / 33.8 FPS / 30 ms em 4311 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.3 / 17.6 / 24.6 ms; GPU média 12.9 ms (p99 17.1); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.98 / 14.76 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 438 / 39 ms; 16.8 ms (3590 objetos · 1713 draw calls · 63459885 primitivas) |

## Fase 309 — névoa nos vales (02/11/2026)

71,8 FPS (308: 71,2), 1% low 38,5, p50/p95/p99 13,3/17,6/24,6 ms, GPU 12,9 ms (308: 12,9), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 16,9 ms; um objeto e uma draw call a mais. Neutra.

### 2026-11-02 23:05:00 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3022 / 1283 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12456 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1098 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9394 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.34 / 1.46 / 2.79 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 16.8 ms (limite 50 ms): comando e vistas 16.8 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.5 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 17.3 / 17.3 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.50 ms |
| salvar | 87 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6581 ms |
| quadro com tudo visível | 14 ms (74 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3437 · 1677 · 20059712 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 314 quadros, 1407 ms; 1381 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.1 / 35.3 / 25.2 FPS / 45 ms em 4265 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.3 / 17.7 / 25.3 ms; GPU média 12.9 ms (p99 17.1); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 2.05 / 14.95 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 444 / 39 ms; 16.9 ms (3590 objetos · 1713 draw calls · 63459885 primitivas) |

## Fase 310 — blocos na face (02/11/2026)

71,1 FPS (309: 71,8), 1% low 35,3, p50/p95/p99 13,3/17,7/25,3 ms, GPU 12,9 ms (309: 12,9), jogo novo 12,5 s, montar tudo 9,4 s,
carregar 6,6 s, construir com a ilha cheia 16,8 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 23:09:37 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3007 / 1269 ms (24 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12500 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1101 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9435 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.46 / 2.73 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.0 ms (limite 50 ms): comando e vistas 17.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.3 / 17.2 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.54 ms |
| salvar | 86 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6489 ms |
| quadro com tudo visível | 13 ms (75 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3437 · 1677 · 20398912 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 303 quadros, 1393 ms; 1383 rotas, 0.65 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.9 / 38.2 / 34.1 FPS / 32 ms em 4317 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.6 / 24.6 ms; GPU média 12.9 ms (p99 17.1); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.97 / 15.44 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 439 / 39 ms; 16.9 ms (3590 objetos · 1714 draw calls · 63798365 primitivas) |

## Fase 311 — blocos caídos (02/11/2026)

71,9 FPS (310: 71,1), 1% low 38,2, p50/p95/p99 13,2/17,6/24,6 ms, GPU 12,9 ms (310: 12,9), jogo novo 12,5 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,0 ms; primitivas de 20,06 para 20,40 milhões. Neutra.

### 2026-11-02 23:15:23 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3074 / 1262 ms (24 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12444 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1091 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9411 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.55 / 2.96 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.9 ms (limite 50 ms): comando e vistas 17.9 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.4 · produção 3.1 · grupos de casas 0.7 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.6 / 17.2 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.49 ms |
| salvar | 86 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6489 ms |
| quadro com tudo visível | 13 ms (75 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20436796 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1903 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 304 quadros, 1424 ms; 1406 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.0 / 38.3 / 32.4 FPS / 38 ms em 4321 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.7 / 24.6 ms; GPU média 12.9 ms (p99 17.1); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.98 / 15.46 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 441 / 39 ms; 16.9 ms (3591 objetos · 1714 draw calls · 63854681 primitivas) |

## Fase 312 — capim na borda (02/11/2026)

72,0 FPS (311: 71,9), 1% low 38,3, p50/p95/p99 13,2/17,7/24,6 ms, GPU 12,9 ms (311: 12,9), jogo novo 12,4 s, montar tudo 9,4 s,
carregar 6,5 s, construir com a ilha cheia 17,9 ms; um objeto e uma draw call a mais. Neutra.

### 2026-11-02 23:25:12 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2996 / 1319 ms (22 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12528 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1105 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9440 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.48 / 2.75 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.8 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.5 / 17.1 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.51 ms |
| salvar | 88 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6601 ms |
| quadro com tudo visível | 13 ms (74 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20436796 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 312 quadros, 1416 ms; 1399 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.27 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.9 / 37.8 / 32.8 FPS / 33 ms em 4315 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.4 / 24.8 ms; GPU média 12.9 ms (p99 16.9); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 2.02 / 15.91 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 433 / 39 ms; 16.8 ms (3591 objetos · 1714 draw calls · 63854681 primitivas) |

## Fase 313 — fendas com mato (02/11/2026)

71,9 FPS (312: 72,0), 1% low 37,8, p50/p95/p99 13,2/17,4/24,8 ms, GPU 12,9 ms (312: 12,9), jogo novo 12,5 s, montar tudo 9,4 s,
carregar 6,6 s, construir com a ilha cheia 17,3 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-02 23:30:56 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2996 / 1283 ms (23 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12600 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1105 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9404 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.54 / 2.83 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.8 ms (limite 50 ms): comando e vistas 17.8 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.5 · produção 2.8 · grupos de casas 0.6 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 17.1 / 17.4 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.53 ms |
| salvar | 88 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6621 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20436796 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 320 quadros, 1419 ms; 1395 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.27 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.0 / 37.2 / 32.2 FPS / 33 ms em 4320 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.1 / 17.5 / 25.0 ms; GPU média 12.8 ms (p99 17.0); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 2.00 / 15.15 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 443 / 39 ms; 16.9 ms (3591 objetos · 1715 draw calls · 63836249 primitivas) |

## Fase 314 — sombra da falésia na água (02/11/2026)

72,0 FPS (313: 71,9), 1% low 37,2, p50/p95/p99 13,1/17,5/25,0 ms, GPU 12,8 ms (313: 12,9), jogo novo 12,6 s, montar tudo 9,4 s,
carregar 6,6 s, construir com a ilha cheia 17,8 ms; objetos, draw calls e primitivas iguais. Neutra.

### 2026-11-04 18:27:54 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3004 / 1267 ms (21 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12491 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1086 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9463 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 2.10 / 2.79 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.4 ms (limite 50 ms): comando e vistas 17.4 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.8 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.1 / 16.6 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.57 ms |
| salvar | 86 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6529 ms |
| quadro com tudo visível | 13 ms (77 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20436796 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 319 quadros, 1471 ms; 1404 rotas, 0.69 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.4 / 35.3 / 25.0 FPS / 67 ms em 4282 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.3 / 17.9 / 25.3 ms; GPU média 13.0 ms (p99 17.6); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 2.00 / 15.22 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 441 / 40 ms; 17.1 ms (3591 objetos · 1715 draw calls · 63836249 primitivas) |

## Fase 315 — capim no alto da garganta (04/11/2026)

71,4 FPS (314: 72,0), 1% low 35,3, p50/p95/p99 13,3/17,9/25,3 ms, GPU 13,0 ms (314: 12,8), jogo novo 12,5 s, montar tudo 9,5 s,
carregar 6,5 s, construir com a ilha cheia 17,4 ms; objetos, draw calls e primitivas iguais. Neutra (um smoothstep a mais no terreno).

### 2026-11-04 18:42:37 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2997 / 1242 ms (21 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12298 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1085 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9428 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.50 / 3.03 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.9 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 17.1 / 16.9 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.54 ms |
| salvar | 83 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6488 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20443660 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 324 quadros, 1476 ms; 1407 rotas, 0.70 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.30 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.6 / 37.2 / 29.8 FPS / 39 ms em 4297 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.7 / 24.8 ms; GPU média 13.0 ms (p99 17.4); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.97 / 15.55 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 443 / 40 ms; 17.1 ms (3591 objetos · 1715 draw calls · 63843833 primitivas) |

## Fase 316 — capim pendendo na garganta (04/11/2026)

71,6 FPS (315: 71,4), 1% low 37,2, p50/p95/p99 13,2/17,7/24,8 ms, GPU 13,0 ms (315: 13,0), montar tudo 9,4 s, carregar 6,5 s,
construir com a ilha cheia 17,3 ms; ~7 mil primitivas a mais no quadro com tudo visível (a franja das gargantas). Neutra.

### 2026-11-04 18:51:50 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3001 / 1275 ms (22 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12447 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1084 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9466 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.42 / 2.76 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.2 ms (limite 50 ms): comando e vistas 17.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.3 / 16.3 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.53 ms |
| salvar | 82 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6598 ms |
| quadro com tudo visível | 13 ms (77 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20802060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 305 quadros, 1448 ms; 1398 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.7 / 38.4 / 29.0 FPS / 42 ms em 4366 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.1 / 17.4 / 24.0 ms; GPU média 12.8 ms (p99 17.0); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.94 / 15.33 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 436 / 39 ms; 16.9 ms (3591 objetos · 1715 draw calls · 64202233 primitivas) |

## Fase 317 — blocos no pé da garganta (04/11/2026)

72,7 FPS (316: 71,6), 1% low 38,4, p50/p95/p99 13,1/17,4/24,0 ms, GPU 12,8 ms (316: 13,0), montar tudo 9,5 s, carregar 6,6 s,
construir com a ilha cheia 17,2 ms; ~360 mil primitivas a mais no quadro com tudo visível (os blocos). Neutra.

### 2026-11-04 18:57:06 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2984 / 1278 ms (20 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12409 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1088 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9386 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.49 / 2.79 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.3 / 18.1 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.54 ms |
| salvar | 85 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6463 ms |
| quadro com tudo visível | 13 ms (78 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20802060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 319 quadros, 1438 ms; 1385 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.30 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.8 / 38.7 / 32.4 FPS / 36 ms em 4310 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.6 / 24.3 ms; GPU média 13.0 ms (p99 17.2); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.96 / 15.71 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 452 / 40 ms; 17.4 ms (3591 objetos · 1715 draw calls · 64201513 primitivas) |

## Fase 318 — espuma nas pedras do rio (04/11/2026)

71,8 FPS (317: 72,7), 1% low 38,7, p50/p95/p99 13,2/17,6/24,3 ms, GPU 13,0 ms (317: 12,8), carregar 6,5 s, construir com a ilha cheia
17,3 ms; objetos, draw calls e primitivas iguais. Neutra (a conta nova só roda no canal).

### 2026-11-04 19:00:46 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2988 / 1254 ms (21 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12343 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1084 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9409 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.46 / 2.73 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.32 · população 0.28 · necessidades 0.10 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.2 ms (limite 50 ms): comando e vistas 17.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.2 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.3 / 16.8 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.57 ms |
| salvar | 86 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6534 ms |
| quadro com tudo visível | 13 ms (77 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20802060 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1903 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 316 quadros, 1459 ms; 1416 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 72.3 / 38.3 / 33.0 FPS / 31 ms em 4341 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.1 / 17.4 / 24.2 ms; GPU média 12.9 ms (p99 17.0); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.97 / 15.15 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 438 / 39 ms; 16.9 ms (3591 objetos · 1715 draw calls · 64201513 primitivas) |

## Fase 319 — correnteza (04/11/2026)

72,3 FPS (318: 71,8), 1% low 38,3, p50/p95/p99 13,1/17,4/24,2 ms, GPU 12,9 ms (318: 13,0), carregar 6,5 s; objetos, draw calls e
primitivas iguais. Neutra (quatro leituras a mais do mapa da costa, só no canal).

### 2026-11-05 00:30:46 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3022 / 1265 ms (54 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 32526 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1097 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 12787 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.46 / 2.74 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.3 ms (limite 50 ms): comando e vistas 17.3 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.8 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.0 / 16.7 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.53 ms |
| salvar | 80 ms (53 KB) |
| carregar (inclui refazer as vistas) | 13647 ms |
| quadro com tudo visível | 27 ms (38 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3424 · 1676 · 20887084 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 313 quadros, 1455 ms; 1385 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.31 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 31.0 / 19.9 / 9.2 FPS / 109 ms em 1863 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 32.2 / 41.2 / 44.1 ms; GPU média 26.9 ms (p99 38.2); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.30 / 2.02 / 15.41 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 441 / 40 ms; 39.4 ms (3560 objetos · 1709 draw calls · 64287083 primitivas) |

## Fase 320 — franja em tufos (05/11/2026)

31,0 FPS, 1% low 19,9, p50/p95/p99 32,2/41,2/44,1 ms, GPU 26,9 ms; primitivas +85 mil (20,80 → 20,89 milhões: os tufos têm 192 triângulos
por pedaço, a franja da 312 tinha 66). **A máquina estava mais lenta nesta rodada** (o jogo novo levou 32 s, contra 12 na 319): o código
da 319 medido logo antes, nas mesmas condições, deu 30,9 FPS e GPU 26,7 ms. Neutra.

### 2026-11-05 06:56:14 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2798 / 1194 ms (16 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 32187 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1105 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 12530 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.41 / 2.77 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.6 ms (limite 50 ms): comando e vistas 17.6 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.9 · serviços 3.8 · módulos, poluição e beleza 0.1 · armazéns 3.2 · produção 2.9 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.5 / 16.9 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.52 ms |
| salvar | 83 ms (53 KB) |
| carregar (inclui refazer as vistas) | 13570 ms |
| quadro com tudo visível | 27 ms (37 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3424 · 1676 · 20887084 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 311 quadros, 1443 ms; 1398 rotas, 0.67 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.27 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 31.3 / 19.6 / 6.9 FPS / 145 ms em 1877 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 31.8 / 41.4 / 43.9 ms; GPU média 26.7 ms (p99 38.0); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.30 / 2.06 / 15.21 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 435 / 40 ms; 39.1 ms (3560 objetos · 1709 draw calls · 64287083 primitivas) |

## Fase 321 — crista sem risco (05/11/2026)

31,3 FPS (320: 31,0), 1% low 19,6, p50/p95/p99 31,8/41,4/43,9 ms, GPU 26,7 ms (320: 26,9); objetos, draw calls e primitivas iguais.
Máquina ainda na condição lenta da 320 (jogo novo em 32 s). Neutra (uma mistura a mais só na faixa da beira).

### 2026-11-05 07:05:10 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2794 / 1200 ms (16 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 31963 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1101 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 12537 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.47 / 2.73 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.7 ms (limite 50 ms): comando e vistas 17.7 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.9 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.4 / 16.7 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.55 ms |
| salvar | 82 ms (53 KB) |
| carregar (inclui refazer as vistas) | 14762 ms |
| quadro com tudo visível | 27 ms (37 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3424 · 1676 · 20887084 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1905 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 328 quadros, 1448 ms; 1382 rotas, 0.68 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.32 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 30.9 / 17.1 / 7.6 FPS / 131 ms em 1854 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 32.2 / 41.4 / 44.5 ms; GPU média 27.1 ms (p99 38.3); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.31 / 2.02 / 15.29 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 440 / 39 ms; 40.1 ms (3560 objetos · 1709 draw calls · 64287083 primitivas) |

## Fase 322 — parede sem esticado (05/11/2026)

30,9 FPS (321: 31,3), 1% low 17,1, p50/p95/p99 32,2/41,4/44,5 ms, GPU 27,1 ms (321: 26,7); objetos, draw calls e primitivas iguais.
Máquina ainda na condição lenta. Neutra (dentro do ruído: duas derivadas e uma mistura por pixel de terreno).

### 2026-11-05 07:18:24 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2836 / 1201 ms (15 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 32963 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1102 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 12519 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.43 / 2.69 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.0 ms (limite 50 ms): comando e vistas 17.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.2 · produção 2.7 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 15.9 / 16.4 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.54 ms |
| salvar | 82 ms (53 KB) |
| carregar (inclui refazer as vistas) | 13430 ms |
| quadro com tudo visível | 27 ms (37 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3424 · 1676 · 20887084 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1902 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 311 quadros, 1435 ms; 1399 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.31 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 31.1 / 18.1 / 6.5 FPS / 154 ms em 1864 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 32.2 / 41.2 / 43.8 ms; GPU média 26.8 ms (p99 37.7); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.31 / 2.08 / 15.49 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 437 / 39 ms; 38.6 ms (3561 objetos · 1710 draw calls · 64286395 primitivas) |

## Fase 324 — fundo na sombra (05/11/2026)

31,1 FPS (322: 30,9), 1% low 18,1, p50/p95/p99 32,2/41,2/43,8 ms, GPU 26,8 ms (322: 27,1); objetos, draw calls e primitivas iguais.
Máquina ainda na condição lenta. Neutra (24 leituras da altura da terra só nos pixels do canal).

### 2026-11-05 17:52:20 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2808 / 1183 ms (20 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12345 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1093 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9456 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.34 / 1.45 / 2.76 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.4 ms (limite 50 ms): comando e vistas 17.4 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.5 / 16.7 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.54 ms |
| salvar | 83 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6358 ms |
| quadro com tudo visível | 13 ms (78 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20887488 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 313 quadros, 1407 ms; 1394 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.32 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.2 / 36.9 / 27.3 FPS / 58 ms em 4272 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.3 / 17.8 / 25.2 ms; GPU média 13.1 ms (p99 17.4); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 1.99 / 14.58 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 435 / 40 ms; 17.1 ms (3591 objetos · 1714 draw calls · 64306093 primitivas) |

## Fase 325 — prado sem xadrez (05/11/2026)

71,2 FPS, 1% low 36,9, p50/p95/p99 13,3/17,8/25,2 ms, GPU 13,1 ms (319: 12,8 a 13,0, na máquina livre); objetos, draw calls e
primitivas iguais. A máquina voltou à condição normal (as Fases 320 a 324 mediram ~31 FPS com ela lenta). Neutra (quatro gradientes
e um ruído de valor a mais por pixel de grama).

### 2026-11-05 19:14:08 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 2793 / 1206 ms (27 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12330 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1108 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9515 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.45 / 2.79 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.2 ms (limite 50 ms): comando e vistas 17.2 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.7 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.2 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.2 / 16.5 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.55 ms |
| salvar | 89 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6425 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20887488 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1901 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 314 quadros, 1423 ms; 1403 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.30 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.1 / 37.6 / 33.6 FPS / 30 ms em 4264 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.3 / 17.9 / 25.2 ms; GPU média 13.1 ms (p99 17.6); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 1.99 / 14.91 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 441 / 40 ms; 17.3 ms (3591 objetos · 1714 draw calls · 64305373 primitivas) |

**Fase 326 (mata no tom).** 71,1 FPS, 1% low 37,6, p50/p95/p99 13,3/17,9/25,2 ms, GPU 13,1 ms (325: 71,2 FPS, GPU 13,1 ms).
Neutra: só constantes de cor.

### 2026-11-06 19:28:21 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 5408 / 1890 ms (57 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 22420 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1085 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 11632 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.51 / 2.75 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.29 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.4 ms (limite 50 ms): comando e vistas 17.4 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.9 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.8 / 16.5 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.55 ms |
| salvar | 89 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6298 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20887488 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 294 quadros, 1403 ms; 1381 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.32 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 65.6 / 28.0 / 19.0 FPS / 59 ms em 3937 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.7 / 22.8 / 30.0 ms; GPU média 13.1 ms (p99 17.2); CPU do render média 2.0 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.17 / 2.84 / 14.84 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 95 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 586 / 47 ms; 17.8 ms (3590 objetos · 1714 draw calls · 64286909 primitivas) |

### 2026-11-06 19:30:29 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3021 / 1226 ms (35 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12439 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1083 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9505 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.32 / 1.49 / 2.73 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 16.9 ms (limite 50 ms): comando e vistas 16.9 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.6 · serviços 3.7 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 15.8 / 16.2 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.51 ms |
| salvar | 81 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6284 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20887488 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 310 quadros, 1400 ms; 1384 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.29 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 71.6 / 37.5 / 29.2 FPS / 44 ms em 4296 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.2 / 17.6 / 24.8 ms; GPU média 13.1 ms (p99 17.2); CPU do render média 1.6 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.13 / 1.98 / 15.06 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 442 / 40 ms; 17.1 ms (3591 objetos · 1715 draw calls · 64286941 primitivas) |

**Fase 327 (copa sem bolhas).** 71,6 FPS, 1% low 37,5, p50/p95/p99 13,2/17,6/24,8 ms, GPU 13,1 ms (326: 71,1 FPS, GPU 13,1 ms). A
primeira rodada (65,6 FPS, GPU 13,1 ms) pegou a máquina na condição lenta (gerar o arquipélago em série levou 5,4 s em vez de ~2,8):
vale a segunda. Neutra: só a cor e a normal dos vértices das copas.

### 2026-11-06 20:08:51 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3024 / 1207 ms (32 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12323 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1093 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 9425 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.33 / 1.84 / 2.77 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.41 · produção 0.32 · população 0.28 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · estaleiro 0.02 · eventos, encomendas, jornal e especialistas 0.01 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 17.1 ms (limite 50 ms): comando e vistas 17.1 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.5 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.3 · produção 2.8 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 16.1 / 16.4 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.52 ms |
| salvar | 87 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6463 ms |
| quadro com tudo visível | 13 ms (76 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20887488 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 311 quadros, 1412 ms; 1382 rotas, 0.66 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.28 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 70.2 / 36.2 / 30.9 FPS / 37 ms em 4211 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 13.3 / 18.5 / 25.6 ms; GPU média 13.2 ms (p99 18.1); CPU do render média 1.7 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.14 / 2.03 / 14.91 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 96 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 508 / 48 ms; 72.3 ms (3561 objetos · 1710 draw calls · 64286395 primitivas) |

**Fase 328 (capim rente).** 70,2 FPS, 1% low 36,2, p50/p95/p99 13,3/18,5/25,6 ms, GPU 13,2 ms (327: 71,6 FPS, GPU 13,1 ms). O trajeto
passa quase só pela vila; sobre o prado aberto (`tools/grass_cost.tscn`) o tapete custa +0,61/+0,69/+0,80 ms a 30/60/110 m (antes
+0,48/+0,38/+0,41), com 56 mil tufos em vez de 32 mil.

### 2026-11-07 12:20:44 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3173 / 1367 ms (18 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 13147 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1357 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15417 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.37 / 1.66 / 2.92 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.31 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · eventos, encomendas, jornal e especialistas 0.02 · estaleiro 0.02 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.7 ms (limite 50 ms): comando e vistas 18.7 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.9 · serviços 4.0 · módulos, poluição e beleza 0.1 · armazéns 3.4 · produção 2.9 · grupos de casas 0.5 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 18.1 / 17.3 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.74 ms |
| salvar | 91 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6958 ms |
| quadro com tudo visível | 15 ms (68 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3438 · 1678 · 20656336 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1905 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 340 quadros, 1623 ms; 1387 rotas, 0.77 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.35 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 63.5 / 33.8 / 28.6 FPS / 36 ms em 3809 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 15.0 / 20.0 / 27.5 ms; GPU média 14.6 ms (p99 19.4); CPU do render média 1.9 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 2.19 / 14.99 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 8 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 498 / 47 ms; 19.5 ms (3590 objetos · 1714 draw calls · 64056349 primitivas) |

**Fase 329 (praia em curva).** 63,5 FPS, 1% low 33,8, p50/p95/p99 15,0/20,0/27,5 ms, GPU 14,6 ms; carregar 6.958 ms. A máquina estava no
estado lento: o A/B no worktree no commit da Fase 328, logo depois, deu 61,6 FPS, GPU 15,1 ms e carregar 6.878 ms. O quadro empata (as
malhas têm os mesmos vértices); o carregar sobe ~80 ms com a rampa da praia (~134 ms medidos à parte nas oito ilhas).

### 2026-11-07 13:45:09 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3120 / 1287 ms (17 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12866 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1344 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15292 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.38 / 1.58 / 2.83 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.31 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · eventos, encomendas, jornal e especialistas 0.02 · estaleiro 0.02 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.7 ms (limite 50 ms): comando e vistas 18.7 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.9 · serviços 3.8 · módulos, poluição e beleza 0.0 · armazéns 3.5 · produção 2.9 · grupos de casas 0.7 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 18.7 / 17.6 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.68 ms |
| salvar | 89 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6893 ms |
| quadro com tudo visível | 14 ms (70 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3201 · 1562 · 19337174 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 353 quadros, 1596 ms; 1436 rotas, 0.74 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.31 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 63.9 / 33.4 / 26.2 FPS / 40 ms em 3836 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 15.0 / 19.8 / 27.7 ms; GPU média 14.5 ms (p99 19.3); CPU do render média 1.9 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 2.10 / 16.06 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 9 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 506 / 47 ms; 18.9 ms (3324 objetos · 1599 draw calls · 62702909 primitivas) |

**Fase 330 (sombra funda).** 63,9 FPS, 1% low 33,4, p50/p95/p99 15,0/19,8/27,7 ms, GPU 14,5 ms; carregar 6.893 ms (329, na mesma
sessão: 63,5 FPS, GPU 14,6 ms). As sombras são as mesmas de antes, só que agora à vista: o custo não muda.

### 2026-11-07 14:03:52 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3104 / 1349 ms (17 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12932 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1348 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15271 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.40 / 1.89 / 2.79 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.32 · necessidades 0.11 · riscos 0.05 · navios 0.05 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · eventos, encomendas, jornal e especialistas 0.02 · estaleiro 0.02 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 19.0 ms (limite 50 ms): comando e vistas 19.0 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 4.0 · serviços 4.0 · módulos, poluição e beleza 0.1 · armazéns 3.3 · produção 2.9 · grupos de casas 0.6 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 18.4 / 17.5 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.19 / 1.65 ms |
| salvar | 95 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6875 ms |
| quadro com tudo visível | 14 ms (70 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3201 · 1562 · 19337174 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1903 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 336 quadros, 1568 ms; 1383 rotas, 0.75 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.35 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 63.4 / 34.1 / 28.2 FPS / 38 ms em 3804 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 15.1 / 19.9 / 27.2 ms; GPU média 14.7 ms (p99 19.4); CPU do render média 1.8 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 2.09 / 15.38 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 9 / 47 / 0 / 98 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 485 / 47 ms; 19.0 ms (3324 objetos · 1599 draw calls · 62702909 primitivas) |

**Fase 334 (prado fundo).** 63,4 FPS, 1% low 34,1, p50/p95/p99 15,1/19,9/27,2 ms, GPU 14,7 ms; carregar 6.875 ms (330 na mesma sessão:
63,9 FPS, GPU 14,5 ms). As Fases 331 a 333 só mudaram números de cor e da neblina que já se desenhava, sem medida à parte.

### 2026-11-07 14:23:37 — AMD Ryzen 7 5700X 8-Core Processor

| Medida | Resultado |
|---|---|
| limite de quadros | 0 FPS (sem limite) |
| nível gráfico | Alta (nuvens volumétricas desligadas) |
| placa e driver | NVIDIA GeForce RTX 5060 · vulkan · (1920, 1080) · VSync ligado |
| gerar o arquipélago: em série / em threads (pior quadro durante) | 3104 / 1326 ms (17 ms; 8 ilhas, 16 núcleos) |
| jogo novo: arquipélago, terreno, água e árvores | 12851 ms (semente 1840, 19236 árvores desenhadas) |
| frota | 10 navios em 7 rotas, o inicial e o do comerciante; entrepostos nas colônias, carta náutica e navios: 1346 ms |
| carga | 10000 moradores em 600 casas; 200 prédios de produção (200 carroças), 14 armazéns, 20 mercados |
| montar tudo (comandos + eventos + vistas) | 15320 ms |
| carroças na rua depois de 2 min | 123 de 200 |
| navios navegando depois de 2 min | 5 de 10 em rota |
| tick de simulação (média / 95% / pior) | 1.38 / 1.63 / 2.86 ms (orçamento 4.0 ms) |
| tick por etapa (ms, da mais pesada) | logística 0.42 · produção 0.33 · população 0.31 · necessidades 0.11 · riscos 0.05 · navios 0.04 · força de trabalho 0.03 · marcos, metas e vitória 0.03 · eventos, encomendas, jornal e especialistas 0.02 · estaleiro 0.02 · combate 0.01 · rivais 0.01 · economia 0.00 · estatísticas 0.00 · estado derivado 0.00 |
| construir um prédio com a ilha cheia | 18.5 ms (limite 50 ms): comando e vistas 18.5 · recálculo 0.0 |
| recálculo por etapa (ms) | prédios 3.9 · serviços 3.8 · módulos, poluição e beleza 0.1 · armazéns 3.3 · produção 2.9 · grupos de casas 0.6 |
| obra pelo histórico e o desfazer dela (ilha cheia) | 18.1 / 17.6 ms (ok) |
| dica que decompõe (um bem, todas as ilhas / o dinheiro) | 0.18 / 1.65 ms |
| salvar | 91 ms (53 KB) |
| carregar (inclui refazer as vistas) | 6956 ms |
| quadro com tudo visível | 14 ms (71 FPS) — NVIDIA GeForce RTX 5060 |
| objetos, draw calls e primitivas no quadro com tudo visível | 3206 · 1567 · 19387574 |
| pipelines compiladas montando e desenhando a cidade (desenho / superfície / malha / especialização) | 0 / 4 / 0 / 26 (primeira vez atrás da cortina: ligada) |
| pedestres | 2000 na multidão, 1900 na rua (teto 2000); 22009 janelas |
| multidão saindo de casa (rotas novas) | 342 quadros, 1573 ms; 1392 rotas, 0.75 ms cada |
| multidão na CPU depois de sair (rotina + instâncias) | 0.34 ms por quadro |
| dia inteiro em 60 s a 1x, Alta, câmera a 40/120/300 m dando a volta (FPS médio / 1% low / 0,1% low / pior quadro) | 63.4 / 34.2 / 30.2 FPS / 35 ms em 3806 quadros (meta 60 FPS), a partir das 10:00 |
| quadro no Alta (p50 / p95 / p99) | 15.2 / 19.9 / 27.4 ms; GPU média 14.7 ms (p99 19.3); CPU do render média 1.8 ms |
| tick por quadro no Alta (média / p99 / pior) | 0.16 / 2.10 / 15.76 ms |
| pipelines compiladas no dia, Alta (desenho / superfície / malha / especialização) | 9 / 47 / 0 / 97 |
| calçar as ruas da cidade (todas / mais uma) e o quadro com tudo visível | 2812 células: 490 / 46 ms; 18.9 ms (3328 objetos · 1603 draw calls · 62702157 primitivas) |

**Fase 339 (mourões na estrada, e o roteiro das Fases 335 a 339).** 63,4 FPS, 1% low 34,2, p50/p95/p99 15,2/19,9/27,4 ms, GPU 14,7 ms;
carregar 6.956 ms (334 na mesma sessão: 63,4 FPS, GPU 14,7 ms). O cascalho, a rua larga, o capim da beira e as cercas não mudam o
quadro do trajeto.
