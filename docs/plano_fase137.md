# Plano da Fase 137 — Boca do forno acesa

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_135_139.md` (galinha, forno e mina, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`FurnaceGlowView.mouth`): nas fábricas de forno (`FURNACES`: padaria, olaria, vidraria, fundição e a de vigas
  de aço), no térreo da fachada de +X do prédio (sem lugar, a de −X), na célula de parede lisa mais perto do meio (com
  janela em todas, a do meio, embaixo dela); no corpo do prédio, sem o pátio. Sem modelo do kit, nada.
- **A boca** (`frame_mesh`): soleira de pedra, ombreiras e arco de tijolo em `ARCH_SEGMENTS` aduelas de tons alternados
  saindo `PROUD_M` da parede, e a portinhola de ferro aberta para fora.
- **O fogo** (`glow_mesh`, `shaders/furnace_glow.gdshader`): o vão do arco, mais claro embaixo e lambendo para cima pelo
  tempo, tremulando; aceso com a fábrica produzindo e não pausada (`burning`, `INSTANCE_CUSTOM.r`), mais forte à noite
  (global `night_light`); parada, fica a brasa escura. À noite a boca acesa deixa uma poça de luz laranja no chão diante
  dela (o `shaders/light_pool.gdshader` da Fase 119), sem luz de verdade.
- Três MultiMesh com a caixa fixa do arquipélago (`GameScreen.furnace_glow_view`), refeitos na obra, na demolição e ao
  trocar de mundo; o estado conferido a cada `CHECK_S` (e guardado à parte: sem tela o MultiMesh não devolve o que se
  grava nele).

## Como testar

- `tests/world/test_phase137_furnace_glow.gd`: a boca fica numa fachada do lado (perpendicular à frente), dentro do lote e
  no piso do prédio, nas cinco fábricas e quatro rotações; nunca bate numa janela; outros prédios não têm; o fogo só
  acende produzindo.
- Captura: `tools/capture_phase137.tscn` (ilha plana: a fundição e a padaria produzindo, a vidraria parada;
  `forno_de_dia.png`, `vidraria_parada.png`, `forno_de_noite.png`, `padaria_de_noite.png` e `fabricas_de_noite.png`).
