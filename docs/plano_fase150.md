# Plano da Fase 150 — Coluna de anúncios

**Estado: feita em 31/10/2026**, primeira do roteiro `docs/plano_fases_150_154.md` (coluna, placa e velocípede, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`AdColumnView.cells`): no canto de dentro das esquinas calçadas — a célula livre (sem prédio, estrada, trilho
  nem árvore) que encosta em rua de paralelepípedo por um lado em x e outro em z —, uma a cada `COLUMN_EVERY` pelo desenho
  da grade, fora do largo, da alameda, das mesas da taverna e das bombas d'água. A coluna fica `CORNER_M` do meio da
  célula para o lado da esquina. O recheio deixa a célula limpa.
- **A coluna** (`column_mesh`): o soco escuro, o fuste coberto de cartazes de cores desencontradas em duas fiadas, cada um
  com a figura de outro tom no meio (sem texto), a cornija e o chapéu de ferro em cúpula com o remate dourado. Um MultiMesh
  do arquipélago (`GameScreen.ad_column_view`), refeito na obra, na demolição, na estrada, no trilho, na derrubada de
  árvores e ao trocar de mundo.

## Como testar

- `tests/world/test_phase150_ad_columns.gd`: no cruzamento de duas ruas calçadas a coluna fica no canto de dentro, numa
  célula livre do desenho certo e com rua calçada nos dois lados da esquina; rua de terra não tem; uma casa no canto a tira;
  a vista desenha uma por célula.
- Captura: `tools/capture_phase150.tscn` (ilha plana: uma grade de ruas calçadas com casas; `esquina.png` e
  `coluna_de_perto.png`, esta com as árvores da alameda escondidas e a câmera posta à mão).
