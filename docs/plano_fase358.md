# Plano da Fase 358 — Onda quebrando

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_355_359.md` (mar aberto). Na ponta de terra e na praia aberta o
Anno tem uma onda que quebra e corre ao longo da costa; as nossas bandas de espuma (Fases 35, 281 e 295) eram todas iguais.

## A tentativa

A série inteira (sem as falhas) e começando mais longe (até 15 m) virou exatamente o defeito que a Fase 295 tinha tirado: uma fita branca
contínua solta no mar, longe da praia — na ilha tropical, em volta do rochedo (`fase358\depois\`). Os testes das Fases 281 e 295, que
procuram as linhas da banda, também pegaram.

## O que entrou

- **A série** no `shaders/water.gdshader`, depois dos trechos da Fase 295: uma crista em `breaker_every` (4) — o número da crista é o mesmo
  ao longo da banda inteira, e a série corre junto pela costa — é mais grossa (`breaker_sharpness` 0,72 no lugar de 0,93) e tem menos
  falhas (`breaker_gap_share`, 45% da falta das outras), no mesmo alcance das bandas (junto da praia). As linhas da banda de antes ficam
  como estavam.

## Medida

Um seno e um teste a mais por pixel de espuma da costa: medido no fim do roteiro.

## Como testar

- `tests/world/test_phase358_breakers.gd`: a série depois dos trechos, no mesmo alcance, ainda em trechos, fora do rio, e o shader
  compilando (com tela). Os das Fases 281 e 295 (com tela).
- Captura: `tools/capture_phase280.tscn` com `CAPTURA_SO=dia`; a tentativa em `F:\ferramentas\capturas\fase358\depois\`, a que ficou em
  `depois2\`.
