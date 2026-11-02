# Plano da Fase 278 — Orla da mata

**Estado: feita em 02/11/2026**, a quarta do roteiro `docs/plano_fases_275_279.md`. Com as copas mais estreitas e os vãos da Fase
276, a beira da mata mostrava os troncos de pé lado a lado, vistos do campo. No Anno, a mata desce em degrau até o campo, com
árvores novas e menores na frente.

## O que entrou

- **A árvore nova da orla** (`TreeView.young_entry`).
  - Onde: na célula de mata temperada que dá para o campo, isto é, com um lado de terra sem árvore (`SIDES`).
  - Quantas: uma em `YOUNG_CHANCE` (75%) dessas células, além das árvores da Fase 276.
  - Tamanho: de `YOUNG_SCALE` 0,32 a 0,55 da árvore adulta.
  - Lugar: puxada para o lado aberto (`YOUNG_OUT`, 0,3 da célula, pela soma dos lados abertos), sem sair da própria célula. A
    vizinha pode ser estrada ou lote.
  - Espécie: abeto em `YOUNG_SPRUCE` (50%), bétula em `YOUNG_BIRCH` (15%) e carvalho ou faia no resto, que de pequenos viram
    arbustos de copa baixa.
  - A primeira medida pôs 30% de bétulas: pequenas, pareciam pirulitos (o tronco branco fino e a bola em cima) e não cobriam
    nada.
- A orla só sai nas ilhas temperadas e fora das clareiras dos lenhadores (a célula cortada fica sem nada, como antes). As árvores
  novas usam as malhas e as camadas da mata: nenhum draw call novo.
- O recheio da beira da mata (arbustos da Fase 41) não mudou: as árvores novas já cobrem o pé dos troncos.

## Como testar

- `tests/world/test_phase278_forest_edge.gd`:
  - a árvore nova só na beira, em ~75% das células da beira, pequena, dentro da própria célula;
  - abetos, bétulas e outras folhosas aparecendo;
  - puxada para o lado aberto;
  - nenhuma no miolo da mata.
- `test_phase276_crowns.gd` soma a orla ao que a vista desenha. A conta é só das ilhas temperadas: uma árvore temperada numa
  ilha tropical faria o desenho passar da conta.
- Captura: `tools/capture_phase275.tscn -- <pasta>` (as vistas do ciclo da mata).
