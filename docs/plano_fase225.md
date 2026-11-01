# Plano da Fase 225 — Lanterna na popa

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_225_229.md` (lanterna, lã e morcego, a partir das capturas
do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`SternLantern.stern_point`, `node`): em cada navio de modelo (o do jogador, o do comerciante e os das rivais), na ré —
  o z mínimo dos triângulos do casco (a proa fica em +z, como o bico de proa da Fase 26), no meio da largura do casco junto dela
  (o modelo do kit não tem o meio em x = 0) e na altura do alto do casco ali —, um pouco para dentro da borda. Filha do modelo,
  com a escala desfeita: as medidas são em metros. A busca do casco (`ShipRigging.hull_points`) é lida uma vez para a lanterna e
  para o cordame, antes de os dois entrarem no modelo (ela lê todas as malhas dele); as malhas da lanterna são feitas uma vez e
  divididas entre os navios.
- **A lanterna** (`frame_mesh`, `glass_mesh`): o pau de madeira, o braço de ferro para trás e a lanterna de quatro montantes com a
  base e o chapéu de quatro águas; o vidro no material dos lampiões da rua (`shaders/night_glow.gdshader`: apagado de dia, aceso à
  noite, marcado pelo alfa 0 do vértice).

## Como testar

- `tests/presentation/test_phase225_stern_lanterns.gd`: a popa de cada modelo fica do lado oposto da proa, perto do meio e acima
  da água, atrás de todo o casco; a vista pendura a lanterna em todo navio de modelo, em metros no mundo, com o vidro no material
  dos lampiões; o vidro fica atrás do pau, para fora da popa.
- Captura: `tools/capture_phase225.tscn` (os quatro navios na ilha plana; `popa_de_dia.png`, `popa_de_noite.png`,
  `navios_de_noite.png`).
