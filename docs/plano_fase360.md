# Plano da Fase 360 — Paredes do MegaKit (ensaio)

**Estado: ensaio feito em 07/11/2026, desligado por padrão.** Pedido do dono ("arte de verdade", o item 1 da conversa sobre o
Unreal): trocar as peças de parede do Kenney Fantasy Town Kit pelas do **Medieval Village MegaKit** (Quaternius, CC0), a fonte que
o `assets/TODO_ASSETS.md` (Fase 50) já apontava para as casas. O pacote Standard (gratuito) tem 374 peças em glTF; as paredes têm
2 m de largura, a mesma célula do jogo, e 3,12 m de altura.

## O que entrou

- **`tools/pack_megakit.gd`**: lê os glTF de fora do repositório (`F:\ferramentas\arte\megakit\x`) e grava, para cada peça do
  `BuildingKit` (`wall`, as três janelas, a porta, o arco e o enxaimel `wall-wood`), uma malha `.res` em `assets/models/megakit/`
  já no referencial da peça do Kenney (largura de −0,5 a 0,5 em z, a face de fora em x = 0,5, o andar de 0 a 1 em y), com a moldura
  mais saliente na face (nada passa do lote), o vidro de duas faces e **a camada do material de cada vértice na UV2.x**. As peças
  são simplificadas para o nível de detalhe do Godot com até 55% dos triângulos (`KEEP_SHARE`). As texturas viram as pilhas
  `megakit_albedo_rough.png` e `megakit_normal.png` (reboco, madeira, tijolo, tijolo irregular, pedra e vidro), lidas como
  Texture2DArray, como as das Fases 9 e 19.
- **`BuildingKit.megakit_walls()`**: ligado só com `SOCIETY_MEGAKIT=1` (ou `use_megakit` nos testes e capturas); o `_parts_of` pega
  a peça do MegaKit no lugar da do Kenney, e o vidro gerado (`_glazing`) sai, porque a janela do pacote já tem o dela.
- **`shaders/building_kit.gdshader`**: o vértice com UV2.x > 0 lê a textura do MegaKit pela UV (com o mapa de normais); o reboco
  segue o material da parede do prédio (tijolo → tijolo, pedra → tijolo irregular, o resto reboco) e leva o tom dele; a madeira
  puxa para a do kit. Sujeira, hera, sombra do beiral e musgo valem igual. Tudo continua numa malha e num material só.

## Medida (área de trabalho escondida, Alta, a mesma janela de tempo)

| | FPS médio | GPU média | primitivas no quadro |
|---|---|---|---|
| Kenney | 65,1 / 64,9 | 14,4 / 14,5 ms | 19,9 M |
| MegaKit inteiro | 61,0 / 61,0 | 15,5 / 15,5 ms | 24,7 M |
| MegaKit simplificado (55%) | 64,9 / 65,1 | 14,4 / 14,4 ms | 18,8 M |

Simplificado, custa o mesmo que o Kenney.

## Por que fica desligado

Capturas em `F:\ferramentas\capturas\fase360\` (`mk0` Kenney, `mk1b` inteiro, `mk1c` simplificado, `noite0`/`noite1`):

- **Melhor**: a pedra e o tijolo com relevo de verdade, as janelas em arco com o caixilho e o vidro, as portas.
- **Quebrado**: tudo o que as fases de antes desenham em volta da janela foi medido no vão do Kenney — vergas e peitoris (Fase 18),
  arcos (Fase 99), guarnições (Fase 25), postigos (Fase 177), cortinas (Fase 217) e as janelas acesas à noite (Fase 4). Nas casas
  dos investidores as vergas cruzam o arco do pacote e as janelas perdem os montantes na simplificação.
- **Testes**: com ele ligado, os prédios grandes (igreja, teatro, universidade, prefeitura, museu) passam do teto de 30.000
  triângulos sem a simplificação, e os testes que procuram células da paleta pegam a UV de verdade das peças (pedem pular os
  vértices com UV2).

## O que falta para ligar

1. Medir o vão de cada janela do pacote e fazer as vergas, peitoris, arcos, guarnições, postigos, cortinas e janelas acesas
   seguirem esse vão (ou tirar os que o pacote já traz).
2. Simplificar só as paredes lisas e manter as janelas inteiras, e conferir o teto de triângulos.
3. Os testes da paleta pulando os vértices do pacote.
4. Telhado (as telhas redondas do pacote) e quinas, depois.
