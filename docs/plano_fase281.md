# Plano da Fase 281 — Rebentação fina

**Estado: feita em 02/11/2026**, a segunda do roteiro `docs/plano_fases_280_284.md`. A praia tinha uma faixa branca larga, de
~20 m, onde a rebentação devia ser uma linha. No Anno, a espuma é uma linha fina e quebrada colada na areia e nas pedras.

## O que entrou

- **A espuma por profundidade do Ocean (`SHORE_FOAM`) presa à linha d'água.**
  - A espuma sai da diferença de profundidade ao longo da vista. De cima e de lado ela fica pequena na praia rasa inteira, e a
    espuma cobria toda a parte rasa.
  - Agora ela só vale até `shore_line_m` (3 m) da linha d'água, pelo mapa da costa (`coast_at`).
  - Nas pedras e nos rochedos, que encostam na linha, a espuma continua colada nelas.
- **As bandas que chegam na praia (Fase 35)**:
  - viram linhas finas (`band_sharpness`, 0,93; era 0,8);
  - quebradas ao longo da costa pela textura da espuma;
  - a espuma da beira vai até metade de `shore_line_m`.

## Como testar

- `tests/world/test_phase281_thin_surf.gd`:
  - os uniformes novos no shader compilado (com tela);
  - o corte da espuma do Ocean pela distância à linha d'água, dentro do bloco `SHORE_FOAM`;
  - as bandas mais finas que as de antes e quebradas pela textura.
- Captura: `tools/capture_phase280.tscn -- <pasta>` (as vistas do ciclo do mar; a praia em `02_praia.png`).
