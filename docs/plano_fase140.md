# Plano da Fase 140 — Clareira do lenhador

**Estado: feita em 31/10/2026**, primeira do roteiro `docs/plano_fases_140_144.md` (toco, bote e boia, olhando o Anno do
dono: só a ideia). Só apresentação: as árvores continuam na simulação (o lenhador as conta) e nada muda no save.

## O que entrou

- **O corte** (`StumpView.cut_cells`): em volta da área de cada lenhador, até `lumberjack_radius_cells`, as células com
  árvore que o hash escolhe pela chance do anel (`RING_CHANCE`: quase todas junto da cabana, um quinto no último anel); a
  primeira escolha fica quando dois lenhadores se encostam. Só nas ilhas com relevo.
- **A mata recua** (`TreeView`): as células cortadas ficam sem árvore no desenho (`is_cut`). Ela guarda os lenhadores pelo
  id: só um lenhador que entra ou sai refaz o corte, e só o da ilha dele; os trechos das células que mudaram ficam para o
  quadro seguinte (`flush`), juntando os pedidos do mesmo quadro.
- **Tocos e toras** (`stump_places`, `log_place`, `stump_mesh`, `log_mesh`): um toco no ponto de cada árvore que a
  `TreeView` desenharia ali (o mesmo `_transform`), com o corte claro um pouco inclinado e três raízes; numa célula a cada
  `LOG_EVERY`, uma tora caída num rumo sorteado. Um MultiMesh de tocos e um de toras por trecho de `CHUNK_CELLS` da ilha,
  com o alcance de visibilidade dos detalhes (`GameScreen.stump_view`); só a ilha de um lenhador que entra ou sai, ou com
  árvores caindo perto de um, é refeita, no quadro seguinte (`refresh`), e tudo ao trocar de mundo.

## No caminho

- A primeira medida mostrou o custo de refazer o corte de todos os lenhadores de todas as ilhas a cada prédio construído:
  montar a cidade do benchmark subiu 2,8 s e construir com a ilha cheia foi de 17,7 para 28,6 ms. Agora outros prédios
  não mexem na clareira, e as camadas por trecho (não por lenhador) gastam menos draw calls.

## Como testar

- `tests/world/test_phase140_clearing.gd`: as células cortadas ficam no raio, fora da área e com árvore, mais cortadas
  perto que longe; a `TreeView` tira do desenho ao menos uma árvore por célula cortada e a `StumpView` põe um toco por
  árvore e algumas toras; demolido o lenhador, a mata volta; outro prédio não marca trecho para refazer; a ilha plana não
  tem.
- Captura: `tools/capture_phase140.tscn` (semente 1840: um lenhador no meio da mata mais cerrada; `clareira.png` e
  `clareira_de_perto.png`).
