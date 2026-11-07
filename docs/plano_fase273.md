# Plano da Fase 273 — Andorinhas no fio

**Estado: feita em 02/11/2026**, quarta do roteiro `docs/plano_fases_270_274.md` (corvo, dedaleira e girassol).

## O que entrou

- **`PowerLineView.rebuilt` e `spans`**: o sinal a cada desenho novo dos fios e as curvas deles.
- **`WireBirdView`** (`GameScreen.wire_bird_view`, com a `PowerLineView`): num vão a cada `SPAN_EVERY` (2), até `BIRDS_PER_SPAN` (5)
  andorinhas a `GAP_M` uma da outra, centradas no meio da curva do fio e no alto dele, de lado para ele (`perches`), cada uma olhando
  para um lado ou o outro pelo `PerchedGullView.heading_at`; somem de noite. `swallow_mesh` (em `SIZE` 1,4): as costas azul-escuras,
  a barriga branca, a garganta ferrugem, as asas compridas dobradas e a cauda em forquilha. Um MultiMesh sem sombra.
- A captura de perto põe a câmera à mão na altura do fio (a da partida fica presa ao chão).

## Como testar

- `tests/presentation/test_phase273_wire_birds.gd`: os pousos no meio do fio, de lado para ele, só nos vãos da vez; a vista seguindo
  os fios da `PowerLineView`; a andorinha de pé com o bico para a frente.
- Captura: `tools/capture_phase273.tscn -- <pasta>` (a rua com a usina; as andorinhas de perto e de lado).
