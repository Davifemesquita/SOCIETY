# Plano da Fase 345 — Granito no alto

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_345_349.md` (pedra grande). No Anno o alto dos morros abre em
massas de rocha cinza; nos nossos o capim cobria tudo até a crista.

## O plano

- **Arquivos**: `presentation/summit_rock_view.gd` (nova), `ui/screens/game_screen.gd`, o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: rocha em cima de onde se constrói; refazer pesado a cada obra; a ilha virar um campo de pedras.
- **Como testar**: o teste novo, a captura do ciclo (o horizonte e a mata alta) antes e depois.

## O que entrou

- **`SummitRockView`** (`GameScreen.summit_rock_view`): numa rede de pontos a cada `STEP` (5) células, o ponto em terra que passa de
  `SUMMIT_SHARE` (62%) da altura mais alta da ilha e de `SUMMIT_MIN_M` (5 m) **e se destaca da volta** (`_crest`: pelo menos `KNOLL_M`,
  0,8 m, acima da média de oito pontos a 5 células — um topo ou uma crista) ganha, pelo hash (`CHANCE`, 55%), um grupo: uma rocha de
  2,5 a 4 m de raio no meio e de três a cinco de 1 a 2 m em volta, até 4,5 m, as formas da `RockModel` com o material da `RockView`,
  meio enterradas.
- **Só em célula livre** (sem prédio, estrada, trilho nem árvore): a célula que recebe obra perde a rocha (a vista se refaz na obra, na
  demolição, na estrada, no trilho e na derrubada).
- **As tentativas**: só pela altura (sem a crista), as rochas cobriam o planalto inteiro, onde fica a vila, como pimenta no capim; pequenas
  (1,6 a 2,8 m), quase não apareciam.

## Medida

315 rochas na semente 1840; refazer o arquipélago inteiro ~14 ms, uma vez a cada obra (como a vista das jazidas, Fase 128). Medido no
benchmark do fim do roteiro.

## Como testar

- `tests/world/test_phase345_summit_rock.gd`: as rochas no alto e em células livres, a estrada tirando a rocha, o mesmo resultado no
  mesmo mundo, nada na ilha plana, poucos pontos de crista e o refazer rápido.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase344\depois\`, depois em
  `F:\ferramentas\capturas\fase345\depois3\` (as tentativas em `depois\` e `depois2\`).
