# Assets faltando

Tudo que ainda é placeholder entra aqui (seção 14 da especificação): o arquivo esperado,
a descrição, o orçamento de polígonos e o prompt de imagem de referência.

| Arquivo | Descrição | Orçamento (LOD0) | Prompt de referência | Fase |
|---|---|---|---|---|
| `presentation/` estrada de terra | desde a Fase 9, ladrilho com a textura de terra da Poly Haven (`shaders/road.gdshader`); falta malha com meio-fio, sulcos de roda e a emenda entre células | 200 tri por célula | "estrada de terra batida, século XIX, vista de cima, sulcos de carroça, pedras soltas" | 10 |
| `assets/buildings/` (30 prédios) | hoje caixas na cor de cada prédio (`data/buildings/*.tres`, campo `color`); um modelo por prédio, com silhueta própria por cadeia | casa 3.000–8.000, fábrica 8.000–20.000 | "prédio industrial europeu do século XIX, <nome>, tijolo e madeira, vista isométrica, luz de fim de tarde" | 9 |
| casas por classe | desde a Fase 8, três modelos placeholder por classe (caixa na cor da classe, com tom sorteado pelo id, e telhado de duas águas em dois sentidos ou plano com chaminé, `presentation/building_view.gd`); 3 a 5 modelos de verdade por classe: madeira e palha (camponeses), tijolo geminado (operários), tijolo e pedra com detalhes (artesãos), 3 a 4 andares com sacadas (engenheiros), mansão ornamentada (investidores) | 3.000–8.000 | "casa de <classe> do século XIX, Europa industrial, <material da classe>, vista isométrica" | 9 |
| andaimes do upgrade | a casa troca de classe na hora; a seção 11 pede andaimes e poeira na mudança | até 1.500 | "andaime de madeira em volta de casa de tijolo, século XIX" | 9 |
| `presentation/` paralelepípedo | desde a Fase 9, textura de paralelepípedo da Poly Haven no ladrilho; falta o meio-fio | 200 tri por célula | "rua de paralelepípedo de granito, século XIX, vista de cima, meio-fio de pedra" | 10 |
| campo e pasto | ladrilho plano colorido; plantação e cerca com animais | até 1.000 | "campo de trigo cercado, século XIX, vista de cima" | 9 |
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
| navio mercante | desde a Fase 9, casco afilado de tábuas, dois mastros e velas enfunadas, gerados no código (`presentation/ship_view.gd`, cores no `data/ships/*.tres`); veleiro de carga de dois mastros com velas, cordame e carga no convés | 4.000–8.000 | "veleiro mercante de dois mastros, 1840, casco de madeira, velas brancas, vista isométrica" | 9 |
| navio do comerciante | o mesmo placeholder com vela vermelha; navio com bandeira e cores próprias do comerciante | 4.000–8.000 | "navio mercante estrangeiro do século XIX, velas vermelhas, bandeira de comércio" | 9 |
| posto do comerciante | plataforma de madeira sobre estacas com uma casinha e bandeira (`ShipView._build_post`); feitoria flutuante com armazém, guindaste e barcos amarrados | até 6.000 | "feitoria de madeira sobre estacas no mar, século XIX, bandeira de comércio" | 9 |
| píer | caixa baixa como os outros prédios; trapiche de madeira avançando sobre a água, com amarras | até 2.000 | "trapiche de madeira sobre estacas, século XIX, cordas e cabeços de amarração" | 9 |
| rastro e gaivotas | desde a Fase 9, rastro de espuma em partículas e gaivotas em V voando em volta dos portos (`presentation/ship_view.gd`); gaivota de verdade com bater de asas | até 300 | "gaivota em voo, baixo polígono" | 10 |
| mapa do arquipélago | desde a Fase 7, carta desenhada no código (papel, sépia, litoral a tinta, rosa dos ventos, `ui/hud/archipelago_map.gd`); falta a textura de papel e o traço de gravura no litoral | — | "mapa náutico do século XIX, arquipélago, papel envelhecido, litoral em gravura" | 9 |
| ícones (`ui/icons/icons.png`) | base do game-icons.net (CC BY 3.0) recolorida e emoldurada por `tools/build_icons.gd`; arte própria no mesmo estilo de medalhão (bens), placa de madeira (prédios) e lacre (classes) | 128 px | "ícone de <nome>, gravura do século XIX, tinta sépia sobre papel, moldura dourada" | 9 |
| papel da interface | desde a Fase 9, papel gerado por ruído com moldura de madeira, filete dourado e cantoneiras (`ThemeBuilder.paper_image`); textura pintada à mão com gravura nas cantoneiras | 512 px, 9-slice | "papel envelhecido do século XIX, bordas gastas, cantoneira de latão" | 10 |

## Retratos (seção 14)

Placeholder hoje: medalhão oval com o desenho do game-icons sobre fundo escuro, gerado por
`tools/build_icons.gd` em `ui/portraits/portrait_<id>.png` (256×320). Estilo base de todos:
**"retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente"**.

| Arquivo | Personagem | Prompt | Fase |
|---|---|---|---|
| `portrait_tier_peasants.png` | camponeses | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; camponês europeu de 1840, camisa de linho e colete de lã, chapéu de palha na mão, mãos calejadas" | 8 |
| `portrait_tier_workers.png` | operários | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; operário de fábrica de 1840, jaqueta de sarja, boné, avental de couro, rosto sujo de fuligem" | 8 |
| `portrait_tier_artisans.png` | artesãos | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; artesã de oficina de 1850, vestido de algodão e avental, óculos na testa, ferramentas de relojoaria" | 8 |
| `portrait_tier_engineers.png` | engenheiros | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; engenheiro de 1860, sobrecasaca, colete com corrente de relógio, planta enrolada debaixo do braço" | 8 |
| `portrait_tier_investors.png` | investidores | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; investidora de 1870, vestido de seda escura, joias discretas, luvas, olhar firme" | 8 |
| `portrait_advisor.png` | conselheiro (metas guiadas) | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; conselheiro do governador, homem de 50 anos, costeletas grisalhas, casaca escura, pena e caderno" | 8 |
| `portrait_trader.png` | comerciante neutro | "retrato a óleo, século XIX, meio corpo, fundo neutro, luz lateral quente; capitã mercante de 1840, casaco de lã azul com botões de latão, lenço no pescoço, luneta" | 8 |

## Gráficos a conferir na placa de vídeo (Fase 9)

Esta VM não tem GPU: estes itens só se confirmam no PC alvo (RTX 3060).

| Item | O que conferir |
|---|---|
| nuvens volumétricas (SunshineClouds2) | no Vulkan por software o efeito escurece a tela inteira fora das nuvens; por isso estão só no nível ultra e desligadas no llvmpipe. Na RTX 3060: o céu e o chão aparecem com as nuvens? Se sim, voltam para o nível alto (`data/graphics/high.tres`, `clouds = true`) |
| benchmark no nível alto | `Society.exe -- --benchmark` (ou `-- --benchmark --nivel 3` para o ultra): o quadro tem de ficar em até 16,6 ms em 1080p |

