# Plano da Fase 280 — Mar fundo

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_280_284.md` (o mar e o rio). O mar inteiro saía
azul-elétrico, com o fundo em (0,05; 0,19; 0,42), e tinha um halo turquesa de 40 m em volta de cada ilha (0,24; 0,76; 0,72). No
Anno, o mar temperado é azul-petróleo escuro, e é ele que faz a terra verde saltar; o turquesa fica para os trópicos.

## O que entrou

- **`shaders/water.gdshader`**:
  - `cold_deep` (0,04; 0,18; 0,29), `cold_shelf` (0,19; 0,52; 0,53, força 0,52) e `cold_shelf_m` (25 m) no mar das ilhas
    temperadas;
  - nas tropicais seguem o `color_deep`, o `color_shelf` e o `shelf_m` que a `WaterView` põe desde a Fase 53;
  - a troca vai pela borda oeste das regiões tropicais (`reef_min_x`, a mesma do recife da Fase 125), gradual em
    `tropic_blend_m` (120 m centrados nela);
  - sem ilha tropical (`reef_min_x` em 1e9), o mar é todo temperado. A guarda evita o `smoothstep` com as duas pontas iguais
    em 1e9 na precisão de 32 bits.
- **A escolha**: entre quatro combinações lado a lado (`CAPTURA_MAR=lab` no `tools/capture_phase280.tscn`), a cor ficou entre a
  "petróleo" e a "fundo". As mais escuras, de azul acinzentado como o do Anno, perdiam a cor viva que o dono pediu nos ciclos
  da cor.

## Como testar

- `tests/world/test_phase280_deep_sea.gd`:
  - o shader com os uniformes novos (com tela), e o fundo e a plataforma das temperadas mais escuros que o turquesa, com a
    plataforma mais estreita;
  - a troca pela borda tropical, com a guarda.
- Sem tela, o renderer falso lista os uniformes mas não guarda os padrões: o teste para aí.
- Captura: `tools/capture_phase280.tscn -- <pasta>`, a captura do ciclo do mar e do rio. Mostra a falésia, a praia, o mar de
  cima, a praia tropical, o rio, e a falésia e o mar de cima à noite.
