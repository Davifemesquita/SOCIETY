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
