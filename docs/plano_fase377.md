# Plano da Fase 377 — Alicerce de cantaria

**Estado: feita em 08/11/2026**, a segunda do roteiro `docs/plano_fases_376_380.md` (peças do MegaKit III).

## O problema

O alicerce que aparece no pé de todo prédio (0,15 m acima do chão), o plinto dos lotes em barranco (Fase 39) e os degraus da porta
saíam na pedra lisa da paleta do Kenney, uma cor só, sob as paredes de reboco e cantaria do MegaKit.

## O que entrou

- **`BuildingKit._mega_ashlar_box`**: caixa na cantaria do pacote (camada 4, UV2.x = 5) em escala de verdade, pelas quatro fiadas
  aparelhadas de baixo da textura (`MEGAKIT_ASHLAR_V`, `MEGAKIT_ASHLAR_PER_M`: blocos de ~0,5 m, fiadas de ~0,27 m). A face alta é
  partida em faixas de quatro fiadas, de cima para baixo, para a textura não esticar.
- Com o MegaKit, o alicerce do `_build` vai para ela (no `_mega_extra`), e o `plinth` monta o plinto, o terraço do pátio e os degraus
  pelo `_stone_block` (a malha inteira com a UV2). O cache dos plintos é esquecido na troca do kit.
- A fase 380 do roteiro (degraus de pedra do pacote) ficou coberta aqui: os degraus já saem na cantaria.

## Como testar

- `tests/presentation/test_phase377_ashlar_footing.gd`: o alicerce na cantaria, nas fiadas certas da textura; o plinto de 3 m sem
  UV fora da faixa; o Kenney sem nada da cantaria.
- Captura: `casa_no_barranco_a.png` no `tools/capture_phase39.tscn` e `02_vila_de_perto.png` no `tools/capture_phase300.tscn`
  (`F:\ferramentas\capturas\fase377`).
