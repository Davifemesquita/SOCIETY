# Plano da Fase 61 — Helicônias

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir"; era a proposta que ficou de fora da Fase 60: flores
tropicais no lugar das flores do campo). Só apresentação: a simulação, o terreno e as assinaturas não mudam; nada vai
no save.

## O que faltava

Depois da Fase 60 o recheio das ilhas tropicais já tinha bananeira e samambaia, mas as flores eram ainda as do campo
temperado (cinco hastinhas com bolinhas coloridas).

## O que entrou

- **Helicônia** no recheio (`ScatterView.Kind.HELICONIA`, gerada no código): quatro folhas em remo, em pé, e duas hastes
  de ~1,2 m com cinco brácteas vermelhas de ponta amarela em zigue-zague, acima das folhas (a helicônia-papagaio). Cor
  no vértice; a instância só varia o tom, como no arbusto; material da folhagem.
- Nas ilhas tropicais as flores do campo viram helicônia; as temperadas não mudam. O sorteio da ilha tropical gasta um
  número a menos por flor (sem a cor da instância): bananeiras e samambaias de lá mudam um pouco de lugar (389 → 384
  bananeiras na semente 1840).
- Na semente 1840: 612 helicônias e nenhuma flor do campo nas ilhas tropicais; 1463 flores do campo nas temperadas.

## Números

- Benchmark (alto, RTX 5060): neutro — mesmos draw calls, GPU 21,9 ms com a máquina no estado lento da Fase 60 (o
  commit da Fase 59 mediu 23,0 ms nesse estado; ver `docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase60_undergrowth.gd` (ganhou a Fase 61): a helicônia de pé, de 0,9 a 1,5 m, com o
  vermelho só acima de 0,4 m; nas ilhas tropicais helicônias e nenhuma flor do campo, nas temperadas o contrário.
- Capturas: `tools/capture_phase60.tscn -- <pasta> heliconia` (helicônias de perto; em `F:\ferramentas\capturas\fase61`).

## Fica de fora (proposta à espera do dono)

- Tornar o rochedo não construível; afinar a malha da falésia.
