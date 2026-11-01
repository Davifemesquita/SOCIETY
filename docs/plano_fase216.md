# Plano da Fase 216 — Monte de carvão na usina

**Estado: feita em 01/11/2026**, do roteiro `docs/plano_fases_215_219.md` (tábua, cortina e andorinha, a partir das capturas do
Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`CoalHeapView.sites`, `cells`): em cada usina a carvão, as duas células do meio de um lado, encostadas nela: o de −X
  do modelo, depois o de +X e por fim o de trás (a frente é a da estrada), livres pela mesma regra das tábuas da Fase 215
  (`PlankStackView._pair`, `_free`), fora das células das tábuas de uma serraria encostada. O recheio e as bombas as deixam
  limpas.
- **O monte** (`heap_mesh`, `height_at`): a baia de tábuas com os esteios encostada na parede, aberta na frente; o monte de duas
  cristas, mais alto junto da parede, em faces chapadas (o carvão em pedras, não um pano liso), entre o preto e o cinza; pedras
  soltas no pé e a pá cravada na crista menor. Um MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase216_coal_heaps.gd`: nas quatro rotações o monte fica de lado, encostado na usina, nunca na frente, nas
  duas células vizinhas ao longo da parede; com uma delas bloqueada, vai para o outro lado; a usina a petróleo e os outros
  prédios não têm; o recheio e as bombas deixam as células; a malha cabe nas duas células e é mais alta junto da parede.
- Captura: `tools/capture_phase216.tscn` (duas usinas na ilha plana; `carvao_de_perto.png`, `carvao_e_usina.png`,
  `carvao_de_longe.png`).
