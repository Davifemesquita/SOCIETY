# Plano da Fase 368 — Janelas e portas do pacote nos prédios de madeira

**Estado: feita em 08/11/2026**, a terceira do roteiro `docs/plano_fases_366_370.md` (acabamento do MegaKit). Entrou no lugar do
"reboco ao sol": com a empena e a pedra clara corrigidas, a fachada ao sol não estoura.

## O problema

O MegaKit trocava as peças pelo nome da peça do Kenney. Nos prédios de madeira (as casas dos camponeses e as fábricas e
fazendas de parede de madeira) só a parede lisa (`wall-wood`) tinha peça no pacote: a de enxaimel. As janelas e as portas
continuavam nas tábuas do Kenney, e o prédio saía metade de cada kit, escuro e cheio de frestas.

## O que entrou

- **`BuildingKit.MEGAKIT_ALIASES`**: as janelas e as portas de madeira usam as mesmas peças do pacote que as de reboco (a
  ordem das três janelas é a mesma, então o `opening` e o `window_index` não mudam).
- **`shaders/building_kit.gdshader`**: no prédio de madeira (camada 2 da parede), o reboco do pacote leva só
  `megakit_wood_plaster_tint` (30%) do tom do prédio. O tom de madeira escura, por inteiro, deixava o reboco roxo.

## O que muda na tela

As casas dos camponeses deixam de ser de madeira escura e viram enxaimel com reboco creme, como as fábricas de madeira.

## Como testar

- `tests/presentation/test_phase368_wood_openings.gd`: todas as peças de madeira vêm do pacote com o MegaKit e do Kenney sem ele.
- Capturas: `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase368\dia\`; antes em `fase367\dia\`),
  `fabricas_de_perto.png` e `rua_peasants_*.png`.
