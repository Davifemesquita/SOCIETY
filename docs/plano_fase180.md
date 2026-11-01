# Plano da Fase 180 — Borboletas nos canteiros

**Estado: feita em 31/10/2026**, a primeira do roteiro `docs/plano_fases_180_184.md` (borboleta, correio e galo, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ButterflyView.groups`): numa rede de pontos a cada `GROUP_STEP` células (cada ponto deslocado uma célula pelo
  hash), o ponto em terra sem árvore, prédio, estrada nem trilho vira um grupo — nas ilhas temperadas só se cai num canteiro de
  papoulas (`ScatterView.poppy_patch`, Fase 156), nas tropicais no capim aberto com a chance `TROPICAL_CHANCE`. Só nas ilhas
  com relevo. Cada grupo tem `PER_GROUP` borboletas, de espécies sorteadas (branca, amarela, laranja, azul), a `GROUP_HEIGHT_M`
  do chão.
- **A borboleta** (`butterfly_mesh`): o corpo fino e as duas asas de cada lado, abertas no plano, com o UV.x do corpo (0) até a
  ponta (1); maior que a de verdade, para se ver da câmera do jogo.
- **O voo** (`shaders/butterfly.gdshader`): cada uma esvoaça numa volta própria em volta do grupo, subindo e descendo, virada
  para onde vai, e bate as asas (a dobra no corpo, pela distância até ele), no tempo visual (para na pausa); a cor da asa sai da
  espécie, com a borda mais escura; some de longe (o MultiMesh cobre o arquipélago).
- **A vista** (`GameScreen.butterfly_view`): um MultiMesh com o dado da instância, escondido à noite (`DayClock.night_factor`
  a partir de `HIDE_AT`); refeito só quando aparece e algo mudou (obra, demolição, estrada, árvores, troca de mundo).

## Riscos

- Na primeira captura, com 30 cm de envergadura e a 45 cm do chão, elas sumiam no meio das papoulas: ficaram com 44 cm e a 70 cm.
- Refazer os grupos do arquipélago inteiro a cada obra custava ~48 ms no quadro seguinte (o `hash()` de um Array por ponto e
  a primeira vez). Agora o hash é aritmético (`FireflyView.cell_hash`) e só a ilha que mudou é refeita (`IslandDirty`: a obra, a
  estrada e as árvores dizem a ilha; o demolido, pela ilha guardada): a ilha principal leva ~2,4 ms. Os vaga-lumes da Fase 178
  ganharam o mesmo (o arquipélago inteiro levava ~10 ms à noite).

## Como testar

- `tests/world/test_phase180_butterflies.gd`: os grupos em terra livre, acima do chão, nas temperadas só sobre as papoulas e
  também nas tropicais; o mesmo mundo dá os mesmos grupos; nada na ilha plana; as asas abertas com o UV do corpo à ponta.
- Captura: `tools/capture_phase180.tscn` (dois grupos da ilha principal de manhã e à tarde, de perto e de meia distância).
