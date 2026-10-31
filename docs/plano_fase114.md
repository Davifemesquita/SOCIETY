# Plano da Fase 114 — Gradil das casas ricas

**Estado: feita em 30/10/2026**, a última do roteiro `docs/plano_fases_110_114.md` (sol, trópico e avenida, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **O gradil** (`BuildingKit._front_railing`, `front_railing_spans`, `front_railing_z`): nas casas dos engenheiros (as de
  sacada, `HouseTrim.BALCONIES`), na faixa entre a parede da frente e a divisa do lote, uma grade de ferro de
  `FRONT_RAIL_M` (a `_railing` das sacadas, de balaústre fino e passo curto) dos dois lados do vão da porta, com os
  pilaretes nas pontas e uma lança no alto de cada balaústre. Não passa da divisa: a rua não é tocada.
- **Só os engenheiros**: o roteiro falava em engenheiros e investidores, mas a frente dos investidores já tem a sebe florida
  e as colunas do pórtico (Fase 13) nessa faixa, e o lote não tem espaço para as duas coisas.

## No caminho

- O teste da balaustrada (Fase 24) compara os triângulos do enfeite dos engenheiros com os dos investidores; passou a
  descontar os do gradil, que não é da sacada.

## Como testar

- `tests/presentation/test_phase114_front_railing.gd`: a casa dos engenheiros tem ferro baixo na frente, dentro do lote e
  fora do vão da porta; camponeses, operários e artesãos não; os trechos deixam a porta livre.
- Captura: `tools/capture_phase95.tscn` ganhou `gradil_de_perto.png`.
