# Roteiro das Fases 260 a 264 — Cor viva II

**01/11/2026.** Segundo ciclo do oitavo pedido "pode continuar" do dono, que pediu a cor mais viva, "parecido com o anno". O
primeiro ciclo (Fases 255 a 259) cuidou do meio do dia na ilha temperada; este cuida do que ele não cobria. O Anno **não foi
aberto** (esta sessão não tem o controle da tela); a referência são as capturas guardadas em `F:\ferramentas\capturas\anno\`
(só a ideia, nenhum número dele).

## O diagnóstico

As vistas novas do `tools/capture_phase260.tscn` (a vila do primeiro ciclo e mais os campos de perto, a falésia, a ilha tropical,
o fim da tarde, a manhã e a noite):

- **fim da tarde e manhã** cor de tijolo escuro: o sol do horizonte do Sky3D é laranja-avermelhado, a luz ambiente segue a cor
  dele e, com o sol a poucos graus, chega pouca luz; e a luz própria das folhas (Fase 256), que só apagava à noite, deixava a mata
  acesa sobre o chão escuro;
- **rocha** marrom-oliva nos rochedos e nas falésias, sem o contraste do cinza com o verde;
- **campos** cor de terra, as plantações miúdas e apagadas;
- **noite** quase preta fora das janelas;
- **sombras** fechadas no vão entre as copas e no pé das matas, quase pretas.

## As fases

| Fase | O quê |
|---|---|
| 260 — Hora dourada | o sol do horizonte em ouro claro, a exposição subindo com o sol baixo e a luz das folhas pela altura do sol |
| 261 — Rocha cinza | a rocha das falésias, dos rochedos e das pedras em cinza claro, com o contraste do verde |
| 262 — Campos coloridos | as plantações mais vivas (o verde das folhas, o dourado do trigo) sobre a terra mais rica |
| 263 — Noite azul | a noite legível: a lua mais forte e azulada, sem apagar as janelas e os lampiões |
| 264 — Sombra aberta | o vão entre as copas e o pé das matas menos fechados (a oclusão de ambiente mais leve) |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura (as vistas do
`tools/capture_phase260.tscn`, antes e depois), escolha no `tools/color_lab.tscn` quando há mais de um caminho, benchmark,
commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase260.md` a `docs/plano_fase264.md`),
testes, captura e benchmark (todas neutras). As três pastas da suíte passaram no fim (world 614, presentation 373, ui 167).
Diferença do roteiro: a Fase 264 virou a sombra aberta (a oclusão de ambiente mais leve), porque a parte do céu na luz ambiente
quase não mudava a sombra. O antes e depois do ciclo está em `F:\ferramentas\capturas\fase264\ciclo_antes_depois.png`.
