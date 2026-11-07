# Plano da Fase 351 — Reboco sujo

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_350_354.md` (cidade gasta). As casas de reboco claro (engenheiros
(0,84; 0,74; 0,56) e investidores (0,93; 0,87; 0,73)) eram todas do mesmo creme quase branco; no Anno a rua tem casas de tons diferentes
lado a lado e o reboco não é branco.

## O que entrou

- **Um tom por casa** (`BuildingView._color`): nas classes de `PLASTER_TIERS` (engenheiros e investidores), a cor da classe vai
  `PLASTER_MIX` (0,75) para um dos `PLASTER_TONES` sorteado pelo hash da casa — creme (0,8; 0,72; 0,56), ocre (0,78; 0,62; 0,4), cinza
  (0,68; 0,66; 0,6) e rosa-velho (0,78; 0,62; 0,56) —, todos menos claros que o reboco dos investidores de antes. O claro e escuro por casa
  (`HOUSE_SHADE`) e a paleta (Fase 39) seguem por cima. A sujeira do pé e os escorridos da Fase 302 seguem no shader.

## Medida

Só cor: sem custo de quadro.

## Como testar

- `tests/world/test_phase351_plaster.gd`: os tons menos brancos que o de antes e distintos entre si; as duas classes e a mistura.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase350\depois\`, depois em
  `F:\ferramentas\capturas\fase351\depois\`.
