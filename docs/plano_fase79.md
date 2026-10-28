# Plano da Fase 79 — O bicho vai beber

**Estado: feita em 28/10/2026, a pedido do dono** ("pode seguir"; proposta deixada de fora na Fase 77). Só
apresentação: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **O bicho vai ao bebedouro** (`PenWalk`): em cada escolha do passeio, com 30% de chance, ele tenta ir beber. Passa por
  um ponto de virar (o lugar onde está, um ponto bem na frente do bebedouro ou um sorteado), vira para o ponto de beber,
  anda até lá e vira de frente para o bebedouro (olhando para +Z), com o focinho a 15 cm da borda (`drink_spot`); bebe de
  6 a 10 s de jogo (`drinking`). Cada perna, cada um dos três giros e o ponto de beber são conferidos como o resto do
  passeio (a cerca e o bebedouro); sem caminho que caiba, o passeio segue normal.
- **Inclina para a frente bebendo** (`BuildingView`, `DRINK_TILT` 0,12 rad): o giro em volta do eixo de lado do próprio
  bicho (desfeito o giro com que a malha foi feita), com o pé no chão.
- **Sai de ré** (`PenWalk._back_up`): sem para onde virar nem andar (na frente do bebedouro o corpo comprido não vira),
  o bicho recua em linha reta até onde cabe. Antes disso, quem bebia uma vez ficava preso no bebedouro para sempre.
- **O bebedouro foi para o meio da cerca de trás** (`ExhibitModels.trough_center`; na Fase 77 ficava à direita): só no
  meio o leão e o tigre conseguem virar na frente dele e chegar de frente.

## Limite medido

- No cercado de 3,3 m por dentro, só o **leão e o tigre** (2,17 m) cabem de frente para o bebedouro. O elefante (2,38 m
  já reduzido), a girafa (2,38 m) e a manada de zebras não acham pose que caiba e não vão beber; as araras não andam.
- Em 20 sementes e 10 minutos de jogo, o leão bebeu em 14 e o tigre em 17, de 1 a 8% do tempo, várias vezes; nas outras
  sementes, nenhuma vez nesse tempo.

## Números

- Benchmark: o mundo do benchmark não tem zoológico; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase79_drinking.gd`: dez minutos de passeio de cada bicho sem tocar a cerca nem o bebedouro;
  bebendo, de frente para ele, no meio dele e com o focinho a `DRINK_GAP_M`; bebe mais que `DRINK_MIN_S` e não o tempo
  todo; o leão e o tigre vão beber; sem bebedouro, ninguém bebe; no `BuildingView`, a cabeça do leão desce bebendo e
  fica no nível andando, com a escala do cercado.
- Capturas: `tools/capture_phase79.tscn -- <pasta>` (o passeio anda até o leão e o tigre estarem bebendo, de perto; em
  `F:\ferramentas\capturas\fase79`).

## Fica de fora (proposta à espera do dono)

- Cercado maior (ou bebedouro mais largo, encostado no lado comprido) para o elefante, a girafa e as zebras beberem;
  a cabeça descendo sozinha em vez do corpo inteiro; o nível da água baixando.
