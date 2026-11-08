# Plano da Fase 374 — Chaminé do pacote

**Estado: tentada e deixada de fora em 08/11/2026**, a quarta do roteiro `docs/plano_fases_371_375.md` (peças do MegaKit II).

## A ideia

Com o MegaKit, trocar o fuste e o capitel da chaminé das casas (o tijolo desenhado no shader, Fase 104) pela chaminé do pacote,
com a boca da fumaça e os potes no mesmo lugar.

## O que se viu

- A `Prop_Chimney2` (130 triângulos, tijolo irregular), esticada até a medida da nossa, saiu escura e cinza sobre o telhado, sem o
  vermelho que faz a chaminé se ler de longe (`F:\ferramentas\capturas\fase374\dia`, `rua_workers_a.png`).
- A `Prop_Chimney` é de tijolo vermelho, mas tem 618 triângulos, e o shader tinge o tijolo do pacote no tom da parede da casa (é
  assim que as paredes de tijolo do pacote seguem o prédio): sairia na cor da casa.
- Nada entrou no código; a chaminé de tijolo da Fase 104 fica.
