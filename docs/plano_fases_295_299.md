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

**A fazer.**
