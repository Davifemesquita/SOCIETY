# Plano da Fase 282 — Água de noite

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_280_284.md`. De noite, a plataforma de cada ilha
ficava ciano acesa e o mar fundo, azul vivo (`08_noite.png` do ciclo da cor). A cor da água sai pela `EMISSION` (o truque da
refração do Ocean do Boujie), e a emissão não recebe a luz da cena.

## O que entrou

- **`shaders/water.gdshader`**: `water_light`, que vai de 1 de dia a `night_water` (0,16; 0,2; 0,3) de noite.
  - É um fator por canal que puxa para o azul de lua. Fica sem o `source_color`: a conversão para linear o deixaria quase
    preto.
  - Vai pelo global `night_light` (o mesmo das janelas e dos postes, `DayClock.night_factor`).
  - Multiplica as cores postas: o raso (`color_shallow`), o fundo, a plataforma e o recife.
  - A tela lida por baixo, o fundo do mar refratado, já vem com a luz certa e não muda.
- A espuma e os carneirinhos são `ALBEDO` e recebem a luz da lua como o resto. O brilho do sol já apagava de noite (Fase 110).

## Como testar

- `tests/world/test_phase282_night_water.gd`:
  - o uniforme no shader compilado (com tela);
  - as quatro cores postas multiplicadas pelo `water_light`;
  - o fator de noite escuro e mais azul que vermelho.
- Captura: `tools/capture_phase280.tscn -- <pasta>`, com a falésia e o mar de cima à noite em `06_` e `07_`.
