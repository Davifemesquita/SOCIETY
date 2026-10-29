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
