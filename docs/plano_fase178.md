# Plano da Fase 178 — Vaga-lumes no prado

**Estado: feita em 31/10/2026**, do roteiro `docs/plano_fases_175_179.md` (espantalho, cegonha e vaga-lume, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`FireflyView.swarms`): numa rede de pontos a cada `SWARM_STEP` células (cada ponto deslocado uma célula pelo hash),
  o ponto em terra sem árvore e sem prédio, estrada nem trilho a até `CLEAR_CELLS` vira enxame — com chance `FOREST_CHANCE` se
  há mata nesse quadrado, `OPEN_CHANCE` no capim aberto. Só nas ilhas com relevo.
- **Os vaga-lumes** (`flies`): `FLIES` por enxame, espalhados até `SPREAD_M` em volta do meio, de `LOW_M` a `HIGH_M` acima do
  chão, pela semente do enxame.
- **O brilho** (`shaders/firefly.gdshader`): um quadrado de frente para a câmera somado à cena, sem profundidade nem sombra; o
  vaga-lume vaga numa volta própria (`wander_m`) e pisca (acende depressa, some devagar) no tempo visual (para na pausa), aceso
  pelo global `night_light` e sumindo de longe (`fade_begin_m`, `fade_end_m`: o MultiMesh cobre o arquipélago).
- **A vista** (`GameScreen.firefly_view`): um MultiMesh com o dado da instância (fase do pisca, fase da volta, ritmo), escondido
  de dia (`DayClock.night_factor` abaixo de `SHOW_AT`); refeito só quando aparece e algo mudou (obra, demolição, estrada,
  árvores, troca de mundo).

## Riscos

- A primeira versão tinha os pontos de 16 cm e quase sempre apagados: não se viam. Ficaram de 24 cm, com halo e o pisca mais
  longo.

## Como testar

- `tests/world/test_phase178_fireflies.gd`: os enxames em terra livre, longe de prédio e estrada, na beira da mata e no capim;
  os vaga-lumes baixos em volta do meio, iguais no mesmo mundo; nada na ilha plana; a estrada nova tira o enxame de perto.
- Captura: `tools/capture_phase178.tscn` (dois enxames da ilha principal ao anoitecer e de noite, de perto e de longe).
