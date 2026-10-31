# Plano da Fase 115 — Carreira do estaleiro

**Estado: feita em 30/10/2026**, primeira do roteiro `docs/plano_fases_115_119.md` (fazenda, taverna e estaleiro, olhando o
Anno do dono: só a ideia). Só apresentação: lê a encomenda do estaleiro (`ShipyardState`), nada muda na simulação nem no
save.

## O que entrou

- **A carreira** (`ShipwayView.site`, `ramp_mesh`): do lado do mar do estaleiro (o mesmo `HarborView.seaward` do píer sem
  cais), uma rampa de `RAMP_WIDTH_M` desce da beira do prédio (`RAMP_TOP_M` acima do chão) até `RAMP_BOTTOM_M`, passando
  `RAMP_PAST_WATER_M` da primeira água funda (entre `RAMP_MIN_M` e `RAMP_MAX_M`): duas vigas-guia, dormentes de través e
  esteios até o chão (ou o fundo) onde ela fica no alto. Sem água perto, ou com prédio ou estrada na linha dela, não há
  carreira.
- **O casco em obra** (`hull_mesh`, `hull_transform`): com uma encomenda, o casco deita na rampa sobre os picadeiros, a
  popa para o mar, do tamanho de `HULL_SCALE` do navio encomendado. Cresce com o progresso: a quilha; a roda de proa, o
  cadaste e as escoras (`POSTS_AT`); o cavername da popa para a proa (até `FRAMES_END`); o costado em `STRAKES` fiadas da
  quilha para cima (de `PLANKING_START` a `PLANKING_END`); a borda no fim; e o andaime dos dois lados enquanto a obra anda.
  O progresso é lido a cada `CHECK_S` em `STEPS` degraus, e só o casco que mudou de degrau é refeito. Pronto o navio, a
  encomenda sai e o casco some.
- Peças com a cor no vértice (`VertexShapes`), uma malha por carreira e uma por casco; a `GameScreen` monta a vista
  (`shipway_view`).

## Como testar

- `tests/world/test_phase115_shipway.gd`: a rampa desce da beira do estaleiro até a água funda; o casco cresce com o
  progresso, fecha na proa e sobe nas pontas; a vista mostra o casco só com a encomenda, a popa mais baixa que a proa, e o
  tira quando ela sai; uma estrada na linha da rampa tira a carreira.
- Captura: `tools/capture_phase115.tscn` (semente 1840: um estaleiro na costa da ilha principal; `casco_25.png`,
  `casco_60.png`, `casco_90.png`, `casco_de_perto.png` e `carreira_vazia.png`).
