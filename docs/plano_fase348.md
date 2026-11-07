# Plano da Fase 348 — Fendas escuras

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_345_349.md` (pedra grande). A face de rocha do Anno tem fendas
escuras verticais e sombras fundas entre os blocos.

## O que entrou

- **`crack_factor`** no `shaders/rock_strata.gdshaderinc`: planos verticais no mundo, cortes em x a cada `crack_spacing_m` (3,1 m) e em z
  a cada 1,3 vez isso, tortos por um ruído e interrompidos ao longo da altura (nem toda fenda corre a face inteira), finos de
  `crack_width_m` (7 cm) e escuros até `crack_dark` (0,5). Só nas faces de pé.
- **Sem depender da normal** para o lugar das linhas (a lição da Fase 310: a normal muda a cada faceta das pedras e o desenho saía em
  riscos): os planos do mundo cortam qualquer face numa linha vertical. A normal só diz se a face é de pé.
- Na rocha do terreno e nas pedras, depois dos blocos (Fase 310).

## Medida

Dois ruídos e duas linhas por pixel de rocha: medido no fim do roteiro. É um detalhe de perto.

## Como testar

- `tests/world/test_phase348_cracks.gd`: as linhas pelos cortes em x e z do mundo, sem a normal no lugar delas, depois dos blocos nos
  dois shaders, que compilam (com tela).
- Captura: `tools/capture_phase330.tscn -- <pasta>` (`03_mata_alta_de_perto`, a rocha no prado); antes em
  `F:\ferramentas\capturas\fase347\depois3\`, depois em `F:\ferramentas\capturas\fase348\depois\`.
