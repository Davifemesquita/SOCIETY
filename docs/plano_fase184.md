# Plano da Fase 184 — Limo na pedra

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_180_184.md` (borboleta, correio e galo, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A rocha do mar** (`RockView.sea_material`, `shaders/sea_rock.gdshader`): a mesma textura de rocha do terreno, triplanar no
  mundo, no mesmo tom (`RockView.TINT`, `TEXTURE_M`), e junto da linha d'água a faixa de limo e sargaço — marrom-oliva escuro
  em manchas até `weed_top_m` acima do mar, com a borda de cima recortada por ruído (`edge_m`) — e acima dela a pedra ainda
  molhada, mais escura e lisa, até `wet_top_m`; na borda de cima do limo, a crosta clara de sal e cracas (`crust`,
  `crust_m`) em manchas, que marca a linha da maré de longe. A chuva molha o resto (`wet_surface.gdshaderinc`). O ruído usa
  hash inteiro (o `sin` perde precisão longe da origem).
- **Quem usa**: os rochedos e as rochas da falésia (`RockView`) e os matacões do rio (`RiverStoneView`), as pedras que ficam na
  água. As pedras soltas dos barrancos (`TreeView`) e as das jazidas (`DepositView`), longe dela, seguem com o
  `RockView.material` de sempre (e os testes das Fases 36 e 57 que o conferem não mudam).

## Riscos

- O sargaço verde-oliva quase não se via contra a textura da rocha, que já tem musgo: a alga ficou marrom-escura e subiu a
  ~1 m, e a crosta da maré entrou; a primeira crosta, branca e contínua, parecia uma faixa pintada (ficou cinza, fraca e em
  manchas).

## Como testar

- `tests/presentation/test_phase184_sea_rock.gd`: a rocha do mar tem a mesma textura, o mesmo tom e a mesma escala; com tela, o
  shader compila com os uniformes da faixa, e a faixa fica acima do mar e abaixo da pedra molhada.
- Captura: `tools/capture_phase184.tscn` (rochedos e falésia da ilha principal da semente 1840, de perto).
