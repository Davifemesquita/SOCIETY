# Plano da Fase 263 — Noite azul

**Estado: feita em 01/11/2026**, quarta do roteiro `docs/plano_fases_260_264.md` (cor viva II).

## O que entrou

- **Exposição da noite** (`GameConfig.night_exposure_boost` 0,45, no `GraphicsQuality.dusk_factor`): com o sol abaixo do horizonte
  a exposição fica em 1,45 vez a do dia, passando sem degrau da do fim da tarde (1,95) para ela. A noite ficava quase preta fora
  das janelas e dos lampiões; agora as ruas, os telhados e a mata se leem no azul da lua, e as luzes seguem mais claras que o resto.
  Escolhida no `tools/color_lab.tscn` entre 1,6 e 2,2 de exposição, e com a lua mais forte (quase igual: a lua não entrou).
- **O laboratório só mexe no que as variantes mexem**: antes ele repunha a luz do sol e do ambiente do começo (de dia) em toda
  variante, e a noite saía clara como o dia; também desligava a saturação da cor viva.
- **A captura espera a luz da noite** (`tools/capture_phase260.tscn`): o Sky3D passa a luz ambiente do dia para a da noite em 3 s.

## Como testar

- `tests/world/test_phase263_night.gd`: a exposição da noite, abaixo da do fim da tarde e sem degrau entre as duas; o
  `tests/world/test_phase260_dusk.gd` passou a esperar a da noite.
- Capturas: `tools/capture_phase260.tscn -- <pasta>`; antes e depois da noite em `F:\ferramentas\capturas\fase263\comparacao.png`.
