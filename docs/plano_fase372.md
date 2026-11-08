# Plano da Fase 372 — Postigos do pacote

**Estado: tentada e deixada de fora em 08/11/2026**, a segunda do roteiro `docs/plano_fases_371_375.md` (peças do MegaKit II).

## A ideia

Com o MegaKit, trocar a madeira lisa dos postigos (a célula da tinta, Fase 177) pelas tábuas do pacote, pintadas na cor do
postigo pelo shader.

## O que se viu

- As folhas prontas do pacote (`WindowShutters_*_Open`) saem abertas em ângulo, até meio metro da parede, e são da madeira crua: não
  cabem na regra da folha dentro da célula (Fase 366) e perderiam as quatro cores dos postigos. Ficaram de fora logo de saída.
- As tábuas do pacote na caixa da folha (a faixa das tábuas da `T_WoodTrim`, em pé, com uma marca na UV2.y para o shader pintar):
  - sem as réguas da veneziana, a folha ficou lisa e mais escura que a de antes;
  - com as réguas por cima, ficou praticamente igual à da Fase 177, porque nessa escala o veio das tábuas quase não aparece
    (`F:\ferramentas\capturas\fase372\dia`, `enxaimel_de_perto.png`).
- Nada entrou no código: o ganho não pagava o caminho a mais no shader e na montagem.
