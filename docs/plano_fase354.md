# Plano da Fase 354 — Fumaça cheia

**Estado: feita em 07/11/2026**, a quinta e última do roteiro `docs/plano_fases_350_354.md` (cidade gasta). No Anno quase toda casa solta
fumaça; nas nossas (Fase 100) a fumaça era rala e sumia a 160 m.

## O que entrou

- **Mais casas fumegando** ao meio-dia: `ChimneySmokeView.BASE_AMOUNT` 0,55 (era 0,35); de manhã e à noite o pico segue o de antes.
- **Mais cheia, mais alta e maior** (`shaders/chimney_smoke.gdshader`): `alpha` 0,65 (era 0,55), `rise_m` 5 m (era 4) e `end_size_m`
  3,2 m (era 2,6).
- **Vista de mais longe**: some de 240 a 380 m da câmera (era de 160 a 260): na vista de cima da vila, as colunas de fumaça se veem.

## Medida (o roteiro das Fases 350 a 354)

Benchmark no estado rápido da máquina: 69,2 FPS, GPU 13,5 ms, carregar 6.967 ms (na mesma sessão, sem as rochas da Fase 349: 69,3–70,0
FPS, GPU 13,3–13,5 ms). Sem diferença medível.

## Como testar

- `tests/world/test_phase354_full_smoke.gd`: a parte de casas fumegando, a distância de sumir e os números do shader. O da Fase 100 (com
  tela).
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase349\depois\`, depois (com as Fases 350 a 354)
  em `F:\ferramentas\capturas\fase354\depois\`.
