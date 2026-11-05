# Plano da Fase 322 — Parede sem esticado

**Estado: feita em 05/11/2026**, a terceira do roteiro `docs/plano_fases_320_324.md` (garganta de perto). A face das paredes da
garganta tinha a rocha esticada em riscos que desciam a parede.

## O diagnóstico

O terreno já é triplanar na rocha (Fase 34), mas a projeção escolhia o eixo pela normal do **vértice**. A parede da garganta tem uma
célula de largura: cada vértice é dividido entre o alto plano e o leito, e a normal dele (a média) aponta quase para cima. Nos
pixels da parede, o triplanar lia a textura de cima (x, z) e a esticava parede abaixo. Os estratos e os blocos (Fases 290 e 310), que
pesam pela inclinação da normal, também ficavam fracos ali.

## O plano

- **Arquivos**: `shaders/terrain.gdshader` e o teste novo.
- **Risco**: a normal da face muda de um triângulo para o outro, e a projeção pula junto (quinas duras). Por isso ela é misturada à
  do vértice, e a derivada sai fora do `if` da rocha (derivada em fluxo não uniforme não vale).
- **Como testar**: o teste novo, a captura da garganta com antes e depois pelo `CAPTURA_TERRENO` e o benchmark.

## O que entrou

- **`shaders/terrain.gdshader`**: `face_normal` pelas derivadas da posição no mundo; `blend_normal`, a do vértice misturada à da face
  em `wall_face_blend` (0,7); o triplanar da rocha pesa as três projeções por ela, com o expoente em `triplanar_sharpness` (4, o de
  antes), e os estratos e os blocos usam a mesma normal. O musgo segue pela do vértice.
- Ficaram de fora o 1 (só a face: as quinas entre triângulos ficavam duras) e o expoente 2 (a troca suave dava imagem dupla).

## Medida

30,9 FPS (321: 31,3), GPU 27,1 ms (321: 26,7), com a máquina ainda na condição lenta. Neutra.

## Como testar

- `tests/world/test_phase322_wall_projection.gd`: a normal da face fora do `if`, o triplanar, os estratos e os blocos por ela, a
  mistura entre 0,5 e 0,9 e o expoente de antes; o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase317.tscn -- <pasta>`; em `F:\ferramentas\capturas\fase322\`: `antes` (`wall_face_blend=0`),
  `depois_07` (o que ficou), `v_mix06` e `v_exp2` (as variantes comparadas).
