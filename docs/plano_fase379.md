# Plano da Fase 379 — Caixote do pacote

**Estado: feita em 08/11/2026**, a quarta do roteiro `docs/plano_fases_376_380.md` (peças do MegaKit III).

## O problema

O caixote da carga (as pilhas de estoque, a carroça, o cais, o convés dos navios, a colheita dos campos) é o do Kenney Pirate Kit,
que na luz do jogo saía rosado e liso, ao lado das peças de madeira do MegaKit.

## O que entrou

- **`tools/pack_megakit.gd`**: o caixote de tábuas do pacote (`Prop_Crate`, 230 triângulos) nas `PROPS`, em metros do pacote
  (`assets/models/megakit/crate.res`).
- **`CargoKit._pack_crate`**: com o MegaKit, a peça `CRATE` é ele, encolhido ao lado de `ITEM_M` com a base em y = 0, com o material
  do kit dos prédios (`BuildingMaterials.kit()`), que lê a madeira do pacote pela UV2. Todos os que usam o `CargoKit.mesh` mudam
  juntos. Sem a peça ou sem o MegaKit, o do Kenney.
- **`CargoKit.forget`**: a troca do kit (`BuildingKit.use_megakit`, `reset_megakit`) esquece as peças da carga.

## Como testar

- `tests/presentation/test_phase379_pack_crate.gd`: com o MegaKit, o caixote na madeira do pacote, do tamanho de `ITEM_M`, no chão
  e com o material do kit; sem ele, o do Kenney.
- Captura: `batatas_de_perto.png` no `tools/capture_phase157.tscn` (`F:\ferramentas\capturas\fase379\dia`), comparada com a da
  Fase 157 (`F:\ferramentas\capturas\fase157`).
