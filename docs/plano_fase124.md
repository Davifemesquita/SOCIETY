# Plano da Fase 124 — Mansarda dos investidores

**Estado: feita em 30/10/2026**, a última do roteiro `docs/plano_fases_120_124.md` (fios, riacho e mansarda, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`Spec.mansard`): as casas dos investidores (`HouseTrim.PORTICO`) de telhado de duas águas e sem ala; a ala tem
  o telhado cruzado com o do corpo e fica como era, e a de telhado plano também. Entra na chave da forma.
- **A forma** (`mansard_levels`, `_mansard`): a água de baixo, íngreme, sobe do beiral (`MANSARD_EAVE_M` para fora da
  parede) até o rebordo, `MANSARD_LOWER` da altura do telhado e `MANSARD_INSET_M` para dentro da parede; a de cima, quase
  plana, fecha em quatro águas até a cumeeira na altura de antes (a chaminé e a fumaça não mudam). O beiral e o rebordo são
  hastes redondas, os espigões e a cumeeira levam a capa (as peças da Fase 95), e o fundo do beiral fecha a caixa.
- **As lucarnas** (`_dormers`): na água de baixo da frente e de trás, uma por célula menos as pontas, com a frente em pé a
  `DORMER_AT` da água, o telhadinho de duas águas, o vidro e o caixilho. As lucarnas antigas (Fase 39) não entram na
  mansarda.

## Como testar

- `tests/presentation/test_phase124_mansard.gd`: só as casas dos investidores sem ala e de duas águas ganham a mansarda; a
  água de baixo passa de 60° e a de cima é mais deitada; a altura do telhado não muda; as lucarnas têm vidro; a chaminé
  segue acima do telhado.
- Captura: `tools/capture_phase124.tscn` (ilha plana: seis casas dos investidores separadas, com e sem a mansarda;
  `mansardas.png`, `mansardas_de_tras.png`, `mansardas_de_cima.png` e `mansarda_de_perto.png`).
