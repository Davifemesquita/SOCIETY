# Plano da Fase 258 — Telhado e parede com cor

**Estado: feita em 01/11/2026**, quarta do roteiro `docs/plano_fases_255_259.md` (cor viva, a pedido do dono).

## O que entrou

- **Telhado pela tabela** (`BuildingView.ROOF_TINTS`, `palette_roof`): todo prédio e toda paleta tiram a cor do telhado da
  tabela do material. Antes a paleta 0 das casas e todo prédio que não é casa tiravam o tom da parede escurecida e clareada,
  e o telhado saía rosa-acinzentado. Telhas: terracota, laranja, vermelho-escuro e marrom de telha velha (o cinza-azulado da
  Fase 39, sobre a textura de telha vermelha, saía lilás); tábuas: quatro marrons quentes.
- **Tinta mais forte** (`shaders/building_kit.gdshader`): na parede, `tint_strength` de 0,55 para 0,68 (o reboco saía cinza-frio,
  a cor da textura); no telhado, `roof_tint_strength` 0,85 (a telha vermelha misturada com o cinza da textura saía rosa).
- **Reboco quente** nas classes de cima (`data/tiers/*.tres`, `house_color`): artesãos (0,74; 0,56; 0,42), engenheiros de cinza
  (0,58; 0,55; 0,5) para areia (0,84; 0,74; 0,56) e investidores (0,93; 0,87; 0,73). As paletas da Fase 39 seguem variando o
  tom em volta disso.

## Como testar

- `tests/world/test_phase258_roofs.gd`: a tabela em todo prédio e paleta, telhas de terracota e tábuas quentes, os pesos da
  tinta no shader e o reboco quente das classes de cima.
- Capturas: `tools/capture_phase255.tscn -- <pasta>`; depois em `F:\ferramentas\capturas\fase258\depois` e o laboratório (a tinta e
  as cores das casas) em `F:\ferramentas\capturas\fase258\lab`.

## Fica de fora

As fotos dos prédios nos cartões do menu (`ui/photos/`, Fase 51) foram tiradas com as cores de antes; refazer com
`tools/bake_building_photos.tscn` no fim do ciclo.
