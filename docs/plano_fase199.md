# Plano da Fase 199 — Rede na varanda

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_195_199.md` (cemitério, pato e rede, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`HammockView.hang`, `spot`): nas casas com o alpendre das ilhas tropicais (a varanda da Fase 23 que a Fase 126 pôs nos
  operários e artesãos de dois andares), uma a cada `HAMMOCK_EVERY` pelo id, num vão da frente que não é o da porta (o do lado
  dela, pelo id), entre os dois esteios (`post_xs`, a mesma conta da `BuildingKit`), no assoalho, do lado de dentro do
  guarda-corpo; a rede estica até o vão de verdade. No lugar do modelo da casa (`BuildingView.model_place`).
- **A rede** (`hammock_mesh`): o pano listrado no comprido (vermelho, creme, amarelo e azul), caindo no meio (`SAG_M`), fechado
  junto das varas e com as beiradas subindo; a vara de cada ponta e os cabos em leque até o nó no esteio (`ANCHOR_UP_M`).
  Balança de leve em volta da linha dos nós, cada uma no seu ritmo, no tempo de jogo (`swing`). Um MultiMesh, sem descarte de
  face (o pano é visto dos dois lados).

## Como testar

- `tests/presentation/test_phase199_hammocks.gd`: a rede fica entre dois esteios num vão que não é o da porta, no assoalho e
  esticada até as faces de dentro dos esteios; fica dentro da varanda (entre o guarda-corpo e a parede, abaixo da viga); só no
  alpendre tropical e numa casa a cada `HAMMOCK_EVERY`; o balanço gira em volta dos nós.
- Captura: `tools/capture_phase199.tscn` (a rua de casas com alpendre na maior ilha tropical da semente 1840, de longe e as redes
  de perto).
