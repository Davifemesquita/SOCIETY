# Plano da Fase 67 — Zoológico e museu

**Estado: feita em 28/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima"; a proposta do
zoológico e do museu do Anno, simplificada). Mexe na simulação (prédios novos, estado novo no save); as assinaturas
(terreno e matemática determinística) não mudam.

## O que entrou

- **Zoológico** (6 × 6, madeira, 4.000 moedas, 16 tábuas e 6 tijolos, 60/min, com 100 artesãos) e **museu** (5 × 5,
  pedra, 5.000 moedas, 6 tábuas e 16 tijolos, 70/min, com 200 artesãos), na aba dos serviços: cada um tem 6 vagas
  (`BuildingDef.exhibit_slots`, `exhibit_kind`) e beleza-base 0,1 em 18 células, como uma decoração grande.
- **Peças** (`ExhibitDef`, `data/exhibits/`): seis animais (araras, zebras, girafa, leão, elefante, tigre) e seis
  objetos (ânfora grega, maquete de navio, fóssil, telescópio, múmia, pintura de mestre), de 1.500 a 7.000 moedas e de
  +0,06 a +0,14 de beleza, as melhores liberadas pelos marcos. Cada uma se compra uma vez.
- **Regra**: a beleza do zoológico ou museu é a dele mais a das peças que ele expõe (`DerivedState.beauty_strength`,
  usada também pela camada Beleza do mapa) e entra na felicidade das casas em volta como a das decorações (a soma por
  casa vai até 1).
- **Comando** `PlaceExhibitCommand`: compra e põe a peça (a guardada vai de graça); recusa prédio de outro tipo, cheio,
  peça já exposta, bloqueada e sem dinheiro. Demolir, substituir, desfazer ou perder o prédio guarda as peças dele.
- **Save**: `ExhibitsState` (peça → prédio, 0 = guardada); o save antigo carrega sem peça; peça desconhecida, no prédio
  errado ou além das vagas recusa o save.
- **Painel**: as casas embelezadas, as peças e a felicidade que elas dão, e um botão por peça do tipo do prédio
  (comprar com o preço na dica, expor a guardada, marcado o da exposta, desligado com o motivo). Ícones no atlas
  (o leão do lorc, baixado do game-icons.net, CC BY 3.0; o busto de pedra do delapouite) e as fotos do menu.

## Números

- Benchmark (alto, RTX 5060): neutro — tick médio 1,30 ms, construir com a ilha cheia 15,3 ms, desenho igual
  (`docs/benchmark.md`).

## Como testar

- `tests/sim/test_phase67_exhibits.gd`: dados, textos e ícones; comprar cobra e sobe a beleza das casas; as recusas;
  o prédio cheio; demolir guarda e a peça volta de graça; o save (e o antigo).
- `tests/ui/test_phase67_exhibit_panel.gd`: o painel do zoológico compra pelo botão, sem chave sem tradução.

## Fica de fora (proposta à espera do dono)

- Os bichos e as peças à vista no modelo (recintos, vitrines: hoje o zoológico é um galpão e o museu um prédio de pedra
  com telhado de quatro águas), peças que chegam por evento ou expedição (Fase 70) e a atratividade/turismo (Fase 68).
  Os números são provisórios.
