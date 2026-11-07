# Plano da Fase 340 — Leiras marcadas

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_340_344.md` (campos em faixa). No Anno o campo é um tapete de
fileiras escuras e claras bem marcadas, que se leem de cima; as nossas leiras (Fases 19, 40 e 262) saíam como um retalho de cor lisa.

## O plano

- **Arquivos**: `presentation/crop_view.gd` (a terra do campo e a largura da leira), o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: a cabeceira (a mesma terra) ficar escura demais.
- **Como testar**: o teste novo e os campos da captura do ciclo.

## O que entrou

- **A terra dos sulcos** (`FIELD_SOILS`, a terra do campo debaixo das leiras) ~0,7 vez a de antes.
- **A leira mais estreita**: `FURROW_FILL` 0,62 (era 0,7) da fileira, e o sulco escuro aparece mais entre elas.

## Medida

Só cor e largura: sem custo de quadro.

## Como testar

- `tests/world/test_phase340_marked_rows.gd`: a leira mais estreita, a terra escura e a leira cheia (trigo e batata) bem mais clara que a
  terra mais clara.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase337\depois\`, depois em
  `F:\ferramentas\capturas\fase340\depois\`.
