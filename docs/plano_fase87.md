# Plano da Fase 87 — Formas e vivas

**Estado: feita em 28/10/2026, a pedido do dono** ("pode fazer tudo", sobre o que a Fase 86 deixou: as vivas do povo
numa gravação, o rastro mais forte e foguetes de várias formas). Só apresentação: a simulação, o save e as assinaturas
não mudam.

## O que entrou

- **Formas do estouro** (`FestivalView.Shape`, `pick_shape`, `shape_burst`; pesos em `SHAPE_WEIGHTS`): bola (a de antes,
  peso 4), crisântemo (mais denso, passando de uma cor sorteada a outra, peso 2), salgueiro (dourado, `WILLOW_COLOR`,
  sai devagar, dura 3,4 s e cai como chuva, peso 2) e anel (as faíscas saem de um círculo num plano inclinado sorteado,
  peso 2). A mesma bomba é rearmada a cada estouro (quantidade, duração, força, queda, cores, forma de emissão), sem
  sobra da forma anterior. `burst_at` aceita a forma (as capturas usam) e `last_shape` guarda a última.
- **Fogos mais baixos** (`FIREWORK_HEIGHT_M`: de 28–42 m da Fase 65 para 14–22 m; `FIREWORK_SPREAD_M` 8 m para o lado):
  a captura mostrou que lá em cima o estouro ficava **acima da borda da tela** com a câmera olhando a cidade de cima —
  nenhuma captura das Fases 65 a 86 tinha mostrado um estouro. É a mudança de um número de uma fase anterior.
- **Rastro mais forte**: 140 faíscas (eram 90) que duram 1,3 s (0,9), mais claras.
- **Vivas do povo** (`FestivalSounds.CHEER_*`, `cheer_share`, `_swell_cheer`, `fade_cheer`, `cheer_level`): a gravação
  "Strong cheering - II - Short" do pacote *Free Crowd Cheering Sounds* de Gregor Quendel (OpenGameArt, **CC BY 4.0**,
  crédito no `CREDITS.md`; `assets/audio/sfx/crowd_cheer.mp3`, sem alteração — não há `ffmpeg` aqui para cortar) toca
  em laço num ponto da praça. A cada estouro com pelo menos `CHEER_MIN_PEOPLE` (3) reagindo, o nível sobe até
  `cheer_share` (cheio com 12) e cai `CHEER_FADE_PER_S` por segundo de jogo; caladas, começam num ponto sorteado da
  gravação. Para com o jogo parado.

## Números

- Constantes de apresentação e de som, não de jogo; a altura dos fogos é a única mudança num número de fase anterior.
- Benchmark: o mundo do benchmark não tem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase87_shapes_and_cheers.gd`: o sorteio segue os pesos; cada forma arma a bomba do seu jeito
  e a bola volta sem sobra do anel; um espetáculo de 60 estouros mostra as quatro; as vivas não sobem com menos de 3
  pessoas, sobem com a gente, não baixam com um estouro menor, não somem com o jogo parado e somem andando; a gravação
  está lá.
- `tests/presentation/test_phase85_burst_cheers.gd`: as vivas entram na fila com seis pessoas.
- Captura: `tools/capture_phase87.tscn -- <pasta>` (o foguete com o rastro e cada forma sozinha no céu:
  `forma_bola.png`, `forma_crisantemo.png`, `forma_salgueiro.png`, `forma_anel.png`; em `fase87.txt`, se cada estouro
  saiu e quantas vezes cada som tocou; em `F:\ferramentas\capturas\fase87`).
- **O som não foi ouvido** nesta máquina: falta o dono ouvir as vivas no jogo (e conferir que a gravação, de estádio,
  serve para uma festa de 1840).

## Fica de fora (proposta à espera do dono)

- Cortar a gravação num trecho (pede `ffmpeg`) e uma segunda faixa mais calma ("Soft cheering") para pouca gente.
- Cores por forma escolhidas pelo dono e o estouro de duas etapas (bomba que solta bombas menores).
