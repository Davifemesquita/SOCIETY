# Plano da Fase 356 — Onda de perto

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_355_359.md` (mar aberto). De perto, o Anno mostra ondas de
alguns metros com a crista mais clara; o nosso mar de perto tinha só o picado miúdo (Fase 296), e o marulho (Fase 284) é de longe.

## O que entrou

- **A onda de perto** no `shaders/water.gdshader`, entre o marulho e o picado: um trem de `wave_lengths_m.x` (12 m) em volta do vento,
  com a fase torcida por um ruído largo (`wave_twist_amount`, 15) — as cristas compridas e irregulares através do vento —, na normal
  (os vértices não mudam), de inclinação `wave_slopes.x` (0,11), mais forte com o vento; some de `wave_near_m` (120 m) a `wave_far_m`
  (250 m). A crista clareia `wave_crest_light` (10%) no fim do shader.
- **A cintilação mais fraca** (`glint_strength` 1,0, era 3,0): com o sol na frente da câmera (Fase 330), os pontos dela perto da praia
  viravam manchas brancas grandes.

## As tentativas (`fase356\lab\`, `lab2\`)

Três trens cruzados (12, 8 e 5,5 m, em três direções) faziam um favo de bolinhas regulares no mar inteiro, visível até com 30% da força;
com um trem só e a fase bem torcida, o reflexo do céu ondula em faixas compridas e o brilho do sol vira um caminho de reflexos alongados
nas cristas. Os outros dois trens ficam no uniforme, em zero, e a crista é pesada pela inclinação de cada trem.

## Medida

Um seno e um ruído por pixel de água de perto: medido no fim do roteiro.

## Como testar

- `tests/world/test_phase356_near_waves.gd`: o bloco entre o marulho e o picado, a crista no fim, um trem só, a crista pesada pela
  inclinação, a cintilação mais fraca e o shader compilando (com tela). O da Fase 110 (com tela).
- Captura: `tools/capture_phase280.tscn` com `CAPTURA_SO=dia`; a primeira tentativa em `F:\ferramentas\capturas\fase356\depois\`, a que
  ficou em `depois2\`.
