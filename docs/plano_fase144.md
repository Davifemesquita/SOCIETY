# Plano da Fase 144 — Boias no porto

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_140_144.md` (toco, bote e boia, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`BuoyView.spots`): diante de cada entreposto, do lado do mar (`HarborView.seaward`), os pontos de `SPOTS` em
  pares — mar adentro, além do cais de pedra e da roda dos botes, e para cada lado —, só os que boiam
  (`HarborView.afloat`), até `BUOYS_PER_POST`. Quem chega do mar vem com a proa para a terra: a vermelha fica à esquerda
  dele (o +través) e a verde à direita.
- **A boia** (`buoy_mesh`): o casco em barril com as três faixas (a cor dela, o branco e a cor), a tampa em cone, a haste de
  ferro e a bola na cor dela no alto.
- **Balançando** (`pose`): afundada `DRAFT_M`, sobe e desce `BOB_M` e tomba até `ROCK` com as ondas, cada uma na sua fase,
  no tempo de jogo (para na pausa). Dois MultiMesh com a caixa fixa do arquipélago (`GameScreen.buoy_view`), refeitos na
  obra, na demolição e ao trocar de mundo.

## No caminho

- A primeira captura mostrou uma boia em cima do cais de pedra da Fase 106, que avança ~15 m mar adentro: os pontos
  foram para 32 e 46 m da beira do entreposto.

## Como testar

- `tests/world/test_phase144_buoys.gd`: as boias do entreposto boiam, ficam mar adentro e em pares, a vermelha no +través;
  a boia fica abaixo da linha d'água, sobe, desce e tomba; só o entreposto tem boias.
- Captura: `tools/capture_phase144.tscn` (semente 1840: um entreposto na costa da ilha principal; `boias.png` e
  `boia_de_perto.png`).
