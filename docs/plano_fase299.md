# Plano da Fase 299 — Fundo à vista no raso

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_295_299.md`. No raso, o Society pintava a plataforma lisa
por cima de um fundo de areia lisa. No Anno, o fundo de areia e pedra aparece sob a água.

## O que entrou

- **`shaders/terrain.gdshader`**, no fundo do mar (o bloco `has_coast`), só nas temperadas: a `TerrainView` liga `seabed_detail`
  junto do cascalho e dos seixos. Até `seabed_detail_m` (26 m) da linha d'água o fundo ganha:
  - **ondulações da areia** paralelas à costa (`seabed_ripple_m`, 1,3 m), tortas por dois ruídos, com a crista clara, o vale
    escuro e a normal acompanhando;
  - **manchas de alga** (`seabed_weed_color`) a partir de 3 m da beira, pelo ruído de `seabed_patch_m`;
  - **pedrinhas escuras**: uma célula de 0,5 m em cada dez, pelo `strata_hash` inteiro da Fase 292.
- **`shaders/water.gdshader`**, só nas temperadas: até `clear_depth_m` (3,5 m de água ao longo da vista), a cor do raso e a da
  plataforma perdem até `clear_strength` (0,6) da cobertura, e o fundo aparece.
- **De cima**, as manchas e as pedras se leem; as ondulações ficam fracas (finas demais para a distância da câmera do jogo).

## Medida

GPU 12,6 ms (298: 12,6). Neutra.

## Como testar

- `tests/world/test_phase299_seabed.gd`:
  - as ondulações, as algas e as pedras no fundo, ligadas pela `TerrainView` só nas temperadas;
  - a água rasa mais clara;
  - os shaders compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase295.tscn -- <pasta>` (`02_praia.png`, `02b_praia_de_perto.png`).
