# Plano da Fase 350 — Telhado de madeira

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_350_354.md` (cidade gasta). No Anno a casa do povo tem telhado
de madeira gasta, marrom e cinza, e a terracota fica para os prédios maiores; a nossa vila era quase toda de terracota viva.

## O que entrou

- **Mais casas de tábuas** (`BuildingView.SHINGLE_SIXTHS`, no lugar de `SHINGLE_TIER`/`SHINGLE_EVERY` da Fase 303): quatro sextos das
  casas dos operários (era metade) e dois sextos das dos artesãos (era nenhuma), pelo hash, nas temperadas. Os camponeses seguem de
  sapê (Fase 130) e as classes de cima de telha.
- **Cinza ou marrom**: o parâmetro de instância `shingle` vale 1 (o cinza `shingle_color`) ou 2 (o marrom `shingle_brown`), metade de
  cada pelo hash (`BuildingView.shingle_tone`); o `shaders/building_kit.gdshader` escolhe a cor pelo valor, nas águas e na capa.

## Medida

Só cor: sem custo de quadro.

## Como testar

- `tests/world/test_phase350_wooden_roofs.gd` e o da Fase 303 (com tela): a parte de cada classe, nada nos camponeses, nas classes de
  cima nem nas tropicais, o tom pelo valor.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase349\depois\`, depois em
  `F:\ferramentas\capturas\fase350\depois\`.
