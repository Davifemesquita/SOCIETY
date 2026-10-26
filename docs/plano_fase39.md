# Plano da Fase 39 — Prédios assentados

**Estado: em andamento desde 26/10/2026.** O dono do produto pediu para fazer todas as fases que faltam, com os
benchmarks e todos os testes possíveis (`/goal` de 26/10/2026). Oitava fase do roteiro de `docs/plano_melhorias.md`. Só
apresentação: a simulação, o save e o gerador não mudam. **Nada aparece na tela do dono**: os testes rodam sem janela, e
o benchmark e as capturas rodam numa área de trabalho escondida do Windows (`F:\ferramentas\desktop_oculto.ps1`: a GPU
desenha, mas a janela nunca aparece).

As paletas e as regras por classe são **proposta à espera do dono** (o roteiro pede a aprovação dele): ficam em
constantes da `BuildingView` e do `BuildingKit`, fáceis de trocar.

## 1. Variação estável (`BuildingKit.variation_hash`)

- Um número pelo id, pelo tipo e pela rotação: o mesmo prédio sai sempre igual, depois de salvar e carregar. A variação
  nunca muda o lote, a porta nem o número de andares (teste).
- **Cumeeira e beiral** em três degraus (0,85/1,0/1,18 da altura de antes; 0,3/0,4/0,5 m) pelo resto do id por 3: casas
  construídas em fila têm ids seguidos, então duas vizinhas nunca ficam com o telhado na mesma altura (telhados
  escalonados). O beiral fixo `ROOF_OVERHANG_M` passa a ser o padrão de `Spec.overhang_m`; o prédio que não é casa tira
  o beiral pelo tipo.
- **Chaminé** no degrau do meio e **lucarnas** no mais alto (telhado de duas águas, só onde o telhadinho fica abaixo da
  cumeeira: nos camponeses a água é baixa demais). Cada malha nova custa ~18 ms, então o beiral e o que vai no telhado
  seguem o degrau: 3 telhados × 3 degraus × 2 janelas por classe (74 malhas para 600 casas, 1,5 s; antes eram 30).
- **Paletas** (`BuildingView.palette_of`): quatro por tipo; a 0 é o tom de antes, as outras puxam matiz, saturação e
  brilho da parede e trocam o telhado da casa por outro do mesmo material (terracota, telha escura, castanho, ardósia;
  tábuas em três tons). No prédio que não é casa a parede só varia um terço disso. A **"invertida"** (caixilho e
  madeiramento claros, `instance uniform trim_paint`) numa casa de reboco ou tijolo a cada cinco.
- **Desvio** de até 1 cm e 0,5° no modelo (não no nó: ícone e seleção não mexem).

## 2. Assentar no chão (`BuildingKit.seat`, `plinth`)

- O piso do prédio de modelo sobe da altura média do lote para o **canto mais alto**: a parede de cima não afunda no
  barranco. A `WindowLightsView` e a prévia de construção usam o mesmo ponto.
- **Plinto**: só no lote em barranco (onde a pedra precisa descer mais que o alicerce do kit, ou a porta fica alta), uma
  malha à parte (filha do modelo, em cache pela forma e pelas medidas a 5 cm) que desce do piso até 0,3 m abaixo do canto
  mais baixo. O pátio da frente (quintal, bancas, varanda, plataforma) vira terraço de pedra no nível do piso, com o muro
  de arrimo em volta.
- **Degraus** diante da porta quando ela fica acima do chão da frente (até quatro, de 18 cm, 28 cm de piso); no quintal
  dos camponeses, diante do portão. Varanda, bancas e plataforma de carga já têm os degraus e as rampas delas.

## 3. Forma por tipo

- **Entreposto lê como armazém** (`Spec.storehouse`): empena alta na frente, portas de carga em arco alternadas no térreo,
  janela pequena, as portas do sótão sobre a porta e o guincho sob a empena (o guindaste de porto continua).
- **Quintal dentro do lote dos camponeses**: o corpo da casa recua 0,6 m de cada divisa dos lados (`hall_side_gap_m`), e
  a cerca segue na borda do lote. Duas casas vizinhas ficam a mais de 1,2 m (antes se colavam).

## 4. Shader (`shaders/building_kit.gdshader`)

- **Vidro e caixilho**: o kit só tem o vão da janela (de dia, buraco preto). Cada janela ganha o vidro na espessura da
  parede (célula (0, 1) da paleta, que o kit não usa) e a cruz de madeira à frente; o vidro é escuro e liso e mostra o
  céu no ângulo raso (Fresnel). As lucarnas também.
- **Sombra de contato** (`instance uniform side_shade`): para cada fachada do referencial do prédio, a parte da divisa
  ocupada por prédio vizinho (campo, píer e decoração não contam); a fachada escurece de baixo para cima. Refeita nos
  vizinhos quando um prédio entra ou sai.
- **Musgo e limo** em manchas na faixa de baixo das paredes, junto com a sujeira de antes.

## Fica de fora

- Kit novo (Fase 50); andares visuais diferentes da capacidade; bevel falso por SDF.
- **Desgaste de aresta** no shader: sem dado de aresta nas peças do kit, fica para o kit da Fase 50.
- **Paredes-meia** de verdade (uma parede só entre casas iguais encostadas): ficam os telhados escalonados e a sombra de
  contato.
- Luz acesa nas lucarnas à noite (a `WindowLightsView` só acende as janelas das fachadas).

## Riscos

- `instance uniform` novo e auto-instancing: o material já usava seis; medir as draw calls no benchmark.
- Plinto e degraus invadindo a célula da frente: no máximo 4 × 28 cm, sobre a beira da rua (como degrau de verdade).
- Construir com a ilha cheia (17,9 ms antes, limite 50): uma variante nova de casa custa ~18 ms a primeira vez.

## Como testar

- `tests/world/test_phase39_buildings.gd` (sem tela): variação estável que não muda lote, porta nem andares; casas em
  fila sem telhado da mesma altura; beiral na malha; vidro em toda janela; lucarnas abaixo da cumeeira; entreposto
  armazém; camponeses recuados; casa no barranco no canto mais alto com plinto, degraus e janelas acesas no piso, sem
  plinto no plano; degraus pela altura da porta e malha do plinto em cache; sombra de contato com vizinho, refeita ao
  demolir, e sem sombra de campo; paletas e invertida; a vista não mexe na simulação; tempo e número de malhas.
- Os testes do kit, das janelas acesas e dos quintais (pasta `presentation`, sem tela) e a pasta `world`.
- Benchmark na área de trabalho escondida, comparado com o de antes da fase (draw calls, quadro e construção).
- Capturas da vila de perto e `07_vila_no_relevo` na área de trabalho escondida, para o dono aprovar as paletas.

## Pronto quando

Vizinhos da mesma classe não formam fileira contínua de mesma altura e telhado; o entreposto lê como armazém; janelas de
dia não são buracos pretos; construir segue abaixo de 50 ms; o dono aprova as paletas e as regras.
