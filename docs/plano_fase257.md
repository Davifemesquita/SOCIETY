# Plano da Fase 257 — Grama viva

**Estado: feita em 01/11/2026**, terceira do roteiro `docs/plano_fases_255_259.md` (cor viva, a pedido do dono).

## O que entrou

- **Puxão para o verde** (`shaders/terrain.gdshader`, `grass_tint` (0,52; 1; 0,2) e `grass_tint_mix` 0,6): depois da graduação
  e da saturação, a cor da grama vai 60% para o verde-amarelado escalado à luminância do texel. O claro e o escuro da textura
  (as touceiras, as manchas secas, a macro-variação) ficam; o matiz deixa de ser o oliva-amarronzado da textura do Poly Haven.
- **Graduação** menos vermelha e menos amarela: `grass_grade` de (0,76; 1,12; 0,58) para (0,6; 1,12; 0,7), saturação de 1,45
  para 1,25 (a cor viva da Fase 255 satura por cima) e a grama seca das cristas de 0,3 para 0,15.
- Escolhida no `tools/color_lab.tscn` entre três verdes (meio, amarelado e frio): o amarelado é o do capim do Anno; o meio e o
  frio pareciam grama de campo de futebol à sombra.

## Como testar

- `tests/world/test_phase257_grass.gd`: os números no shader, o puxão depois da graduação e a conta que guarda a luminância.
- Capturas: `tools/capture_phase255.tscn -- <pasta>`; depois em `F:\ferramentas\capturas\fase257\depois` e o laboratório em
  `F:\ferramentas\capturas\fase257\lab`.
