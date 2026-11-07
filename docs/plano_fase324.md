# Plano da Fase 324 — Fundo na sombra

**Estado: feita em 05/11/2026**, a última do roteiro `docs/plano_fases_320_324.md` (garganta de perto). No rio estreito e fundo, a
água do fundo da garganta saía clara (o céu refletido), como se estivesse ao sol; no Anno ela é escura, na sombra das paredes.

## O plano

- **Arquivos**: `shaders/water.gdshader` e o teste novo.
- **Risco**: a sombra da falésia da Fase 314 olha só na direção do sol; no fundo da garganta o que falta é o céu tapado dos dois
  lados. Uma conta de abertura do céu pela altura da terra (do mapa da costa, já no shader) custa leituras por pixel: só no canal.
- **Como testar**: o teste novo, a captura da garganta com antes e depois pelo `CAPTURA_AGUA`, a do rio aberto da Fase 122 e o
  benchmark.

## O que entrou

- **`sky_closed`**: em `GORGE_DIRECTIONS` (8) rumos, o ângulo mais alto da terra a até `gorge_reach_m` (9 m, `gorge_steps` 3), pelo
  seno, na média: 0 com o céu aberto, perto de 1 entre paredes altas.
- **No canal**, depois da sombra da falésia: `deep` (de `gorge_closed` 0,25 a 0,7 do céu tapado, vezes o canal) escurece a cor e a
  refração até `gorge_shade` (0,7), corta o reflexo (`gorge_specular` 0,85), deixa a água fosca (`gorge_roughness` 0,6) e apaga a
  cintilação. Com só a cor e o reflexo (a primeira tentativa, `gorge_shade` 0,55), o reflexo do céu pela rugosidade baixa ainda
  deixava a água azul-clara.

## Medida

31,1 FPS (322: 30,9), GPU 26,8 ms (322: 27,1), com a máquina ainda na condição lenta. Neutra.

## Como testar

- `tests/world/test_phase324_gorge_shade.gd`: a abertura do céu pela altura da terra, o escuro, o reflexo, a rugosidade e a
  cintilação no canal, depois da sombra da falésia; o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase317.tscn -- <pasta>` (com `CAPTURA_AGUA=gorge_shade=0` para o antes); em
  `F:\ferramentas\capturas\fase324\`: `antes`, `depois` (a primeira tentativa) e `depois2` (o que ficou), e o rio aberto da Fase 122
  em `rio_depois` (igual ao de `fase319\rio_depois`, só um pouco mais escuro junto da parede alta).
