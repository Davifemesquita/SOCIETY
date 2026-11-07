# Plano da Fase 107 — Barcos de pesca

**Estado: feita em 30/10/2026**, terceira do roteiro `docs/plano_fases_105_109.md` (cidade e porto, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save (o peixe sai da cabana como antes).

## O que entrou

- **O barco** (`FishingBoatView`, montada pela `GameScreen` ao lado do porto): um por cabana de pesca, com o casco a remo
  da `HarborView` e o mastro com a vela latina (`rig_mesh`).
- **O caminho** (`route`): o ponto de amarra é a água funda (`HarborView.afloat`) mais perto da cabana, andando do lado do
  mar (`HarborView.seaward`); o pesqueiro fica até `FISHING_GROUND_M` mar adentro na mesma direção, onde ainda boia. Sem água
  funda por perto, a cabana fica sem barco.
- **A volta** (`pose`, `phase_of`): em `CYCLE_S` de jogo, a ida suave (até `OUT_END`), a pesca numa volta de
  `FISH_CIRCLE_M` em torno do pesqueiro (até `FISH_END`, começando na direção da ida) e a volta, com o casco olhando para onde
  anda e balançando na onda. Desencontrada pelo id; no tempo de jogo (para na pausa). Com a cabana parada (ou pausada), o
  barco fica no ponto de amarra.

## Fica de fora

- Ao parar ou voltar a produzir, o barco pula para a amarra ou para o ponto da volta em que estaria (sem a viagem de
  volta). E na saída do pesqueiro ele vira de uma vez para casa.

## Como testar

- `tests/world/test_phase107_fishing_boats.gd`: amarra e pesqueiro em água funda, o pesqueiro mais longe da cabana; a volta
  começa e termina na amarra, passa pelo pesqueiro e anda sem salto (mil passos); na ida a proa olha para o pesqueiro; um
  barco por cabana, amarrado com ela parada.
- Captura: `tools/capture_phase107.tscn` (semente 1840: a cabana achada pelo `SiteFinder`, o barco na ida, no pesqueiro, na
  volta e de perto).
