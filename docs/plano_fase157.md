# Plano da Fase 157 — Caixas da colheita

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_155_159.md` (carneirinho, papoula e colheita, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quando** (`CropView.harvest_shown_at`): nenhum lugar da colheita antes do degrau `HARVEST_FROM` do crescimento (de
  `GROWTH_STEPS`); daí até o degrau cheio, mais lugares a cada degrau, todos os `HARVEST_SPOTS` perto da colheita. Colhido, o
  ciclo volta a zero e as peças somem (a conferência de sempre da `CropView`, a cada 0,5 s).
- **Onde** (`_harvest_places`, em cache pelo lote como as plantas): cada lugar no vão entre duas fileiras, num ponto sorteado
  pelo id ao longo delas (fora da cabeceira), com um par de peças lado a lado, cada uma girada à toa.
- **O quê**: as peças do `CargoKit` em `HARVEST_SCALE` — caixote na parreira e na folhosa tropical (`HARVEST_CRATES`), caixote
  e saco alternados na batata (`HARVEST_MIXED`), saco nas outras —, em dois MultiMesh (`HarvestCrates`, `HarvestSacks`); a peça
  que não aparece fica encolhida a zero. Os sacos são de juta mais escura (`HARVEST_SACK`, puxada de leve para a cor do bem e
  convertida para linear, como o material dos sacos lê a cor).

## No caminho

- Os sacos claros do estoque sumiam no meio do trigo e pareciam ovos; os caixotes empilhados pareciam um caixote sobre pernas.

## Como testar

- `tests/presentation/test_phase157_harvest.gd` (com janela): a quantidade por degrau só sobe e enche no degrau cheio; num
  campo de batata as peças aparecem perto do fim do ciclo e somem na colheita; ficam no campo, no vão entre as fileiras, no
  chão e no tamanho certo; trigo só saco, parreira só caixote, batata os dois.
- Captura: `tools/capture_phase157.tscn` (uma fazenda de trigo e uma de batata no fim do ciclo, de longe e de perto, e o campo
  depois da colheita).
