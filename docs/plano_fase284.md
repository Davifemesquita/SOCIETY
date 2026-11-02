# Plano da Fase 284 — Marulho

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_280_284.md`. As ondas da água são de porto (Fase 6), baixas
e curtas. De cima e de longe, o mar aberto do Society era uma chapa lisa. No Anno, a ondulação larga se lê de longe.

## O que entrou

- **`shaders/water.gdshader`, no começo do fragment**: três trens de ondas longas.
  - Comprimentos `swell_lengths_m` de 52, 33 e 21 m e inclinações `swell_slopes` de 0,09, 0,07 e 0,05.
  - O primeiro anda com o vento (`wind_direction`), e os outros dois a +0,55 e -0,8 rad dele.
  - A velocidade é `swell_speed` (0,6) da das ondas de água funda.
  - Mais fortes com o vento forte (`sea_whitecaps`, de 0,6 a 1,2).
- **Só na normal**: os vértices não mudam. Por estar antes do resto, o Fresnel, o reflexo do céu (as nuvens refletidas
  ondulando) e o brilho do sol (Fase 110) seguem a ondulação.
- **Onde ele some**:
  - perto da costa (de `swell_open_m` × 0,4 a `swell_open_m`, 40 m), então nunca no rio (o canal da Fase 283 fica a menos de
    10 m da terra);
  - o trem mais curto também de 500 a 900 m da câmera, para não cintilar.

## Como testar

- `tests/world/test_phase284_swell.gd`:
  - os uniformes no shader compilado (com tela);
  - a normal dobrada antes do Fresnel, longe da costa, com o vento e o trem curto sumindo de longe;
  - os trens mais longos que 15 m e suaves;
  - o começo dele além da largura de um canal.
- Captura: `tools/capture_phase280.tscn -- <pasta>` (a falésia e o mar de cima em `01_` e `03_`).
