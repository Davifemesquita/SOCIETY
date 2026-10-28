# Plano da Fase 75 — Bichos no cercado

**Estado: feita em 28/10/2026, a pedido do dono** ("pode continuar"; proposta deixada de fora na Fase 74). Só
apresentação: a simulação, o save, o lote, as vagas e as assinaturas não mudam.

## O que entrou

- **Os bichos andam no cercado** (`PenWalk`): descansam (2,5 a 7 s de jogo), sorteiam um ponto, viram no lugar para ele e
  andam até lá (0,55 m/s, giro de 1,1 rad/s); sem caminho que caiba, só viram no lugar, como se pastassem. Elefante,
  girafa, leão, tigre e a manada de zebras; as araras ficam no poleiro e as peças do museu, paradas.
- **Nada atravessa a cerca**: cada pose é conferida pela pegada do corpo (`ExhibitModels.footprint`, o retângulo no chão
  com o bicho de frente para -Z, desfeito o giro com que a malha foi feita, `ExhibitModels.FACING`) contra a linha da
  cerca (`BuildingKit.pen_half`) com 0,1 m de folga: o alvo, o giro no lugar (a cada 0,05 rad, com 1 cm a mais) e, como a
  pegada é convexa e a cerca é um retângulo, o caminho reto inteiro. Sem nenhuma pose que caiba, o bicho fica parado.
- **O bicho grande demais fica menor no cercado** (`PenWalk.fit_scale`): o corpo ocupa no máximo 72% do lado menor do
  cercado (3,3 m por dentro). Só o elefante (3,7 m de comprimento com a tromba, fica com 64%) e, pouco, as zebras (91%)
  e a girafa (99%) mudam; leão e tigre ficam do tamanho da Fase 74.
- **Em `BuildingView`**: cada vaga vira um nó no meio dela com o corpo ("Body") dentro; o PenWalk põe o corpo
  (`_walkers`, `walk_animals` no `_process` pelos segundos de jogo, parado com o jogo pausado). Quando outra peça entra
  e as vagas são refeitas, o bicho segue o mesmo passeio (pela peça); a demolição leva tudo.
- A sorte de cada passeio vem do prédio, da vaga e da peça (`hash`), fora da simulação.

## Números

- Benchmark: o mundo do benchmark não tem zoológico; neutra (`docs/benchmark.md`). O custo é de cinco nós por
  zoológico, uma conta de retângulo por quadro.

## Como testar

- `tests/presentation/test_phase75_pen_walk.gd`: cinco minutos de jogo de cada bicho no cercado do zoológico sem a
  pegada sair da cerca em nenhum quadro, todos virando e andando; a pegada de frente para -Z; só o elefante menor; um
  cercado pequeno demais deixa o bicho parado; no `BuildingView`, o leão anda (o corpo no ponto do passeio), parado com
  o jogo pausado, as araras e a ânfora sem passeio, o passeio seguindo quando a girafa entra e sumindo com a demolição.
- Capturas: `tools/capture_phase75.tscn -- <pasta>` (no mundo plano, o zoológico cheio de perto em três momentos do
  passeio e de longe; em `F:\ferramentas\capturas\fase75`).

## Fica de fora (proposta à espera do dono)

- Cercado maior para o elefante (pediria mudar o lote ou a divisão do pátio), passos e cabeça mexendo, chão de capim e
  bebedouro nos cercados, as araras voando no poleiro, visitantes olhando os bichos.
