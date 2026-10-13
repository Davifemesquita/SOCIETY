# Assets faltando

Tudo que ainda é placeholder entra aqui (seção 14 da especificação): o arquivo esperado,
a descrição, o orçamento de polígonos e o prompt de imagem de referência.

| Arquivo | Descrição | Orçamento (LOD0) | Prompt de referência | Fase |
|---|---|---|---|---|
| `presentation/` estrada de terra | ladrilho plano marrom no lugar da malha e textura de terra batida com sulcos de roda | 200 tri por célula | "estrada de terra batida, século XIX, vista de cima, sulcos de carroça, pedras soltas" | 9 |
| ícone "sem acesso à estrada" | hoje é um "!" laranja em Label3D; vira ícone do sistema central (`ui/icons/`) | — | "ícone de estrada interrompida, estilo gravura do século XIX, moldura dourada" | 7 |
| `assets/buildings/` (30 prédios) | hoje caixas na cor de cada prédio (`data/buildings/*.tres`, campo `color`); um modelo por prédio, com silhueta própria por cadeia | casa 3.000–8.000, fábrica 8.000–20.000 | "prédio industrial europeu do século XIX, <nome>, tijolo e madeira, vista isométrica, luz de fim de tarde" | 9 |
| casas por classe | camponês e operário são caixas da cor da classe (`data/tiers/*.tres`); 3 a 5 modelos por classe | 3.000–8.000 | "casa de <classe> do século XIX, Europa industrial, <material da classe>" | 8 |
| campo e pasto | ladrilho plano colorido; plantação e cerca com animais | até 1.000 | "campo de trigo cercado, século XIX, vista de cima" | 9 |
| ícones de estado do prédio | hoje texto em Label3D ("Sem entrada", "Saída cheia"…); viram ícones do sistema central | — | "ícone de <estado>, gravura do século XIX, moldura dourada" | 7 |
| carroça | caixa marrom com a carga na cor do bem (`presentation/cart_view.gd`); carroça de madeira com cavalo e carga visível (sacos, barris, tábuas, carvão) | 1.000–2.000 | "carroça de carga do século XIX puxada a cavalo, madeira, vista isométrica" | 9 |
| entreposto e armazém | caixas; galpão de porto com guindaste e armazém de tijolo com rampas | 8.000–20.000 | "entreposto portuário do século XIX com guindaste de madeira" | 9 |
| roupa dos pedestres | os personagens base da Quaternius vêm de roupa de baixo; a roupa por classe é cor por região do corpo no shader (`shaders/pedestrian_vat.gdshader`). Modelo de verdade: camponês de camisa e colete, operário de jaqueta e boné, mulheres de vestido longo; reduzir para 1.000–3.000 triângulos e gerar o VAT com `tools/bake_pedestrians.gd` | 1.000–3.000 | "pessoa comum da Europa industrial de 1840, <classe>, roupa de trabalho, corpo inteiro, pose em T, fundo neutro" | 9 |
| proporção dos pedestres | a versão gratuita só traz o corpo "Superhero" (musculoso); os corpos "Regular" estão na versão Source (paga, US$ 19,99) | — | — | 9 |
| cestos e sacos | quem sai de fazenda ou mercado anda com a animação de carregar, mas sem o cesto na mão | até 300 | "cesto de vime com pão e legumes, século XIX" | 9 |
| postes e fogueiras | a seção 9 pede postes e fogueiras acesos à noite; entram com os objetos de cenário | até 1.000 | "poste de lampião a gás, século XIX, ferro fundido" | 9 |
| janelas | vidros planos com luz no lugar das janelas dos modelos dos prédios; somem quando os prédios ganharem modelo com janela própria (emissão na textura) | — | — | 9 |
| árvores e pedras | modelos de estilo de desenho animado do Kenney Nature Kit com as cores trocadas no código (`presentation/tree_view.gd`); árvores europeias de 1840 (carvalho, faia, pinheiro-silvestre) com 2 LODs e balanço ao vento | árvore 300–800, pedra até 300 | "carvalho europeu isolado, baixo polígono estilizado, folhagem em massa, vista isométrica" | 9 |
| terreno | shader próprio com 4 texturas da Poly Haven (grama, rocha, areia, chão de floresta); falta lama de margem de rio, campo arado e trilhas | — | — | 9 |
| rio | braço de mar pela planície (fica no nível do mar); rio de verdade, com correnteza e altura própria, pede água em vários níveis | — | — | 9 |
| ponte | ladrilho de tábuas sobre o rio (`presentation/road_view.gd`); ponte de madeira ou pedra com corrimão | até 1.000 | "ponte de madeira rústica, século XIX, vista isométrica" | 9 |
| navio mercante | casco em caixa com proa em prisma, dois mastros e velas em placas (`presentation/ship_view.gd`, cores no `data/ships/*.tres`); veleiro de carga de dois mastros com velas, cordame e carga no convés | 4.000–8.000 | "veleiro mercante de dois mastros, 1840, casco de madeira, velas brancas, vista isométrica" | 9 |
| navio do comerciante | o mesmo placeholder com vela vermelha; navio com bandeira e cores próprias do comerciante | 4.000–8.000 | "navio mercante estrangeiro do século XIX, velas vermelhas, bandeira de comércio" | 9 |
| posto do comerciante | plataforma de madeira sobre estacas com uma casinha e bandeira (`ShipView._build_post`); feitoria flutuante com armazém, guindaste e barcos amarrados | até 6.000 | "feitoria de madeira sobre estacas no mar, século XIX, bandeira de comércio" | 9 |
| píer | caixa baixa como os outros prédios; trapiche de madeira avançando sobre a água, com amarras | até 2.000 | "trapiche de madeira sobre estacas, século XIX, cordas e cabeços de amarração" | 9 |
| rastro, balanço e gaivotas | o navio balança por seno na vista e a espuma é a da água; a seção 9 pede rastro na água e gaivotas no porto | — | "gaivota em voo, baixo polígono" | 9 |
| mapa do arquipélago | a janela de rotas pinta a carta náutica pixel a pixel (terra e mar); vira mapa ilustrado no estilo da interface | — | "mapa náutico do século XIX, arquipélago, papel envelhecido" | 7 |
