# Plano da Fase 309 — Névoa nos vales

**Estado: feita em 02/11/2026**, a última do roteiro `docs/plano_fases_305_309.md`. No Anno, de manhã, a névoa baixa fica presa
nos vales da mata; no Society, a neblina da manhã (Fase 9) era só a névoa de distância, igual em todo lugar.

## O que entrou

- **`ValleyMistView`** (`presentation/valley_mist_view.gd`, `GameScreen.valley_mist_view`):
  - `sites`: nas temperadas, numa rede a cada `STEP` (5) células, a terra mais baixa `VALLEY_M` (0,7 m) que a média de oito pontos a
    `RING_CELLS` (7) dela, com `FOREST_MIN` células de mata a até `FOREST_REACH` (o roteiro falava da curvatura dos dados do
    terreno; a comparação com a volta é a mesma ideia, sem depender da `TerrainView`);
  - `sheets`: duas camadas por lugar (`LAYERS`: a 1,2 m de 36 m e a 2,6 m de 26 m), planas e giradas pelo lugar, num MultiMesh;
  - `amount_at`: sobe de 4h a 5h30, cheia até 8h e some até 11h; num dia sem a neblina sorteada pelo `WeatherCycle`, a
    `PLAIN_DAY` (metade) da força. Escondida com a força abaixo de 1%.
- **`shaders/valley_mist.gdshader`**: sem luz e sem profundidade, a borda redonda e mole, o miolo rasgado por um ruído no mundo que
  anda com o vento, o pé esmaecido contra o chão e as árvores (a profundidade da tela, como o proximity fade) e perto da câmera.
- A primeira versão (opacidade 0,55, branca, camadas menores e a borda dura) parecia neve no chão; ficou acinzentada, mais rala,
  maior e de borda mole.

## Medida

71,8 FPS, GPU 12,9 ms (308: 12,9); um objeto e uma draw call a mais. Neutra.

## Como testar

- `tests/world/test_phase309_valley_mist.gd`: a força pela hora e pela neblina do dia; os lugares só nas temperadas, em terra com
  mata perto; duas camadas acima do chão; o shader compilando (com tela).
- Captura do ciclo: `tools/capture_phase305.tscn -- <pasta>` (`06_vale_de_manha.png` e `07_vale_de_manha_longe.png`, às 6h30); o antes
  e depois está em `F:\ferramentas\capturas\fase309\antes_depois2.png`.
