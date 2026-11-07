# Plano da Fase 335 — Estrada clara

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_335_339.md` (estrada no jeito do Anno). No Anno a estrada de
terra é uma faixa clara, cinza-bege, que se lê de longe; a nossa (Fase 38) saía da textura de terra laranja-tijolo e sumia no capim.

## O plano

- **Arquivos**: `shaders/terrain.gdshader` (a cor da terra das estradas), o laboratório da captura do ciclo (a vila de perto e de cima),
  o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: a estrada clara demais virar uma faixa branca; perder o claro e o escuro da textura.
- **Como testar**: o laboratório `CAPTURA_TERRENO` (`road_tint_mix`, `road_light`, `road_tint`), o teste novo e as vistas da vila.

## O que entrou

- **A terra cinza-bege**: a cor da textura vai `road_tint_mix` (0,75) para `road_tint` (0,6; 0,56; 0,47) na luminância dela (o claro e
  o escuro da textura ficam, como na grama da Fase 257) e clareia `road_light` (1,4), antes dos sulcos e das poças.
- **No laboratório** (`fase335\lab\`): sem nada, 0,6/1,25, 0,8/1,45 e 0,7/1,35 com o tom mais quente; as duas últimas já leem como as
  do Anno, a de 0,8/1,45 um pouco clara.

## Medida

Duas contas por pixel de estrada: sem custo de quadro à parte.

## Como testar

- `tests/world/test_phase335_light_road.gd`: o tom cinza-bege, a mistura e a luz, a graduação antes dos sulcos e o shader compilando
  com os uniformes (com tela).
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase334\depois\`, depois em
  `F:\ferramentas\capturas\fase335\depois\`.
