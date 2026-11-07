# Plano da Fase 177 — Postigos nas janelas

**Estado: feita em 31/10/2026**, do roteiro `docs/plano_fases_175_179.md` (espantalho, cegonha e vaga-lume, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`Spec.shutters`, na chave da forma): todas as casas de `SHUTTER_TRIMS` (camponeses, operários e artesãos). Todas da
  classe, não uma parte: um detalhe que valesse só para algumas casas dobraria as malhas da classe (~18 ms cada uma nova).
- **As folhas** (`BuildingKit._shutters`): em cada janela do corpo (o slot `&"window"`: o que a ala tira fica de fora, o balanço
  e o pátio vêm do `_wall_point`), duas folhas abertas encostadas na parede, uma de cada lado do vão, cada uma da metade dele e
  da altura dele, `SHUTTER_GAP_M` além do vão (encostadas no caixilho do kit), `SHUTTER_OUT_M` fora da parede. Cada folha é uma
  caixa (12 triângulos).
- **A tinta** (`shaders/building_kit.gdshader`): a célula (1, 1) da paleta (`UV_SHUTTER`), que o kit não usa, numa das quatro
  cores de postigo (`shutter_green`, `shutter_blue`, `shutter_red`, `shutter_ochre`) pelo lugar do prédio (hash inteiro da
  origem do modelo, sem o `sin`, que perde precisão longe da origem), com as réguas da veneziana (`shutter_slat_m`) e a madeira
  aparecendo onde a tinta gastou.

## Riscos

- A primeira versão deixava as folhas a 14 cm do vão e elas pareciam soltas da janela (o caixilho do kit é estreito): 3 cm.

## Como testar

- `tests/presentation/test_phase177_shutters.gd`: só as três classes de baixo; duas folhas por janela do corpo (12 triângulos
  cada) em várias casas; a folha cabe na célula ao lado do vão; a célula da tinta é própria e nenhuma peça do kit cai nela. O
  teto de triângulos das casas (`test_building_kit.gd`) segue valendo.
- Captura: as ruas do `tools/capture_phase95.tscn` (`rua_peasants_a.png`, `enxaimel_de_perto.png`, `cerca_de_estacas.png`).
