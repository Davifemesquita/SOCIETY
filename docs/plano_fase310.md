# Plano da Fase 310 — Blocos na face

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_310_314.md` (falésia de verdade; o Anno não foi aberto: o
dono estava no PC, e a ideia vem das capturas guardadas). No Anno, a falésia é uma parede de rocha em blocos grandes de faces
planas; no Society, a face era a rocha com os estratos (Fase 290) e as pedras redondas encaixadas (Fase 56).

## O que entrou

- **`shaders/rock_strata.gdshaderinc`**, `block_factor`: nas faces de pé, um Voronoi 3D no mundo (`block_m` de 2,6 m, mais baixo que
  largo) parte a rocha em blocos, cada um com o seu tom (`block_tone`) e o seu plano (a normal do bloco, torta pelo sorteio, pega
  mais ou menos da luz fixa `block_light_dir`), e as juntas escuras entre eles (`block_joint_m`, `block_joint_dark`). Fator de cor,
  sem mexer na normal (o terreno e as pedras têm tangentes diferentes).
- Chamado logo depois dos estratos na rocha do `shaders/terrain.gdshader` e nas pedras do `shaders/sea_rock.gdshader`.
- O roteiro pedia o Voronoi no plano da face; projetado pela normal, ele mudava a cada faceta da pedra e saía em riscos (conferido
  com o efeito exagerado). No mundo, em 3D, os blocos ficam inteiros.
- A normal quantizada do roteiro ficou de fora: a cor por bloco já dá a faceta, e o mapa de normais do terreno não tem a base da
  pedra.

## Medida

71,1 FPS, GPU 12,9 ms (309: 12,9). Neutra.

## Como testar

- `tests/world/test_phase310_cliff_blocks.gd`: o `block_factor` no include, chamado pelos dois shaders; os dois compilando com os
  uniformes novos (com tela).
- Captura do ciclo: `tools/capture_phase310.tscn -- <pasta>`; os recortes da face estão em
  `F:\ferramentas\capturas\fase310\face_antes.png` e `face_depois2.png`.
