# Plano da Fase 209 — Lanterna nas carroças

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_205_209.md` (estandarte, bebedouro e lanterna, a partir
das capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A lanterna** (`CartView.lantern_mesh`, `lantern_glass_mesh`, `LANTERN_AT`): a haste de madeira no canto da frente da
  caçamba, à esquerda, o braço de ferro para a frente e a lanterna pendurada nele (os quatro montantes, a base, o chapéu de
  quatro águas e a argola), com o vidro no material dos lampiões da rua (`shaders/night_glow.gdshader`: apagado de dia, aceso
  à noite). O vidro é marcado pelo alfa 0 da cor do vértice: a camada das carroças não tem cor de instância.
- **Na malha do corpo** (`with_lantern`): a armação e o vidro entram como superfícies a mais da malha da carroça, na mesma
  instância. A primeira versão tinha duas camadas próprias, reposicionadas a cada quadro com as 200 carroças do benchmark, e
  custava ~0,7 FPS; na malha do corpo não custa conta nenhuma por quadro.

## Como testar

- `tests/presentation/test_phase209_cart_lanterns.gd`: a malha do corpo leva duas superfícies a mais (a última no night_glow, o
  vidro com alfa 0) e é a da camada das carroças; a lanterna fica à frente da caçamba, atrás da ponta dos varais, acima dela.
- Captura: `tools/capture_phase209.tscn` (a rua das carroças na ilha plana, de dia e à noite).
