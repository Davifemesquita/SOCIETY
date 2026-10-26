# Plano da Fase 35 — Costa viva (nossa)

**Estado: em andamento desde 25/10/2026**, com a confirmação do dono do produto ("pode seguir para a próxima fase").
Quarta fase do roteiro de `docs/plano_melhorias.md`. Só apresentação: nenhuma altura, contorno ou assinatura muda, e
nada vai para o save.

**Sem tela nesta fase**: por decisão do dono, nada abre na tela do PC dele (nem capturas, nem benchmark). O que precisa
de GPU fica para quando ele liberar; a compilação dos shaders é conferida pelo CI (que roda com tela, no xvfb).

## 1. Distância até a costa com sinal (`TerrainBake.signed_coast`, `CoastField`)

- Por região, das alturas dos cantos que o `region_corners` já gera: positiva na terra (até a água), negativa na água
  (até a terra), com a linha d'água no meio entre os cantos, cortada em `coast_field_max_m`. Por chanfro em duas
  passadas (o mesmo do bake da Fase 34), não pela EDT exata: o erro fica em até ~10% fora dos eixos e das diagonais,
  invisível numa faixa de espuma, e a conta divide a distância até a água com o bake.
- `CoastField.compose`: os campos das regiões num mapa só do arquipélago (a água é uma malha que segue a câmera), de 2 em
  2 m, mar fundo fora das regiões; textura de um canal float.

## 2. Água (`shaders/water.gdshader`, `WaterView`)

- Cor de plataforma de areia na água rasa junto da costa, pelo campo (`shelf_m`, `color_shelf`).
- Bandas de espuma que andam para a praia e a espuma fina na linha d'água (`shore_foam_width_m`); a espuma por
  profundidade do Boujie continua (píer e navio).
- Ondas acalmadas perto da costa (`wave_calm_m`), no vértice.

## 3. Terreno (`shaders/terrain.gdshader`)

- Fundo raso pintado pela distância da costa (areia clara no raso, escurecendo até `seabed_deep_m`), no lugar do tipo
  de chão da célula: é o que tira o halo marrom junto da vila.
- Cáusticas no fundo raso (duas camadas de ruído em sentidos opostos).
- Espraiado e areia molhada no **mesmo ritmo** da espuma da água (`shaders/coast_waves.gdshaderinc`, mesma fase e mesmo
  `TIME`), até `swash_m` areia acima, e uma linha de detritos logo acima dele.

## Fica de fora

Oceano FFT, reflexo planar, SSR (Fase 37), contorno das ilhas (Fase 45), o flow map dos braços de mar. **A suavização
visual da linha d'água** também fica: a receita das notas ainda precisa ser validada contra os portos (construídos na
costa) e, sem poder olhar a tela, não há como validar.

## Riscos

- Sem captura, o visual (cores, largura da espuma, força das cáusticas) vai sem ser visto até o dono liberar a tela:
  os números ficam em uniformes, fáceis de ajustar.
- O campo em GDScript alonga o jogo novo.
- Ordem de transparência da água com a espuma: a espuma é da própria água, não um nó à parte.

## Como testar

- `tests/world/test_phase35_coast.gd` (sem tela): sinal e valor numa costa reta, corte em `max_m`, erro contra o
  euclidiano num poço, composição de regiões e mar fundo fora delas, determinismo e tempo na semente 1840, a
  `TerrainView` e a `WaterView` recebendo o mesmo campo; e, **com tela (no CI)**, os dois shaders compilando com os
  uniformes novos.
- O teste dourado do terreno segue passando.
- Quando o dono liberar a tela: capturas `03_litoral`, `07_vila_no_relevo` e `02_ilha_principal`, e o benchmark.

## Pronto quando

A 70 m a borda não lê como escada; a espuma anda para a praia; o halo marrom junto da vila sumiu; o jogo novo subiu
pouco (meta: até 0,5 s). As três primeiras só se confirmam na tela.
