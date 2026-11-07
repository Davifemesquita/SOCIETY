# Plano da Fase 51 — Fotos e retratos nos menus

**Estado: feita em 26/10/2026, a pedido do dono** ("figuras, como pessoas, formato fotos das casas e das fábricas,
com ideias da parte gráfica do Anno 1800"). Do Anno 1800 só vieram ideias de apresentação — nada de arquivo dele (regra
do projeto): cartões ilustrados no menu de construção, o painel do prédio com a imagem grande no topo e retratos pintados
das classes. A fonte dos retratos foi escolha do dono: pinturas de museu em domínio público.

## 1. Fotos dos prédios (`tools/bake_building_photos.tscn`, `ui/photo_grade.gd`, `ui/photos/`)

- Os nossos modelos, fotografados no próprio jogo: um prédio por vez na ilha plana, com o que o mapa desenha em volta
  (os campos da fazenda, o quintal, a rua na frente), às 16h30, de três quartos pela frente e um pouco mais baixo que a
  câmera do jogo, sem interface nem ícones, depois de a poeira da obra assentar. Enquadrado pelo tamanho real (largura,
  fundo e 1,7 × a altura; a fazenda pela casa com folga para os primeiros campos).
- Recorte 4:3, 320 × 240, e o acabamento de pintura (`PhotoGrade`: tom quente de óleo envelhecido, saturação um pouco
  menor, vinheta). 64 fotos: cada prédio e a casa uma por classe. O píer fica com o ícone (a ilha plana não tem água).
- Refazer: `godot --path . --resolution 1920x1080 res://tools/bake_building_photos.tscn` (precisa de GPU; no PC do dono,
  na área de trabalho escondida). Prédio novo sem foto cai no ícone.

## 2. Retratos (`tools/build_portraits.gd`, `assets/source/portraits/`, `ui/portraits/`)

- Pinturas do século XIX em domínio público do Art Institute of Chicago (imagens CC0; a API do Met respondeu 410):
  Pissarro (camponeses), Renoir (operários), Shirlaw (artesãos), T. Wheeler (engenheiros), W. M. Bennett (investidores),
  John Jackson (conselheiro) e Manet (comerciante). Créditos e números das obras no `CREDITS.md`.
- Recorte 4:5 pelo rosto, 256 × 320, o mesmo acabamento. Os desenhos do game-icons que eram os retratos saíram, e o
  `build_icons.gd` não os gera mais (não apaga as pinturas).

## 3. Interface

- Menu de construção: os cartões com a foto (104 × 78) e o nome embaixo (`Hud.PHOTO_CARD_HEIGHT`); estrada,
  paralelepípedo e demolir seguem com ícone.
- Painel do selecionado: a foto numa faixa de 150 px no topo (a da classe, na casa); o retrato da classe segue ao lado.
- Os retratos novos entram sozinhos onde os antigos estavam (população, painel da casa, conselheiro, comerciante).

## Números

- Benchmark (área de trabalho escondida, alto): quadro, obra e carregar iguais (GPU 11,5 ms, obra 18,3 ms).

## Como testar

- `tests/ui/test_phase51_photos.gd`: foto de cada prédio e de cada classe de casa (320 × 240), o píer sem foto; o
  acabamento (vinheta, tom, alfa) e o recorte 4:3; cada retrato 256 × 320 e cada pintura no `CREDITS.md`; o cartão com a
  foto e o painel com a foto da padaria e da casa da classe.
- Capturas: `tools/capture_phase51.tscn` (menus, painéis, população, conselheiro).

## Fica de fora (proposta à espera do dono)

- Fotos de época mais elaboradas (cenário com árvores e vizinhos, várias horas do dia), cartas de evento ilustradas como
  as do Anno, e retratos dos rivais e dos especialistas.
