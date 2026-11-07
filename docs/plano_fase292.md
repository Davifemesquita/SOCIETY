# Plano da Fase 292 — Praia de seixos

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_290_294.md`. A costa das temperadas era praia de areia
dourada ou falésia. No Anno, há também a praia de seixos cinzentos junto das pedras, molhada na beira.

## O que entrou

- **`shaders/terrain.gdshader`**, depois da areia dourada e antes de a areia entrar no chão: `pebble_beach`, que a `TerrainView`
  liga nas temperadas.
- **Onde**:
  - na areia com rocha perto: a inclinação dos dados a `pebble_reach_m` (5 m) nos quatro lados;
  - nos trechos de seixos (o ruído de `pebble_stretch_m`, 70 m): nem toda costa de pedra;
  - com a borda contra a areia recortada.
- **Os seixos**:
  - cada um é uma célula de Voronoi de `pebble_size_m` (0,22 m), num tom próprio, com a junta escura entre eles;
  - a normal estufada sai do meio de cada pedra;
  - mais escuros e brilhantes até `pebble_wet_m` (0,9 m) acima da água;
  - o hash é o inteiro dos estratos (Fase 290), porque o `fract(p * 123,34)` perde precisão com as coordenadas do arquipélago.
- **A primeira versão**, a textura de rocha em escala menor, saía como uma mancha cinza lisa, sem cara de pedra.
- A lama da margem dos rios (Fase 283) sai da areia de antes dos seixos e não muda.
- **As pedrinhas do recheio**, que o roteiro previa, ficaram de fora: o recheio teria de repetir em GDScript o ruído do shader para
  achar as mesmas praias.

## Medida

GPU 12,6 ms (291: 12,5): a busca da rocha e o Voronoi só rodam na areia, e a busca de nove células só onde há seixo.

## Como testar

- `tests/world/test_phase292_pebble_beach.gd`:
  - os seixos no lugar da areia junto da rocha, depois da areia dourada e sem tocar na lama, escuros e brilhantes na beira;
  - a `TerrainView` ligando nas temperadas e não nas tropicais;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase290.tscn -- <pasta>` (a praia sob a falésia em `01_falesia_de_perto.png`).
