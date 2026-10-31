# Plano da Fase 143 — Cerca de estacas

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_140_144.md` (toco, bote e boia, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingKit.Spec.picket`, na chave da forma): as casas de `TierDef.HouseTrim.NONE` (os operários) sem pátio
  na frente — a casa tropical com o alpendre da Fase 126 tem o guarda-corpo dele e fica sem.
- **A cerca** (`_front_picket`): nos mesmos trechos do gradil da Fase 114 (`front_railing_spans`, `front_railing_z`: a
  faixa entre a parede e a divisa da frente, com o vão da porta), duas travessas, uma estaca a cada `PICKET_STEP_M` com a
  ponta em pirâmide, `PICKET_M` de alto, e o mourão mais grosso nas pontas; tudo na célula do creme da lona
  (`UV_CANVAS`), que o shader do kit pinta de branco-creme com a trama, como madeira caiada.

## Como testar

- `tests/presentation/test_phase143_picket_fence.gd`: só os operários têm a cerca; ela muda a chave da forma e soma
  triângulos; os trechos deixam o vão da porta e ficam na faixa da frente.
- Captura: a rua dos operários do `tools/capture_phase95.tscn` (`rua_workers_a.png` e `cerca_de_estacas.png`).
