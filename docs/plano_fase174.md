# Plano da Fase 174 — Banco na porta

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_170_174.md` (laterita, lenha e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia) e do último ciclo deste pedido. Só apresentação: nada muda na simulação nem
no save.

## O que entrou

- **Onde** (`DoorBenchView.spot`): numa casa de camponeses a cada `BENCH_EVERY` pelo id, dentro do quintal cercado da frente
  (Fase 13), encostado na parede da frente do lado da porta que tem mais parede, `SIDE_M` ao lado dela (além dos vasos da Fase
  15) e `OUT_M` para fora, de costas para a parede. No lugar do modelo da casa (`BuildingView.model_place`).
- **O banco** (`bench_mesh`): o assento de tábua grossa sobre dois pés em cavalete e a travessa. Um MultiMesh
  (`GameScreen.door_bench_view`).

## Como testar

- `tests/world/test_phase174_door_benches.gd`: só as casas de camponeses do resto certo têm o banco, na fileira do quintal,
  virado para a rua e além dos vasos; operários não; o banco é baixo e cabe no quintal.
- Captura: `banco_na_porta.png` no `tools/capture_phase95.tscn`.
