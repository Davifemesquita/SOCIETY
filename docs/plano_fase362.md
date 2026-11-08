# Plano da Fase 362 — Peso das janelas

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_361_365.md` (ligar o MegaKit). O MegaKit segue desligado
por padrão (`SOCIETY_MEGAKIT=1` liga).

## O problema

Com a janela do pacote inteira (Fase 361), a GPU subia ~0,7 ms e os prédios grandes triplicavam: igreja de 18.036 para 55.929
triângulos, universidade de 17.684 para 54.041, a casa dos investidores de 27.606 para 33.244 (o pior de cada uma em 12
variantes). A janela larga em arco tem 276 triângulos só de moldura.

## A tentativa

Simplificar a moldura a 80% (`TRIM_KEEP_SHARE`): os níveis de detalhe do Godot andam em degraus grandes, e o primeiro já corta a
moldura pela metade ou mais (276 → 138, 136 → 36) — ela virava cacos como na Fase 360. A moldura fica inteira.

## O que entrou

- **A janela da forma só na fachada da frente** (`BuildingKit.window_index(spec, face)`, `opening(spec, face)`): nos lados e nos
  fundos vai a janela larga reta, a mais leve do pacote. As janelas acesas, os postigos e as cortinas leem o vão de cada fachada.
- O pior de cada um, agora: igreja 35.229, universidade 34.169, teatro 21.039, investidores 20.824 (Kenney 27.606), museu 20.793,
  engenheiros 18.720 (22.102), artesãos 13.420 (14.738), operários 12.606 (13.084).

## Medida (área de trabalho escondida, Alta, alternando, duas rodadas cada)

| | FPS médio | GPU média | primitivas |
|---|---|---|---|
| Kenney | 64,8 / 64,9 | 14,5 / 14,5 ms | 19,9 M |
| MegaKit | 63,9 / 63,9 | 14,7 / 14,7 ms | 20,2 M |

## Como testar

- `tests/presentation/test_phase362_window_weight.gd`: só a frente com a janela da forma, o Kenney sem fachada, e as casas até 20%
  acima do Kenney (no pior de cada classe ficam abaixo).
- Captura: `tools/capture_phase95.tscn` com `SOCIETY_MEGAKIT=1` (`F:\ferramentas\capturas\fase362\dia\`).

## Fica para depois

- Igreja e universidade (~35 mil) passam do teto de 30.000 do `test_building_kit` com o MegaKit ligado (Fase 363).
- Uma linha escura atravessa as paredes de pedra a meia altura do andar, nas casas dos artesãos (Fase 365).
