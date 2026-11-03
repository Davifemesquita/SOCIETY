# Plano da Fase 308 — Abetos de longe

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_305_309.md`. No Anno, os abetos de longe ficam escuros e
azulados; no Society, tinham a mesma cor de perto e de longe.

## O que entrou

- **`shaders/foliage.gdshaderinc`**: `far_cool` e `far_cool_tint` (mais escuro e azulado); de `far_cool_from_m` (40 m) a
  `far_cool_to_m` (240 m) da câmera, a folhagem vai para o tom de longe, depois do tom por árvore da Fase 305. A primeira versão
  (de 70 a 320 m) quase não aparecia nas distâncias da câmera do jogo.
- **`TreeModel.far_cool_of`**: `CONIFER_FAR_COOL` no pinheiro e no abeto (perto e longe, e o abeto da rocha da Fase 294, que usa a
  malha dele); as folhosas, o coqueiro e as plantações ficam com 0.

## Medida

71,2 FPS, GPU 12,9 ms (307: 12,9). Neutra.

## Como testar

- `tests/presentation/test_phase308_far_conifers.gd`: só as coníferas com o escurecido; os dois shaders compilando com os uniformes
  novos (com tela).
- Captura do ciclo: `tools/capture_phase305.tscn -- <pasta>`; o antes e depois está em
  `F:\ferramentas\capturas\fase308\antes_depois2.png`.
