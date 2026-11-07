# Plano da Fase 204 — Guarda-sol de palha

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_200_204.md` (gato, poço e carrinho, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`PalapaView.cells`, `near_of`): em volta de cada entreposto e cabana de pesca das ilhas tropicais, até `PER_HOST`
  células de areia (terra baixa até `SAND_TOP_M`, quase plana, com o mar a até `SEA_CELLS`), livres e fora do barco virado e das
  redes, a partir de `near_of` do meio do prédio e até `SPREAD_CELLS` além disso, pela ordem da distância e afastadas
  `SPACING_CELLS` umas das outras. Em volta do entreposto a distância mínima passa do cais de pedra da Fase 106
  (`QUAY_CLEAR_CELLS`): o cais é só desenho, e as células debaixo dele parecem areia livre (o primeiro guarda-sol nasceu dentro
  da plataforma).
- **O guarda-sol** (`palapa_mesh`): o mastro, o cone de palha de gomos em dois tons, a franja de pontas recortadas, o bico
  amarrado e o banco de duas toras ao lado, girado à toa. Um MultiMesh, sem descarte de face.
- **O recheio** se refaz mais longe em volta dos prédios cujas peças ficam longe deles (`ScatterView.FAR_REACH`: a igreja e o
  cemitério, o entreposto e a cabana de pesca e os guarda-sóis); antes, a 2 células, uma bananeira ficava debaixo do
  guarda-sol.
- **A memória das buscas junto da rua** (`WaterPumpView.remembered`): as células tomadas, as bombas e os carrinhos de feira
  ficam guardados por ilha até a próxima obra, estrada, trilho, árvore derrubada, subida de classe ou troca de mundo. O recheio,
  a bomba, o poço e o carrinho as recalculavam várias vezes, cada vez percorrendo os ~800 prédios da cidade do benchmark: o
  carregar tinha subido de 5,9 para 6,4 s ao longo das Fases 201 a 204 e voltou a 6,0. Sem a vista da bomba na árvore (testes,
  ferramentas) nada fica guardado; quem recebe a lista ganha uma cópia.

## Como testar

- `tests/world/test_phase204_palapas.gd`: os guarda-sóis ficam na areia livre perto do mar, na faixa de distância do entreposto,
  afastados uns dos outros e nunca debaixo do cais de pedra; o recheio deixa as células; as temperadas e a ilha plana não têm.
- Captura: `tools/capture_phase204.tscn` (o entreposto da maior ilha tropical da semente 1840, os guarda-sóis de perto e de
  longe).
