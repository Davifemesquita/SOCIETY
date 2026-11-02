# Plano da Fase 259 — Praia dourada

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_255_259.md` (cor viva, a pedido do dono). O roteiro previa o
"mar vivo", mas depois da Fase 255 (sem o véu de névoa e com a cor viva) o azul do mar aberto e o turquesa da costa já estavam
vivos; o que destoava na costa era a areia, cinza-taupe.

## O que entrou

- **Areia dourada** (`shaders/terrain.gdshader`, `sand_tint` (1; 0,82; 0,58) e `sand_tint_mix` 0,55): depois da graduação, a areia
  vai 55% para o dourado escalado à luminância do texel, como a grama da Fase 257; a graduação mais clara, de (1,3; 1,2; 1,0) para
  (1,5; 1,35; 1,1). Escolhida no `tools/color_lab.tscn` entre três tons (quente, dourado e claro).
- **A lama não muda** (`mud_base`): a lama da margem dos rios (Fase 19) e a laterita das tropicais (Fase 170) saíam da cor da
  areia; agora saem da areia com a graduação de antes.

## Como testar

- `tests/world/test_phase259_sand.gd`: os números no shader, o dourado depois da graduação e a lama com a areia de antes.
- Capturas: `tools/capture_phase255.tscn -- <pasta>`; o ciclo inteiro, antes e depois, em
  `F:\ferramentas\capturas\fase259\ciclo_antes_depois.png`.
