# Plano da Fase 189 — Focas nas pedras

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_185_189.md` (hera, estaca e arco-íris, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SealView.colonies`): numa rede de pontos a cada `COLONY_STEP` células, com a chance `COLONY_CHANCE` (hash
  aritmético, `FireflyView.cell_hash`), a célula da costa mais perto do ponto — terra baixa (`LOW_M`) e quase plana, sem prédio,
  estrada nem árvore, encostada no mar pelo lado — vira um grupo, se não há prédio no bloco dela nem nos vizinhos (blocos de
  `WILD_CELLS`: longe das vilas). Só nas ilhas temperadas com relevo.
- **As focas** (`seals`): duas a quatro deitadas ao longo da beira, a cabeça mais ou menos para o mar. O corpo malhado deitado
  (`body_mesh`: o tronco afinando para a cauda, a barriga clara, as manchas e as nadadeiras) é parado; a cabeça (`head_mesh`,
  com o pivô no pescoço) ergue e baixa uma vez por volta, cada foca no seu ritmo (`head_lift`), no tempo de jogo (para na
  pausa). Dois MultiMesh (`GameScreen.seal_view`), refeitos na obra, na demolição, na estrada e ao trocar de mundo.

## Riscos

- O teste pegou as focas de costas para o mar (o sinal do rumo trocado); a primeira captura também as tinha claras demais.

## Como testar

- `tests/world/test_phase189_seals.gd`: os grupos na beira baixa e livre das temperadas, nada nas tropicais; cada foca no chão,
  virada para o mar; nenhum grupo perto de prédio; a cabeça ergue e volta.
- Captura: `tools/capture_phase189.tscn` (os grupos da costa, de perto e de meia distância, com as cabeças erguidas).
