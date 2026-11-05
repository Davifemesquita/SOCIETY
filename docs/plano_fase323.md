# Plano da Fase 323 — Parede que avança

**Estado: tentada em 05/11/2026 e deixada de fora** (quarta do roteiro `docs/plano_fases_320_324.md`). A ideia era quebrar as
quinas em esquadro das paredes da garganta, que seguem as células.

## O que se tentou

O roteiro pedia o detalhe visual do relevo da Fase 36 nos cantos da parede. Ele não serve aqui: na garganta, a parede é o
quadrado da célula de rio que vai do alto (os cantos que ela divide com o planalto) ao leito (os de dentro, abaixo d'água). Não há
canto no meio dela para subir ou descer.

A segunda tentativa foi empurrar na horizontal, ao longo da descida, os pontos novos da subgrade que as Fases 55 e 62 já põem nesses
quadrados (`CoastRefine.sway`, até 0,45 m num ruído suave, cheio só onde o desnível passa do de falésia e acima d'água, zero nos
cantos da grade e na borda com quadrado que não se divide). O teste passou, mas a captura não mostrou diferença, nem de perto.

## Por que não dá

- A **beira de cima** da parede é a borda das células do planalto, onde se constrói: os cantos dela são da simulação e a borda com o
  quadrado plano é reta (sem isso, fresta na malha).
- O **pé** é o leito, abaixo d'água, que a linha d'água da Fase 55, a espuma e os blocos da Fase 317 usam.
- Sobram um ou dois pontos no meio de cada face: empurrá-los só estufa o perfil da parede, o que de cima não aparece.

Fazer a parede avançar de verdade é mudar o traçado do rio (o gerador, que muda as assinaturas do terreno e os saves pedem
`VERSION` nova) ou deixar a malha da beira sair da grade, o que mexe com as regras de construção. As duas coisas são maiores que
uma fase de apresentação e ficam como proposta para o dono do produto.

## O que ficou

Nada no código. As capturas da tentativa estão em `F:\ferramentas\capturas\fase323\depois\` (iguais às de
`F:\ferramentas\capturas\fase322\depois_07\`).
