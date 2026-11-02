# Plano da Fase 296 — Água picada de perto

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_295_299.md`. De perto, a água do Society só tinha as
ondas grandes do Ocean e o marulho da Fase 284, e o reflexo saía liso. A do Anno tem a ondulação miúda que quebra o reflexo.

## O que entrou

- **`shaders/water.gdshader`**, no começo do fragment, logo depois do marulho:
  - quatro trens de ondinhas de `chop_lengths_m` (2,7; 1,8; 1,15 e 0,75 m) cruzando em volta do vento, cada uma mais fraca, na
    velocidade das ondas de verdade (`sqrt(g·k)`), vezes `chop_speed`;
  - a fase de cada trem torcida por um ruído de 6 m (o do recife, sem seno): as cristas deixam de ser retas e paralelas;
  - só na normal (os vértices não mudam), antes do Fresnel e do brilho do sol, que seguem a normal nova;
  - forte até `chop_near_m` (35 m) da câmera e some até `chop_far_m` (90 m): de longe nada muda e não cintila; mais forte com o
    vento (`sea_whitecaps`).

## Medida

GPU 12,5 ms (295: 12,4). Neutra.

## Como testar

- `tests/world/test_phase296_chop.gd`:
  - o bloco depois do marulho e antes do Fresnel, com o ruído na fase, quatro trens e só na normal;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase295.tscn -- <pasta>` (`01b_falesia_de_perto.png` e `02b_praia_de_perto.png`).
