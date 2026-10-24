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
