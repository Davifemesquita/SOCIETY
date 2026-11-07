# Plano da Fase 53 — Cor no jeito do Anno (grama, mata, areia, rocha, água e névoa)

**Estado: feita em 26/10/2026, a pedido do dono** (a parte gráfica que ficou de fora da Fase 52, olhando as capturas do
Anno 1800 dele em `F:\ferramentas\capturas\anno`; só a ideia, nenhum arquivo do jogo). As texturas seguem as do Poly
Haven (CC0); muda só o tratamento de cor no shader e os números das cores.

## O que entrou

- **Grama** (`shaders/terrain.gdshader`): `grass_grade` puxa para o verde, `grass_saturation` 1,45 satura, e a grama
  seca das cristas pesa menos (`dry_strength` 0,3 no lugar de 0,65). O amarelado de antes vira o verde vivo do Anno.
- **Mata no chão** (`forest_grade`), **areia clara de praia** (`sand_grade`, mais quente e mais clara) e **rocha escura**
  nas encostas e falésias (`rock_grade`).
- **Folhas** (`TreeModel`): carvalho, faia e pinheiro mais claros e saturados; a mata deixa de ser um bloco escuro.
- **Água** (`WaterView`): plataforma turquesa mais viva e mais larga (`color_shelf` (0,24; 0,76; 0,72), 40 m), raso um
  pouco mais forte e o fundo azul de mar aberto (`color_deep`).
- **Névoa**: a do céu (Sky3D) de 0,00035 para 0,0002 e a volumétrica de 0,004 para 0,0018: de longe a ilha aparece
  nítida, como no Anno, sem o véu azulado.
- **Falésia do v3**: desce em 1,6 célula em vez de 0,8 (com uma célula ela virava a escada da grade de 2 m), e em cima
  dela não se desenha mais praia (acima de 2,4 m o chão é o da terra: grama, e rocha pela inclinação). As assinaturas do
  v3 foram regravadas.

## Números

- Benchmark (alto, RTX 5060): quadro com tudo visível 11 ms (89 FPS), dia inteiro 87,9 FPS de média, GPU 10,6 ms;
  igual à Fase 52 (a cor não custa nada medível).

## Como testar

- `tests/world/test_phase53_colors.gd`: o tratamento de cor no shader, as folhas mais verdes, a névoa mais leve, a água
  turquesa e nada de areia acima de 2,4 m no v3.
- Capturas: `tools/capture_phase52.tscn -- <pasta>` (as mesmas vistas da Fase 52, para comparar).

## Fica de fora (proposta à espera do dono)

- O serrilhado da linha d'água e da falésia vem da grade de 2 m do terreno (a borda segue as células); alisar pede
  desenhar a costa com mais detalhe que a simulação (um contorno próprio ou subdividir a malha na beira).
- Rochedos e falésias com malha de rocha própria (hoje é o terreno com textura de rocha e as pedras da Fase 36).
- Palmeiras e mata tropical nas ilhas do sul; grama por região (mais seca no velho mundo, como o Anno faz).
- Se a cor nova fica ou se vira opção (como a "Cor de época" da Fase 37).
