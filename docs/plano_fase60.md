# Plano da Fase 60 — Sub-bosque tropical

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir"; era a proposta que ficou de fora da Fase 59:
bananeira e samambaia na mata tropical). Só apresentação: a simulação, o terreno e as assinaturas não mudam; nada vai
no save.

## O que faltava

O recheio da Fase 41 (`ScatterView`) punha nas ilhas tropicais os mesmos arbustos redondos de folha temperada das
ilhas do norte, em volta da mata nova de coqueiros e folhosas tropicais.

## O que entrou

- Duas peças novas no recheio, geradas no código: **bananeira** (`Kind.BANANA`, pseudocaule de 1,5 m e seis folhas
  largas em remo, arqueadas, ~2,6 m, faz sombra) e **samambaia** (`Kind.FERN`, roseta de oito frondes recortadas rente
  ao chão, ~0,7 m). Material da folhagem (balançam), cor no vértice, tom sorteado como o do arbusto.
- Nas ilhas tropicais o arbusto vira bananeira (40%, `BANANA_SHARE`) ou samambaia; o sorteio a mais só acontece na
  ilha tropical, então o recheio das temperadas fica igual, peça por peça. O contexto da ilha
  (`ScatterView.island_context`) passa a dizer se ela é tropical.
- Na semente 1840: 389 bananeiras e 600 samambaias nas ilhas tropicais (nenhum arbusto); 2197 arbustos nas temperadas.

## Números

- Benchmark (alto, RTX 5060): neutro — mesmos draw calls e, na mesma hora, o mesmo tempo que o commit da Fase 59
  (GPU 22,8 e 23,0 ms; a máquina inteira estava ~2,5 vezes mais lenta nesta hora; ver `docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase60_undergrowth.gd`: as duas malhas de pé no chão e no tamanho; na semente 1840, as
  ilhas tropicais com bananeira e samambaia e sem arbusto, as temperadas com arbusto e sem planta tropical.
- `tests/world/test_phase41_scatter.gd` continua valendo (recheio determinístico, igual depois de carregar).
- Capturas: `tools/capture_phase60.tscn -- <pasta>` (bananeiras de perto numa ilha tropical; em
  `F:\ferramentas\capturas\fase60`).

## Fica de fora (proposta à espera do dono)

- Flores tropicais (helicônia) no lugar das flores do campo; tornar o rochedo não construível; afinar a malha da
  falésia.
