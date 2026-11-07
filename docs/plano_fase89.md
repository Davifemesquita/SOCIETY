# Plano da Fase 89 — Grand finale

**Estado: feita em 28/10/2026, a pedido do dono** ("pode continuar"; proposta deixada pela Fase 88: uma salva de
foguetes no fim da noite de festa). Só apresentação: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **O grand finale** (`FestivalView.start_finale`, `advance_finale`, `finale_left`, sinal `finale_started`): às
  `FINALE_HOUR` (23h) de cada noite de festa, até `FINALE_WINDOW_H` depois, uma vez por noite (rearmado de dia), uma salva
  de 24 foguetes, um a cada `FINALE_GAP_S` (0,12 a 0,35 s), de um mastro sorteado, nas formas de `FINALE_SHAPES`
  (crisântemos, duas etapas, bolas e anéis, e seis salgueiros no fim: a chuva dourada). Enquanto a salva dura, os fogos
  de sempre esperam. O foguete leva a forma até o estouro (`Rocket.shape`, `fire(site, shape)`).
- **Mais bombas e foguetes no ar**: `FIREWORK_POOL` de 6 para 14 e `ROCKET_POOL` de 8 para 12.
- **Todo foguete estoura** (`burst_at`, `_burst_cursor`): sem bomba livre, a usada há mais tempo é reaproveitada. Antes
  o foguete sumia sem estourar quando as bombas estavam todas no ar — no teste da salva, 10 dos 24 sumiam.
- **Vivas pela gente batendo palmas agora** (`Crowd.cheering_count`, `FestivalSounds.on_burst(..., cheering)`): na
  salva, cada estouro pega pouca gente nova (quem reagiu bate palmas por ~2 s), e as vivas, que pediam 3 reagindo ao
  mesmo estouro, quase não tocavam no momento de mais festa (6 vezes na captura, nível mais alto 0). Agora contam também
  quem ainda bate palmas pelos estouros de antes: 41 vezes, até 63% do volume. As palmas de cada estouro seguem só quem
  reagiu a ele.

## Números

- Constantes de apresentação, não de jogo.
- Benchmark: o mundo do benchmark não tem festa; as 14 bombas e os 12 foguetes ficam parados (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase89_finale.gd`: a salva solta a lista inteira e todas estouram, acabando no salgueiro;
  sai em poucos segundos, um foguete de cada vez; às 23h uma vez por noite, rearmada de dia; os fogos de sempre esperam;
  as vivas seguem quem ainda bate palmas; a multidão conta quem bate palmas e zera depois.
- Captura: `tools/capture_phase89.tscn -- <pasta>` (`finale_meio.png` e `finale_chuva.png`; em `fase89.txt`, os estouros
  da salva e quantas vezes cada som tocou; em `F:\ferramentas\capturas\fase89`).

## Fica de fora (proposta à espera do dono)

- Um som próprio do finale (rufar ou a música da festa subindo) e a câmera indo sozinha para a praça às 23h.
