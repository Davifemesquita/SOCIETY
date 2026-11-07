# Plano da Fase 343 — Restolho e fardos

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_340_344.md` (campos em faixa). No Anno o campo depois da colheita
fica de restolho claro, com fardos; no nosso, a colheita levava os sacos e o campo voltava à terra recém-lavrada na hora.

## O que entrou

- **O restolho** (`CropView.STUBBLE`, a palha cortada clara): nos `STUBBLE_STEPS` (4) primeiros degraus depois da colheita do cereal, a
  leira vai do restolho à cor de sempre (`furrow_color_at`), sem degrau. As outras culturas não têm restolho.
- **Os sacos ficam no campo**: no cereal, os sacos e caixotes da colheita (Fase 157) seguem no restolho e vão sendo levados até o degrau
  `STUBBLE_STEPS` (`left_after_harvest`); o restolho acaba antes de a colheita seguinte começar a aparecer (`HARVEST_FROM`).

## Medida

Só cor e as peças que já existiam: sem custo de quadro.

## Como testar

- `tests/world/test_phase343_stubble.gd`: o restolho no degrau 0 do cereal, sumindo sem degrau, nada nas outras culturas; os sacos
  todos no degrau 0 e nenhum no `STUBBLE_STEPS`, sempre diminuindo.
- Os testes dos campos (com tela): `test_crops`, Fases 157, 262 e 270.
- Captura: as do fim do roteiro (`docs/plano_fase344.md`).
