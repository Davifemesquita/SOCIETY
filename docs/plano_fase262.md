# Plano da Fase 262 — Campos coloridos

**Estado: feita em 01/11/2026**, terceira do roteiro `docs/plano_fases_260_264.md` (cor viva II).

## O que entrou

- **Cobertura da planta nas leiras** (`CropView.furrow_color_at`, `COVER_MAX` 0,7, `CEREAL_GREEN`, `CEREAL_GOLD`, `CROP_COVER`): a
  cor das leiras de cada campo, que ia só da terra úmida à seca com o ciclo da fazenda, passa a levar a cor da plantação por cima
  (a folhagem rasteira entre as plantas), até 70% no degrau cheio. O trigo vai do verde ao dourado, a batata, o lúpulo, a vinha,
  a cana, o café e o tabaco no verde de cada um. De longe cada campo vira um retalho da cor da planta, como no Anno, em vez de um
  quadrado de terra. As leiras já mudavam de cor por instância a cada degrau: nada novo a refazer.
- Escolhida no `tools/color_lab.tscn` (as fazendas da vila postas em fases diferentes do ciclo) entre 0,5, 0,7 e 0,85.

## Como testar

- `tests/presentation/test_phase262_field_cover.gd`: a cor sobe com o degrau, o cereal do verde ao dourado e toda planta com
  cobertura verde. O `tests/presentation/test_crops.gd` passou a esperar as leiras cobertas no degrau cheio.
- Capturas: `tools/capture_phase260.tscn -- <pasta>`; depois em `F:\ferramentas\capturas\fase262\depois` e o laboratório em
  `F:\ferramentas\capturas\fase262\lab`.
