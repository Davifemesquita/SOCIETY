# Roteiro das Fases 290 a 294 — Rocha e costa

**02/11/2026.** Quarto ciclo da ideação de 02/11/2026 (ver `docs/plano_fases_275_279.md`). A referência é o Anno aberto nesse
dia, em `F:\ferramentas\capturas\anno\`:

- a falésia sobre o mar (`c10_03`);
- a garganta do rio (`c10_04`);
- a montanha com os abetos no pé (`c10_09`);
- a costa de pedra da cidade (`c10_10`).

Como sempre, **só a ideia**: tudo é gerado no código.

## O diagnóstico

- **Rocha lisa.** As encostas e as falésias do Society são a textura de rocha cinza (Fase 261) sem estrutura. No Anno, a rocha tem
  estratos e sulcos descendo, com capim e musgo nas saliências.
- **Costa de dois tipos.** Nas temperadas do Society, a costa é praia de areia ou falésia. O Anno tem também a praia de seixos
  cinzentos junto das pedras, molhada na beira.
- **Pedra sem espuma.** No Society, a água encosta nas rochas soltas e nos rochedos sem a linha branca em volta.
- **Encosta pelada.** As encostas íngremes do Society só têm o pinheiro-anão (Fase 207) e o cascalho (Fase 162). No Anno, os
  abetos sobem pela rocha.

## As fases

| Fase | O quê |
|---|---|
| 290 — Estratos na rocha | no `shaders/terrain.gdshader` e no `shaders/sea_rock.gdshader`, camadas quase horizontais e sulcos descendo pela encosta (ruído esticado ao longo da inclinação), com a borda de cima de cada camada mais clara e a de baixo na sombra |
| 291 — Musgo nas saliências | nas partes quase planas da rocha (pela normal), manchas de capim e musgo, mais no lado da sombra e menos nas faces de pé |
| 292 — Praia de seixos | nas costas baixas das temperadas encostadas em rocha, a areia vira seixos cinzentos e redondos (no shader e com pedrinhas do recheio), escuros e brilhantes junto da água |
| 293 — Espuma nas pedras | a linha de espuma fina e animada em volta das rochas e dos rochedos na água, pela profundidade da pedra logo abaixo da superfície (a conta da espuma do Ocean, mais fina) |
| 294 — Abetos na rocha | abetos pequenos e esparsos (a espécie da Fase 275, reduzida) presos nas saliências das encostas íngremes e das falésias das temperadas, pelo recheio |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push. Peça nova do
recheio vai no fim do enum e da lista dela.

## Estado

A fazer.
