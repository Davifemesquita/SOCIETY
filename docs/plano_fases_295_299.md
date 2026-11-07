# Roteiro das Fases 295 a 299 — Mar e costa II

**02/11/2026.** Primeiro ciclo da ideação de 02/11/2026 (tarde), feita sem abrir o Anno (o dono estava usando o PC). A referência
são as capturas guardadas em `F:\ferramentas\capturas\anno\` (`c10_04` e `c10_10`, a costa de pedra e o mar aberto), comparadas
com o depois dos quatro ciclos anteriores (`F:\ferramentas\capturas\fase294\quatro_ciclos_antes_depois.png`). Como sempre, **só a
ideia**: tudo é gerado no código.

## O diagnóstico

- **Linha solta no mar.** A rebentação ficou fina (Fase 281). Mas a banda de espuma que anda para a praia (Fase 35) ainda
  desenha, longe da areia, uma linha branca contínua e paralela à costa por centenas de metros. No Anno, a espuma de fora vem
  em trechos curtos que se desfazem.
- **Mar liso de perto.** De perto, a água do Society só tem as ondas grandes do Ocean e o marulho (Fase 284). A do Anno tem a
  ondulação miúda e picada que quebra o reflexo.
- **Pedra sem rastro.** No Anno, a espuma que bate nas pedras sai levada em fiapos compridos pela corrente (`c10_10`). No
  Society, ela fica só colada na pedra (Fase 293).
- **Mar aberto claro demais de longe.** O azul-petróleo (Fase 280) é o mesmo perto e longe. No Anno, o mar de longe escurece e
  pega o céu pelo ângulo.
- **Raso sem fundo.** No raso, o Society pinta a plataforma turquesa lisa. No Anno, o fundo de areia e pedra aparece sob a água.

O degrau de cor que parecia haver no mar fundo da comparação dos quatro ciclos é só a redução da imagem: no tamanho cheio o mar
é liso.

## As fases

| Fase | O quê |
|---|---|
| 295 — Espuma em trechos | no `shaders/water.gdshader`, a banda de espuma da Fase 35 longe da linha d'água quebrada por um ruído ao longo da costa: trechos curtos que nascem, andam para a praia e se desfazem; junto da areia ela segue como está |
| 296 — Água picada de perto | um mapa de normais miúdo gerado no shader (duas camadas cruzando com o vento), só perto da câmera e sumindo com a distância, por cima das ondas do Ocean |
| 297 — Fiapos de espuma nas pedras | a partir do anel da Fase 293 e da costa de pedra, fiapos de espuma esticados na direção do vento, pela distância à costa com sinal (`CoastField`) |
| 298 — Mar escuro de longe | a cor do mar aberto escurece com a distância da câmera e o reflexo do céu cresce em ângulo raso (Fresnel mais forte), sem mexer no raso |
| 299 — Fundo à vista no raso | no raso das temperadas, o fundo do terreno (areia com ondulações e pedras) aparece pela transparência, com a cor da água pela profundidade por cima, no lugar do turquesa liso |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push. Teste de
shader confere a lista de uniformes cheia com tela (Fase 290).

## Estado

**Concluído em 02/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase295.md` a `docs/plano_fase299.md`),
testes, captura e benchmark (todas neutras, GPU de 12,6 a 12,6 ms). As três pastas da suíte passaram no fim (world 707,
presentation 389, ui 167).

Diferenças do roteiro:

- a linha branca solta no mar era a última banda de espuma da Fase 35 (achada pelo laboratório `CAPTURA_MAR=espuma`), não um banco
  de areia nem a espuma das pedras;
- os fiapos das pedras saíam como fitas lisas na primeira versão e ganharam um ruído miúdo que os renda;
- o mar de longe: o roteiro pedia o reflexo do céu mais nítido, o que clareava o mar; ficou o contrário (menos reflexo e o fundo
  mais escuro). O horizonte claro é o reflexo no ângulo raso e a névoa, e segue igual;
- no fundo do raso, as manchas de alga e as pedras se leem de cima; as ondulações ficam finas demais para a câmera do jogo.

O antes e depois de cada fase está em `F:\ferramentas\capturas\faseNNN\antes_depois.png` (295 a 299).
