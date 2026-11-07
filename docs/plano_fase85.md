# Plano da Fase 85 — Palmas nos estouros

**Estado: feita em 28/10/2026, a pedido do dono** ("pode seguir"; o que a Fase 84 deixou de fora: palmas no ritmo dos
estouros e som de palmas e vivas junto dos fogos). Só apresentação: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **Cada estouro avisa** (`FestivalView.exploded(island_id, position)`): a `FestivalView` guarda a ilha de cada lugar de
  lançamento (`_launch_islands`) e avisa quando uma bomba estoura.
- **Palmas por estouro** (`Crowd.react_to_burst`, `_end_cheers`, `Agent.cheer_until`): quem está parado vendo a festa até
  `REACT_RADIUS_M` (30 m, no chão) do estouro, na parte `REACT_SHARE` (85%), reage depois de `REACT_DELAY_S` (0,15 a
  0,6 s): olha para o céu e bate palmas (a animação da Fase 84 começa na palma) por `CHEER_SECONDS` (1,6 a 2,6 s) e volta
  a olhar o mastro, parado. Quem já está batendo palmas não recomeça no estouro seguinte. Sem estouro, ninguém bate
  palmas — na Fase 84 80% batiam o tempo todo (`CHEER_SHARE` saiu).
- **Som gerado** (`audio/festival_sounds.gd`, `FestivalSounds`, montado pela `GameScreen`): nenhum arquivo, como o
  vento e a chuva. O estouro (`bang_stream`: baque grave descendo de tom, estalo e crepitar das faíscas) toca no ponto do
  céu e chega atrasado pela distância até a câmera (343 m/s); as palmas (`applause_stream`: batidas curtas de ruído em
  faixa, densas no começo) tocam na praça depois de `CLAP_DELAY_S`, de `CLAP_QUIET_DB` (uma pessoa) a `CLAP_FULL_DB`
  (`CLAP_FULL_PEOPLE` ou mais), só se alguém reagiu. Vozes 3D no barramento Effects (4 de estouro, 3 de palmas). Os dois
  sons são gerados uma vez por execução (~21 ms) e ficam em cache.
- **Vivas ficaram de fora**: voz sintetizada soa artificial; pedem gravação (proposta abaixo).

## Números

- Constantes de apresentação e de som, não de jogo.
- Benchmark: o mundo do benchmark não tem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase85_burst_cheers.gd`: o estouro faz bater palmas quem vê a festa (na palma, depois da
  reação, pelo tempo certo) e depois volta a olhar o mastro; estouro longe ou em outra ilha não mexe em ninguém; o
  estrondo e as palmas entram na fila e tocam (sem palmas quando ninguém reagiu), com o volume pela gente; os sons gerados
  têm corpo; a `FestivalView` avisa cada estouro com a ilha.
- `tests/presentation/test_phase84_cheer.gd`: sem estouro, quem vê a festa espera parado e ninguém bate palmas.
- Captura: `tools/capture_phase85.tscn -- <pasta>` (as fotos da 84 com quem bate palmas por um estouro; grava
  `estouro.wav` e `palmas.wav` para ouvir e, em `fase85.txt`, quantas vezes cada som tocou; em
  `F:\ferramentas\capturas\fase85`: 26 estouros e 14 palmas na partida da captura).
- **O som não foi ouvido** nesta máquina (a área escondida não tem quem ouça): falta o dono ouvir os dois `.wav` e o jogo.

## Fica de fora (proposta à espera do dono)

- Vivas e assobios: uma gravação CC0 de multidão ou de vozes, no lugar de voz gerada.
- O estouro com eco entre os prédios e o assobio da bomba subindo.
