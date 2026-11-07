# Plano da Fase 168 — Gaivotas no cais

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_165_169.md` (chão batido, feno e gaivota, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`PerchedGullView`, `GameScreen.perched_gull_view`): nos cabeços que a `HarborView` desenhou — píeres, cais de tábuas
  e cais de pedra (`HarborView.bollard_places`, guardado a cada desenho) —, um a cada `PERCH_EVERY` pela posição, uma gaivota de
  pé no alto do cabeço. A `HarborView` avisa pelo sinal `rebuilt` quando refaz o desenho, e as gaivotas acompanham.
- **Viradas** (`heading_at`, `advance`): cada gaivota olha para um lado sorteado por volta, cada volta de 4 a 11 s de jogo pela
  semente dela; o relógio anda com a velocidade do jogo e para na pausa.
- **A gaivota** (`gull_mesh`, cerca de 40 cm): corpo branco, asas dobradas cinza com a ponta preta passando da cauda, cabeça com
  o bico amarelo e as patas. Um MultiMesh, sem sombra.

## Como testar

- `tests/world/test_phase168_perched_gulls.gd`: sem cais, nenhuma; com o entreposto, parte dos cabeços tem gaivota, sempre no
  alto de um cabeço; o desenho do cais refeito marca as gaivotas; em um minuto cada uma vira algumas vezes, mas não a cada
  segundo, e o relógio parado não as mexe; o tamanho é o de uma gaivota.
- Captura: `tools/capture_phase168.tscn` (um entreposto na ilha principal, as gaivotas de bem perto e o cais de meia distância).
