# Plano da Fase 136 — Vagoneta e rejeito

**Estado: feita em 31/10/2026**, segunda do roteiro `docs/plano_fases_135_139.md` (galinha, forno e mina, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SpoilTipView.sites`, `cells`): em cada mina (os prédios de `Silhouette.HEADFRAME`), duas células em linha
  encostadas no meio de um lado — o de +X da frente, o oposto ou o de trás, o primeiro livre (sem prédio, estrada, trilho
  nem árvore, fora do largo e da alameda), de terra e com até `MAX_RELIEF_M` de desnível. O recheio, os silos e as bombas
  d'água deixam essas células limpas.
- **O trilho e o monte** (`track`, `_rails`, `_heap`): o trilho sai da parede, `FLOOR_LIFT_M` acima do piso da mina, e vai
  até `TIP_BACK_M` antes do meio do monte, `TIP_BELOW_M` abaixo do cume; dois trilhos de ferro, dormentes a cada
  `SLEEPER_STEP_M`, cavaletes de madeira onde ele passa acima do chão e o batente na ponta. O monte é um cone de
  `HEAP_SIDES` faces irregulares, cada uma num tom, com pedras soltas no pé, na cor do rejeito da jazida
  (`SPOIL_COLORS`: carvão preto, ferro ferrugem, ouro cinza claro). Uma malha só para o arquipélago.
- **A vagoneta** (`cart_pose`, `loaded`, `phase_of`): enquanto a mina produz, sai cheia da boca (`OUT_S`), vira o rejeito
  na ponta com a frente baixando em volta do eixo das rodas da frente (`TIP_S`, até `TIP_RAD`), volta vazia (`BACK_S`) e
  espera na boca o resto da volta de `CYCLE_S`; cada mina no seu adianto. Parada (sem produzir), fica na boca, cheia. A
  vagoneta e a carga (tingida pela cor do rejeito) são dois MultiMesh com a caixa fixa do arquipélago, no tempo de jogo
  (para na pausa). `GameScreen.spoil_tip_view`; refeito na obra, na demolição, na estrada, no trilho, na derrubada de
  árvores e ao trocar de mundo.

## Como testar

- `tests/world/test_phase136_spoil_tips.gd`: duas células em linha fora da mina, nunca do lado da frente, nas quatro
  rotações; com o lado bloqueado, vai para outro; o trilho vai da parede até a beira do monte, acima do pé dele; a
  vagoneta só anda com a mina produzindo, chega perto da ponta, vira e volta à boca; vai cheia e volta vazia; outros
  prédios não têm; a vista conta as minas.
- Captura: `tools/capture_phase136.tscn` (semente 1840: uma mina sobre as duas primeiras jazidas com lugar para o monte,
  produzindo; `mina_<minério>.png` e `mina_<minério>_virando.png`).
