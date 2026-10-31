# Plano da Fase 128 — Jazidas à vista

**Estado: feita em 30/10/2026**, quarta do roteiro `docs/plano_fases_125_129.md` (recife, alpendre e nuvens, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **As manchas** (`DepositView.patches`): as células de jazida da ilha (`IslandGrid.deposits`) ligadas pelos lados, com o
  mesmo bem, viram uma mancha. Até aqui a jazida só aparecia no destaque ao escolher a mina.
- **O que se desenha** (`places`): na mancha sem prédio em cima, um afloramento de rocha no meio dela (as formas da
  `RockModel` com o material da `RockView`, meio enterrado) e pedras soltas do minério espalhadas pelas células dela,
  `ORE_PER_CELL` por célula em média, na cor do bem (`ORE_COLORS`: carvão quase preto, ferro ferrugem, ouro amarelo), cada
  uma num tom um pouco diferente. Com uma mina na mancha, nada (a mina já está lá).
- A vista (`GameScreen.deposit_view`) é refeita na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase128_deposits.gd`: cada mancha livre ganha um afloramento e as pedras do minério ficam sobre ela, na
  cor do bem; uma mina em cima tira o afloramento da mancha; a ilha plana não tem.
- Captura: `tools/capture_phase128.tscn` (semente 1840: as jazidas da ilha principal, de longe e de perto).
