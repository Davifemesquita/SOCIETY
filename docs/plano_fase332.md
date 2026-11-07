# Plano da Fase 332 — Casca sem laranja

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_330_334.md` (luz e sombra), **no lugar do "pé das árvores"**
do roteiro.

## Por que mudou

O roteiro pedia uma mancha de sombra de contato debaixo de cada árvore. Depois da Fase 330 (o sol na frente da câmera), a sombra do
sol aparece no capim e no chão da mata, que desde a Fase 306 já escurece debaixo das copas: as árvores assentam no chão sem a mancha
(captura `03_mata_alta_de_perto` da Fase 331, de perto). Uma camada a mais de manchas custaria memória e desenho sem mostrar nada.
O que saltava de perto eram os troncos do pinheiro-silvestre, em laranja vivo, como palitos coloridos no meio da mata.

## O plano

- **Arquivos**: `presentation/tree_model.gd` (`PINE_UPPER_BARK`), o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: perder o tronco avermelhado que distingue o pinheiro.
- **Como testar**: o teste novo e a mata de perto da captura do ciclo.

## O que entrou

- O alto do tronco do pinheiro em (0,5; 0,35; 0,25), castanho-avermelhado (era (0,62; 0,36; 0,2)): ainda mais claro e mais quente
  que o pé do tronco, sem o laranja que a saturação da cor viva exagerava.

## Medida

Só cor: sem custo de quadro.

## Como testar

- `tests/world/test_phase332_pine_bark.gd`: a casca de cima com pouca saturação, sem vermelho demais e ainda mais clara e mais quente
  que a de baixo.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase331\depois\`, depois em
  `F:\ferramentas\capturas\fase332\depois\`.
