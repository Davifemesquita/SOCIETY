# Plano da Fase 384 — Cerca do pasto

**Estado: feita em 08/11/2026**, a quarta do roteiro `docs/plano_fases_381_385.md` (texturas do MegaKit).

## O problema

A cerca dos pastos (Fase 14) era um mourão e duas travessas de caixa lisa, numa cor só, enquanto a cerca dos quintais dos camponeses
já era a cerca de tábuas do MegaKit (Fase 375).

## O que entrou

- **`tools/pack_megakit.gd`**: a mesma cerca de tábuas do pacote (`Prop_WoodenFence_Single`) empacotada no lanço da cerca do pasto
  (`assets/models/megakit/pasture-fence.res`: 1 m em +x a partir do mourão, 0,95 m de alto).
- **`CropView.pasture_fence_pack`**: com o MegaKit, a camada `Fence` usa ela, no material do kit dos prédios (que lê a madeira pela
  UV2); os lanços, as aberturas para outro pasto e o encurtamento do último lanço não mudam. Sem o MegaKit, a cerca gerada.

## Como testar

- `tests/presentation/test_phase384_pasture_fence.gd`: a peça no tamanho do lanço; a camada com ela e o material do kit; o Kenney
  com a gerada. `tests/presentation/test_crops.gd` (contagem dos lanços) segue passando.
- Captura: `pasto_de_perto.png` no `tools/capture_phase118.tscn` (`F:\ferramentas\capturas\fase384\dia`, contra a `fase118`).
