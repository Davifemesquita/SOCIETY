# Plano da Fase 260 — Hora dourada

**Estado: feita em 01/11/2026**, primeira do roteiro `docs/plano_fases_260_264.md` (cor viva II).

## O que entrou

- **Sol de horizonte em ouro claro** (`GameConfig.sun_horizon_color` (1; 0,8; 0,55), posto no domo do Sky3D pelo `SkyAdapter`):
  o do Sky3D, (0,98; 0,52; 0,29), deixava o chão do fim da tarde e da manhã cor de tijolo escuro (a luz ambiente segue a cor do
  sol).
- **Exposição pela altura do sol** (`GraphicsQuality.dusk_factor`, `follow_sun`, chamada a cada quadro pela `GameScreen` junto do
  `sun_direction`): com o sol no horizonte a exposição chega a 1 + `dusk_exposure_boost` (0,95) vezes a do dia e volta a ela com
  o sol a `dusk_sun_high` (0,45, o seno da elevação); abaixo do horizonte volta à da noite. Escolhida no `tools/color_lab.tscn`
  entre 1,75, 2,2 e 2,6 de exposição no sol baixo (o laboratório desliga o `follow_sun` com `GraphicsQuality.sun_exposure`).
- **Luz das folhas pela altura do sol** (`shaders/foliage.gdshader`): a luz própria da Fase 256 vai de nada no horizonte a cheia
  com o sol a 0,5 de altura; antes só apagava à noite, e a mata acesa brilhava sobre o chão escuro do fim da tarde.

## Como testar

- `tests/world/test_phase260_dusk.gd`: a exposição só sobe com o sol baixo e sem degrau, o ouro claro no domo e o quadro seguindo
  o sol; o `tests/world/test_phase256_canopy.gd` passou a esperar a luz das folhas pelo `sun_direction`.
- Capturas: `tools/capture_phase260.tscn -- <pasta>`; antes e depois em `F:\ferramentas\capturas\fase260\` (`comparacao.png`).
