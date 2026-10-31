# Plano da Fase 145 — Relógio da igreja

**Estado: feita em 31/10/2026**, primeira do roteiro `docs/plano_fases_145_149.md` (relógio, cais e cata-vento, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ClockView.dials`): na torre do campanário da Fase 18 (os prédios de `Silhouette.BELFRY`: a igreja), um
  mostrador em cada uma das duas faces de fora — a da frente e a do lado —, no fuste, a `HEIGHT_SHARE` do trecho entre o
  beiral e a sineira, `OUT_M` à frente da parede.
- **O mostrador** (`face_mesh`, `frame_mesh`): o disco claro, aceso à noite pelo `shaders/night_glow.gdshader` (o vidro
  dos postes, com o creme de dia em `day_color`), o anel de pedra em volta, o aro e as doze marcas de ferro (a das doze
  maior).
- **Os ponteiros** (`hand_angles`, `hand_mesh`, `set_hour`): o das horas e o dos minutos marcando a hora do jogo
  (`GameClock`: param na pausa), refeitos a cada quadro. Quatro MultiMesh com a caixa fixa do arquipélago
  (`GameScreen.clock_view`), refeitos na obra, na demolição e ao trocar de mundo.

## No caminho

- A primeira captura mostrou a parede da torre passando na frente de boa parte do mostrador: a `BuildingView` gira cada
  modelo até meio grau e o desloca até 1 cm pela variação (Fase 39). A conta virou `BuildingView.model_place`
  (`model_offset`, `model_yaw`), usada pelo modelo e pelo relógio.

## Como testar

- `tests/world/test_phase145_clock.gd`: a igreja tem dois mostradores, para fora, na horizontal, acima do beiral e
  `OUT_M` à frente da face da torre no lugar do modelo, um para a frente e o outro de lado, nas quatro rotações; outros
  prédios não têm; os ponteiros marcam 12h, 15h, 6h30 e 21h15.
- Captura: `tools/capture_phase145.tscn` (ilha plana: uma igreja; `igreja.png`, `relogio_de_perto.png` às 10h10 e
  `relogio_de_noite.png` às 21h45).
