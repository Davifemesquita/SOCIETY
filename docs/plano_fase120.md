# Plano da Fase 120 — Postes e fios

**Estado: feita em 30/10/2026**, primeira do roteiro `docs/plano_fases_120_124.md` (fios, riacho e mansarda, olhando o Anno
do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`PowerLineView.poles`): nas células de estrada (terra ou calçada) até o raio de cada usina
  (`BuildingDef.power_radius_cells`, o mesmo raio da eletricidade), uma a cada `POLE_EVERY` pelo desenho da grade
  (`posmod(x + 3y, 4) = POLE_REST`, que nunca é a célula do poste de gás, a do resto 0), um poste na beira do lado de fora da
  rua, `POLE_OFFSET_M` do meio da célula. Sem usina, nenhum poste.
- **O poste** (`pole_mesh`): fuste de madeira de `POLE_HEIGHT_M`, a travessa com duas escoras e dois isoladores de porcelana,
  com a cor no vértice; um MultiMesh do arquipélago. A travessa fica de través da direção média das ligações do poste
  (`arm_direction`).
- **Os fios** (`links`, `clear_span`): cada poste se liga a até `MAX_LINKS` vizinhos mais perto, até `LINK_M`, só quando o vão
  não passa por nenhuma célula de prédio (o fio entrava na parede da casa da esquina); de cada ligação saem dois fios de
  isolador a isolador, sem cruzar, caindo em curva (`HarborView.rope_span`), todos numa malha só.

## Como testar

- `tests/world/test_phase120_power_lines.gd`: sem usina não há poste; com ela, os postes ficam nas ruas até o raio e nunca
  na célula do poste de gás; cada ligação tem dois fios que caem no meio; a travessa fica de través da linha; nenhum fio
  atravessa um prédio; demolir a usina tira os postes.
- Captura: `tools/capture_phase120.tscn` (semente 1840: uma rua calçada com casas, a usina do outro lado e uma rua de terra
  subindo da ponta; `fios.png`, `fios_de_perto.png` e `fios_na_esquina.png`).
