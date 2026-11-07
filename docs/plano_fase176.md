# Plano da Fase 176 — Cegonha na chaminé

**Estado: feita em 31/10/2026**, do roteiro `docs/plano_fases_175_179.md` (espantalho, cegonha e vaga-lume, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`StorkView.has_nest`, `nest_place`): numa casa de camponeses ou operários (`TIERS`) a cada `STORK_EVERY` pelo id,
  nas ilhas temperadas, com chaminé: o pé do ninho no capitel (a boca de `BuildingKit.chimney_top` menos os potes), no lugar do
  modelo da casa (`BuildingView.model_place`), girado pelo id.
- **O ninho** (`nest_mesh`): o monte de gravetos mais largo em cima, o miolo afundado e os gravetos soltos saindo da borda; cobre
  os dois potes da chaminé.
- **A cegonha** (`stork_mesh`): ~1 m, corpo e pescoço brancos, asas dobradas brancas na frente e pretas atrás, bico comprido e
  pernas vermelhas; vira para um lado novo de tempos em tempos pela mesma conta das gaivotas do cais
  (`PerchedGullView.heading_at`), no tempo de jogo.
- **A chaminé com ninho não fumega**: o `ChimneySmokeView.chimney_world` pula a casa com ninho (o teste da Fase 100 procura uma
  casa sem ninho).
- Dois MultiMesh (`GameScreen.stork_view`), refeitos na obra, na demolição, na subida de classe e ao trocar de mundo.

## Como testar

- `tests/presentation/test_phase176_storks.gd`: só as casas de camponeses e operários do resto certo com chaminé; nenhuma nas
  dos artesãos; o ninho no capitel, acima do telhado; sem fumaça na chaminé com ninho; a cegonha vira com o tempo; as medidas.
- Captura: `tools/capture_phase176.tscn` (ilha plana, uma rua de camponeses e uma de operários; a câmera posta à mão no alto da
  chaminé, como na captura do gavião da Fase 121).
