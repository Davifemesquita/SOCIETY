# Plano da Fase 241 — Terreiro de café

**Estado: feita em 01/11/2026**, a segunda do roteiro `docs/plano_fases_240_244.md` (lagar, terreiro e estacas, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`CoffeeYardView.sites`): em cada cafezal, nas duas células do meio de um lado pelo `SideYard` — o de −X do modelo, depois
  o de trás e por fim o de +X —, guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **O terreiro** (`yard_mesh`): o chão batido caiado com a mureta baixa em volta; o café espalhado numa camada fina, a metade de −x
  ainda vermelha e a de +x já seca, castanha, com os sulcos do rodo por cima, mais escuros; o montinho de café seco que o rodo está
  juntando, o rodo deitado e dois sacos cheios no canto. Um MultiMesh. (As leiras em cordões lisos pareciam tábuas, e em montinhos
  soltos pareciam escamas: a camada com os sulcos é que lê como grão espalhado.)

## Como testar

- `tests/world/test_phase241_coffee_yards.gd`: em cada rotação o terreiro fica num lado do cafezal (nunca na frente), encostado
  nele; com uma célula bloqueada ele muda de lado; o vinhedo não tem; o recheio e as bombas deixam as células; o terreiro cabe nas
  duas células.
- Captura: `tools/capture_phase241.tscn` (a ilha plana; `terreiro_de_perto.png`, `terreiro_e_predio.png`,
  `terreiro_de_longe.png`).
