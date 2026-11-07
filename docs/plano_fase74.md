# Plano da Fase 74 — Recintos e vitrines

**Estado: feita em 28/10/2026, a pedido do dono** ("pode continuar"; proposta deixada de fora na Fase 67). Só
apresentação: a simulação, o save, o lote, as vagas e as assinaturas não mudam.

## O que entrou

- **Duas silhuetas novas** (`BuildingDef.Silhouette.MENAGERIE` e `GALLERY`, no fim do enum: os números dos `.tres` não
  mudam). O zoológico deixa de ser um galpão de 6 × 6 e ganha o pátio da frente (quatro fileiras) com **seis cercados**
  de madeira (três por fileira, mourões e duas travessas, o portão na frente), com o galpão nas duas fileiras de trás. O
  museu ganha a fileira da frente com **seis pedestais** de pedra clara, três de cada lado do caminho da porta.
- **Uma vaga por cercado ou pedestal** (`BuildingKit.exhibit_spots`): a peça posta aparece na vaga dela, na ordem do
  catálogo (`ExhibitsState.in_building`), como filha do modelo (segue o giro do prédio); a peça que entra refaz só as
  peças (`building_state_changed`), e o prédio demolido as leva junto.
- **Os bichos e as peças** (`ExhibitModels`, gerados no código com cor por vértice, sem asset): o elefante (tromba,
  orelhas e presas), a girafa (pescoço comprido, manchas e ossicones), o leão (juba), o tigre (listras), duas zebras
  listradas, três araras no poleiro; a ânfora, a amonite no suporte, o sarcófago dourado, o quadro de mestre no
  cavalete, o modelo de navio e a luneta no tripé. As formas simples (caixa, viga, cilindro) foram para `VertexShapes`,
  que o trem da Fase 71 também usa.
- O material é o mesmo do trilho e do trem (cor por vértice): nenhuma pipeline nova. As fotos do zoológico e do museu no
  menu foram refeitas.

## Números

- Benchmark: o mundo do benchmark não tem zoológico nem museu; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase74_exhibits_shown.gd`: os seis cercados e os seis pedestais (no pátio, dentro do lote, o
  caminho da porta do museu livre), uma malha própria para cada peça (de pé e do tamanho da vaga), e as peças postas
  aparecendo nas vagas na ordem do catálogo e saindo com a demolição.
- Capturas: `tools/capture_phase74.tscn -- <pasta>` (no mundo plano, o zoológico e o museu cheios; em
  `F:\ferramentas\capturas\fase74`).

## Fica de fora (proposta à espera do dono)

- Bichos andando no cercado, chão de capim e água nos cercados, vitrines de vidro (pediriam um material transparente) e
  visitantes olhando as peças.
