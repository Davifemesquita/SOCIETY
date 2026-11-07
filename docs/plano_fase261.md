# Plano da Fase 261 — Rocha cinza

**Estado: feita em 01/11/2026**, segunda do roteiro `docs/plano_fases_260_264.md` (cor viva II).

## O que entrou

- **Pedra cinza** (`shaders/sea_rock.gdshader`, `stone_grey` (0,95; 0,95; 1), `stone_grey_mix` 0,75, `stone_light` 1,5;
  `RockView.STONE_GREY`, `STONE_GREY_MIX`, `STONE_LIGHT`): a cor da textura (média (0,43; 0,36; 0,2), marrom) vezes o tom saía
  marrom-oliva; agora vai 75% para o cinza escalado à luminância e clareia 1,5 vez. Os rochedos, as rochas da falésia e os matacões
  do rio.
- **As pedras soltas no mesmo shader** (`RockView.material`, com `sea` desligado): as dos barrancos, das jazidas e do recheio eram
  um `StandardMaterial3D` e não levariam o cinza; agora são o shader da rocha do mar sem a faixa da maré (o limo, a crosta e a pedra
  molhada só com `sea` ligado).
- **Rocha do terreno** (`shaders/terrain.gdshader`, `rock_grey`, `rock_grey_mix`, `rock_light`, os mesmos números): as encostas e a
  face das falésias casam com as rochas encaixadas nelas.
- Escolhida no `tools/color_lab.tscn` entre três cinzas (meio, claro e um pouco quente).

## Como testar

- `tests/presentation/test_phase261_grey_rock.gd`: o cinza em toda pedra, a faixa da maré só na do mar e a mesma conta no terreno.
  Os testes das Fases 36, 57 e 184 passaram a esperar o shader da rocha nas pedras soltas.
- Capturas: `tools/capture_phase260.tscn -- <pasta>`; antes e depois em `F:\ferramentas\capturas\fase261\comparacao.png`.
