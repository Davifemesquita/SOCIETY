# Plano da Fase 104 — Lampião, grade e chaminé de tijolo

**Estado: feita em 29/10/2026**, a última do roteiro `docs/plano_fases_100_104.md` (a rua habitada, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Chaminé de tijolo** (`BuildingKit._brick_chimney`, `_chimney_base`, `_chimney_height`): no lugar do bloco cinza do kit
  (a peça `chimney.glb` saiu do desenho; o arquivo fica, na lista das peças do kit), o fuste de `CHIMNEY_SIDE_M` de lado
  até `CHIMNEY_ABOVE_M` acima da cumeeira, o capitel em duas fiadas mais largas e dois potes de barro torneados. O tijolo é
  a célula (7, 1) da paleta (`UV_BRICK`), que o kit não usa, desenhado no `shaders/building_kit.gdshader` (fiadas
  desencontradas pela face, um tom por tijolo, a argamassa clara). A boca da fumaça da Fase 100 (`chimney_top`) passou para
  o alto dos potes.
- **Lampião de parede** (`Spec.lantern`, `lantern_pane`, `_lantern`): os serviços (menos o mercado, que tem a arcada, e a
  taverna, que tem o toldo) e as casas dos artesãos para cima sem toldo ganham, ao lado da porta, a `LANTERN_AT` do andar,
  o lampião de ferro no braço com a voluta, com o chapéu de quatro águas e a vidraça da frente. A vidraça entra na lista
  `windows()`: acende à noite com o prédio aceso, como as janelas.
- **Grade do pátio do museu** (`_gallery_fence`): o roteiro falava do pátio dos serviços de pedra, e o único deles com pátio
  é o museu (o dos pedestais, Fase 74). A grade de ferro de `GALLERY_FENCE_M` fecha a frente e os lados do pátio até o corpo,
  com o portão (dois pilares de pedra clara com o capitel) diante do caminho da porta.

## No caminho

- Dois testes antigos contavam a lista `windows()` como se fosse só de janelas da fachada (o leque de vidro do arco da Fase
  99 e a guarnição de pedra da Fase 25): passaram a descontar o lampião.

## Como testar

- `tests/presentation/test_phase104_lanterns_chimneys.gd`: a chaminé é de tijolo, passa da cumeeira, e a boca fica no alto
  dos potes; nenhuma peça do kit usa a célula do tijolo; quem tem lampião (serviços e casas dos artesãos para cima sem
  toldo); o lampião fica na frente, ao lado da porta, no térreo, e acende com as janelas; a grade do museu tem o vão do
  portão diante da porta.
- Captura: `tools/capture_phase95.tscn` ganhou o museu na rua dos prédios grandes e as tomadas `chamine_de_perto.png` e
  `museu_grade.png`; a chaminé aparece em `fumaca_manha.png`.
