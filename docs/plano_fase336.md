# Plano da Fase 336 — Cascalho na estrada

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_335_339.md` (estrada no jeito do Anno). De perto, a estrada do
Anno tem cascalho e pedrinhas; a nossa tinha sulcos numa terra lisa.

## O plano

- **Arquivos**: `shaders/terrain.gdshader` (o bloco da estrada de terra), o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: cintilação de pontos menores que um pixel de longe; custo na GPU.
- **Como testar**: o teste novo (o bloco e a compilação com tela) e a vila de perto antes e depois.

## O que entrou

- **O cascalho**: células de Voronoi de `road_gravel_m` (9 cm) com o hash inteiro dos estratos (`strata_hash`: as coordenadas do
  arquipélago são grandes); `road_gravel_share` (30%) delas viram pedrinha cinza-clara (`road_gravel_color`, um tom por pedra), com a
  sombra em volta e a normal estufada. Mais no meio da estrada, um quarto nos sulcos, nenhuma na poça.
- **Só perto**: até `road_gravel_far_m` (70 m, sumindo de 42 m em diante); mais longe as pedras seriam menores que um pixel. O laço das
  nove células só roda nos pixels de estrada dentro dessa distância.

## Medida

Medida no benchmark do fim do roteiro (`docs/plano_fase339.md`).

## Como testar

- `tests/world/test_phase336_road_gravel.gd`: o cascalho no bloco da estrada, sem seno, menos nos sulcos, nada na poça, só perto, e o
  shader compilando com os uniformes (com tela).
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase335\depois\`, depois em
  `F:\ferramentas\capturas\fase336\depois\`.
