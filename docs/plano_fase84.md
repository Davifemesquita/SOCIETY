# Plano da Fase 84 — Palmas e cota da festa

**Estado: feita em 28/10/2026, a pedido do dono** ("pode fazer tudo isso", sobre o que a Fase 83 deixou de fora: os
pedestres olharem para o céu e baterem palmas, e a cota extra da festa só para a gente da ilha dela). Só visual: a
simulação, o save e as assinaturas não mudam.

## O que entrou

- **Animação de ver os fogos** (`tools/vat/cheer_clip.gd`, `CheerClip`): os pacotes da Quaternius não estão nesta
  máquina e não se sabe se trazem palmas, então a animação é gerada no código a partir da parada (`idle`): o pescoço
  (`NECK_PITCH`) e a cabeça (`HEAD_PITCH`) erguidos para o céu e as mãos batendo palmas diante do peito, `CLAPS` vezes por
  volta (fecham de repente e abrem devagar, `hands_gap`). Os braços vão por IK de dois ossos (ombro, cotovelo, pulso),
  com o cotovelo para baixo e para fora; o resto do corpo é o da parada, no mesmo ritmo, e a volta fecha sem salto. A
  frente do corpo sai do tornozelo para a ponta do pé (`body_frame`).
- **Quinta animação no VAT**: o `tools/bake_pedestrians.gd` grava a `cheer` depois das quatro da biblioteca (os dois
  `.res` dos pedestres foram refeitos; 1.570 e 1.600 triângulos, como antes). O shader dos pedestres passou de
  `clips[4]` para `clips[8]` e a `PedestrianView` completa a tabela até `MAX_CLIPS`. O carregador do glTF do gerador virou
  `static func load_gltf` (o teste usa).
- **Quem vê a festa bate palmas** (`Crowd.CLIP_CHEER`, `CHEER_SHARE`): parado num lugar de ver os fogos, 80% olham para o
  céu batendo palmas e os outros ficam parados olhando o mastro. Cada um começa num ponto da volta (`agent.phase`): as
  palmas não saem em coro.
- **A cota extra só para a ilha da festa** (`_quiet_full`, `_festive`, `_quiet_out`): na hora dos fogos, o pedestre de
  uma ilha sem festa só sai de casa se a parte da multidão de fora da festa ainda não encheu a cota da hora. A contagem
  de quem está na rua fora da festa é refeita a cada rebalanceamento (2 s) e somada a cada partida; quem volta para casa
  entre duas contagens só é descontado na seguinte.

## Números

- Constantes de apresentação (`CheerClip.*`, `CHEER_SHARE`), não de jogo.
- Benchmark: o mundo do benchmark não tem festa e ninguém usa a animação nova; a tabela do shader cresceu de 4 para 8
  `vec4` (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase84_cheer.gd`: no esqueleto de verdade, as mãos fecham na palma e abrem no meio da
  batida, ficam à frente do peito e acima de onde ficam na parada, a cabeça olha para cima e a volta fecha; quem vê a
  festa usa a animação e ninguém mais; com a ilha sem festa construída primeiro (os pedestres dela vêm antes na fila), a
  rua dela fica na cota da noite e a da festa enche. Sem a correção da cota, este último falha (conferido).
- `tests/tools/test_vat_baker.gd`: os pedestres têm as cinco animações.
- Capturas: `tools/capture_phase84.tscn -- <pasta>` (a da Fase 83 e, de perto, alguém batendo palmas olhando para cima:
  `palmas.png` e `palmas_lado.png`; em `F:\ferramentas\capturas\fase84`).

## Fica de fora (proposta à espera do dono)

- Palmas no ritmo dos estouros (hoje cada um bate no seu ritmo, o tempo todo).
- Som de palmas e vivas junto dos fogos.
