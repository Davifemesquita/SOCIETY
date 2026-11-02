# Plano da Fase 291 — Musgo nas saliências

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_290_294.md`. Com os estratos da Fase 290, a rocha ganhou
camadas, mas seguia toda cinza. No Anno, as saliências da rocha têm capim e musgo, mais no lado da sombra.

## O que entrou

- **`moss_amount`** no `shaders/rock_strata.gdshaderinc`, de 0 a 1, nos dois shaders da rocha.
  - Onde: as partes quase planas (pela normal, `moss_flat` de 0,35 a 0,7) e o ressalto de cima de cada camada dos estratos (a
    mesma conta da Fase 290). Nas faces de pé, só no ressalto.
  - Em manchas de `moss_patch_m` (2,2 m), até `moss_amount_max` (0,85).
  - Mais no lado da sombra: `moss_shade_dir`, o norte fixo (−Z). Com a direção do sol do dia, o musgo andaria ao longo das horas.
- **No terreno**, dentro do bloco da rocha, a cor vai para `moss_color` com o miúdo da textura da grama.
- **Nas pedras** (`sea_rock.gdshader`), com o miúdo da textura da rocha. Na pedra do mar, o musgo só fica acima da pedra molhada
  (`wet_top_m`): a maré o tira.

## Medida

GPU 12,5 ms, igual à Fase 290 medida na mesma tarde. Neutra.

## Como testar

- `tests/world/test_phase291_moss.gd`:
  - o musgo nos dois shaders (no terreno, dentro do bloco da rocha; na pedra do mar, acima da molhada);
  - nas partes planas e nos ressaltos, com o lado da sombra fixo (sem o sol);
  - os shaders compilando com os uniformes novos (com tela, a lista vazia falha).
- Captura: `tools/capture_phase290.tscn -- <pasta>` (a costa de pedra de lado e o barranco).
