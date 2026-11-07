# Plano da Fase 248 — Caixotes de vidro

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_245_249.md` (coelho, cogumelo e pedra, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`GlassCrateView.sites`): em cada vidraria e janelaria, nas duas células do meio de um lado pelo `SideYard` — o de −X do
  modelo, depois o de trás e por fim o de +X (a boca do forno da vidraria, Fase 137, fica no +X) —, fora da célula do carrinho de
  mão da Fase 172; guardado pelo `SideYard.remember`. O recheio e as bombas deixam as células limpas.
- **O pátio** (`crate_mesh`, `_crate`): o cavalete em A de madeira com as chapas de vidro de pé encostadas dos dois lados, cada uma
  um pouco mais para fora, e os caixotes de ripas com palha e duas vidraças saindo por cima, dois no chão e um em cima. Um
  MultiMesh.

## Como testar

- `tests/world/test_phase248_glass_crates.gd`: em cada rotação os caixotes ficam num lado da vidraria (nunca na frente), encostados
  nela; com uma célula bloqueada eles mudam de lado; o vinhedo não tem; o recheio e as bombas deixam as células; os caixotes cabem
  nas duas células.
- Captura: `tools/capture_phase248.tscn` (a ilha plana; `vidro_de_perto.png`, `vidro_e_predio.png`, `vidro_de_longe.png`).
