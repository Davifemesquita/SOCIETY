# Plano da Fase 149 — Cata-vento no pasto

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_145_149.md` (relógio, cais e cata-vento, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`WindpumpView.spot`): junto do cocho de cada pasto (Fase 118, `RoadMask.trough_of`), `BESIDE_M` do meio dele
  para o lado do meio da cerca de trás, no chão. Só nas ilhas com relevo (o cocho é delas).
- **A torre** (`tower_mesh`): quatro pés de madeira afinando para o alto, com travessas e xis em três lanços, a plataforma
  no alto e o cano de ferro descendo pelo meio.
- **A roda** (`rotor_mesh`, `rotor_pose`, `turn`, `spin_of`): o cubo, `BLADES` lâminas de chapa torcidas, o aro e o leme
  vermelho na ponta da haste. Vira de frente para o vento em `TURN_S`, com o leme apontando para onde ele sopra, e gira
  mais depressa quanto mais forte ele é (nada abaixo de `CALM`, até `SPIN_MAX`), pelo vento do `WeatherView` no tempo de
  jogo (para na pausa). A torre é um MultiMesh parado; a roda, um MultiMesh refeito a cada quadro
  (`GameScreen.windpump_view`), refeitos na obra, na demolição e ao trocar de mundo.

## Como testar

- `tests/world/test_phase149_windpumps.gd`: o cata-vento fica dentro do pasto, a `BESIDE_M` do cocho, do lado do meio e no
  chão; a roda vira com o leme para o vento e só gira com vento; a ilha plana não tem.
- Captura: `tools/capture_phase149.tscn` (semente 1840: um pasto na ilha principal, o jogo andando um pouco para a roda virar
  e girar; `cata_vento.png` e `cata_vento_de_perto.png`).
