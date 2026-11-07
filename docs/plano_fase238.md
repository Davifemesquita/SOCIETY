# Plano da Fase 238 — Bandeira na prefeitura

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_235_239.md` (cervo, âncora e marco, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`TownFlagView.foot_of`, `BuildingKit.dome_finial`): em cada prefeitura (Fase 66), no remate do lanternim da cúpula de
  cobre (Fase 97), no referencial do modelo (`BuildingView.model_place`); sem cúpula, no meio da cumeeira. O `_dome` do kit passa
  a pôr o remate pelo mesmo `dome_finial` (a malha não muda).
- **A bandeira** (`pole_mesh`, `flag_mesh`): o mastro de ferro afinando com o colar no pé e a bola dourada no alto, e a bandeira da
  cidade — o campo vermelho com o losango dourado no meio e a orla dourada na ponta, nenhuma bandeira de verdade —, presa
  `FLAG_BELOW_M` abaixo do alto, numa `WindFlag` (Fase 22): o `WeatherView` a vira para o vento, faz tremular e deixa cair com o
  ar parado. Um nó por prefeitura; refeito na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase238_town_flag.gd`: na semente 1840, o mastro da prefeitura sobe do remate da cúpula, no meio do prédio e
  acima do tambor; o teatro (outra cúpula) não tem bandeira; a bandeira vai do mastro para +x e fica no alto dele.
- Captura: `tools/capture_phase238.tscn` (a semente 1840; `bandeira_perto.png`, `bandeira_outro_lado.png`, `bandeira_longe.png`).
