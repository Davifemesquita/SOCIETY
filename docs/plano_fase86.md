# Plano da Fase 86 — Foguete e assobio

**Estado: feita em 28/10/2026, a pedido do dono** ("pode continuar"; da proposta da Fase 85, a parte que se gera no
código: o assobio da bomba subindo e o eco do estrondo; as vivas esperam uma gravação escolhida pelo dono). Só
apresentação: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **O fogo sobe como foguete** (`FestivalView.fire`, `advance_rockets`, `rocket_point`, classe `Rocket`): até a Fase 85 a
  bomba aparecia estourando direto no céu. Agora sai do alto do mastro e sobe até o ponto do estouro (o mesmo sorteio de
  antes, `FIREWORK_HEIGHT_M` acima e até 12 m para o lado) em `ROCKET_RISE_S` (0,9 a 1,4 s de jogo), rápido no começo e
  perdendo força no alto, balançando até `ROCKET_WOBBLE_M` para o lado; só lá em cima estoura (`burst_at`). A cabeça é um
  brilho de `ROCKET_GLOW_M` sempre de frente para a câmera (uma esfera de 24 cm sumia na distância da câmera da cidade) e
  o rastro, faíscas de `ROCKET_SPARK_M` que ficam no mundo e caem. No máximo `ROCKET_POOL` no ar; anda no tempo de jogo
  (para na pausa). `launch(site)` continua sendo o estouro imediato (captura da Fase 65 e testes).
- **A subida avisa** (`FestivalView.launched(ilha, de, até, segundos)`), para o som.
- **Assobio** (`FestivalSounds.whistle_stream`, `on_launch`, `_follow_flights`): tom que sobe de 900 a 2.600 Hz com um
  tremor e o chiado da pólvora, gerado no código; a voz 3D segue o foguete e cala no estouro, tocada mais depressa
  quanto mais rápida a subida (acaba junto); para com o jogo parado.
- **Eco** (`ECHO_DELAY_S`, `ECHO_DB`, `ECHO_PITCH`): o estrondo de novo, 0,45 s depois, 12 dB mais fraco e mais grave.

## Números

- Constantes de apresentação e de som, não de jogo.
- Benchmark: o mundo do benchmark não tem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase86_rockets.gd`: o foguete sai do mastro, está acima da metade no meio da subida e estoura
  onde ela acaba; a subida é rápida no começo e sempre para cima; sem foguete livre não há lançamento; o assobio segue o
  voo, acaba no estouro e não anda com o jogo parado; o assobio gerado tem corpo.
- `tests/presentation/test_phase85_burst_cheers.gd`: o eco entra na fila depois do estrondo.
- Captura: `tools/capture_phase86.tscn -- <pasta>` (para o jogo com um foguete no meio da subida, `foguete.png`; grava
  `estouro.wav`, `palmas.wav` e `assobio.wav`; em `F:\ferramentas\capturas\fase86`: 25 assobios, 24 estouros, 23 ecos e
  16 palmas na partida da captura).
- **O som não foi ouvido** nesta máquina: falta o dono ouvir o `assobio.wav` e o jogo.

## Fica de fora (proposta à espera do dono)

- Vivas e assobios do povo: uma gravação CC0 de multidão escolhida pelo dono.
- O rastro mais longo e brilhante (hoje é discreto de longe) e foguetes de várias cores e formas (chuva, crisântemo).
