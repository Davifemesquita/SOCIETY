# Plano da Fase 365 — Viga entre os andares

**Estado: feita em 07/11/2026**, a última do roteiro `docs/plano_fases_361_365.md` (ligar o MegaKit), **no lugar do "telhado e
quinas"** do roteiro: o defeito que sobrou das Fases 360 a 364 pesava mais que o telhado novo.

## O problema

A parede do MegaKit foi desenhada para ter o piso por cima; empilhada andar sobre andar, a emenda aparecia como uma fresta escura
atravessando a fachada (nas casas de pedra dos artesãos se via de longe) e na frente do enxaimel saliente.

## O que entrou

- **`BuildingKit._floor_beams`**: com o MegaKit, uma viga de madeira escura (`UV_TIMBER`, `FLOOR_BEAM_M` de alto, saindo
  `FLOOR_BEAM_OUT_M` da parede) em volta do corpo em cada piso de cima; no último, só o corpo, se houver ala; no enxaimel saliente,
  a viga acompanha a frente que avançou. A fachada fica com o ritmo de vigas do próprio pacote.
- As fotos do menu refeitas.

## Como testar

- `tests/presentation/test_phase365_floor_beams.gd`: uma viga em cada piso de cima, perto da parede.
- presentation (428) e world (826) sem falha. Captura: `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase365\dia\`).

## Fica para depois

- O telhado com as telhas redondas e as quinas do pacote (o telhado gerado segue com as texturas da Fase 9).
