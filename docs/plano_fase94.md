# Plano da Fase 94 — Som e câmera do grand finale

**Estado: feita em 28/10/2026**, a última do roteiro `docs/plano_fases_90_94.md` (a proposta deixada pela Fase 89). Só
apresentação e uma opção nova; nada muda na simulação nem no save.

## O que entrou

- **Rufar de caixa antes da salva** (`FestivalSounds.roll_stream`, `on_finale`, `ROLL_*`): gerado no código, como os outros
  sons da festa — batidas curtas de ruído em faixa (o estalo da pele e o chiado da esteira) cada vez mais juntas (de 0,11 a
  0,04 s) e mais fortes, por `ROLL_S` (2 s), e uma batida forte no fim. Toca na praça do grand finale.
- **O primeiro foguete espera o rufar** (`FestivalView.FINALE_ROLL_S`): a salva começa `FINALE_ROLL_S` depois do
  `finale_started`, e os fogos de sempre já esperam desde aí. O sinal passou a levar o mastro da praça
  (`finale_started(site)`).
- **Câmera no grand finale** (`Settings.finale_camera`, Opções → Jogo, "Câmera no grand finale", **desligada por
  padrão**): ligada, às 23h a câmera desliza até a praça (a mesma centralização do clique num aviso), menos no modo foto.
  Desligada, a câmera fica onde o jogador deixou — arrancar a câmera de quem está construindo seria intrusivo.

## Números

- Constantes de apresentação e de som; a opção é preferência do jogador (`[game] finale_camera` no `settings.cfg`).
- Benchmark: o mundo do benchmark não tem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase94_finale_roll.gd`: a salva começa com o rufar na praça e o primeiro foguete só sobe
  quando ele acaba; o rufar dura o mesmo que a espera e cresce (a segunda metade tem mais som que a primeira); a opção da
  câmera nasce desligada e grava.
- `tests/presentation/test_phase89_finale.gd`: ajustado ao rufar (o primeiro foguete espera `FINALE_ROLL_S`).
- Captura: `tools/capture_phase94.tscn -- <pasta>` (a câmera a 85 m da praça, a opção ligada só na execução: quando o
  primeiro foguete da salva sobe ela está a 0,1 m do mastro, `camera_na_praca.png`; grava `rufar.wav`; em
  `F:\ferramentas\capturas\fase94`).
- **O som não foi ouvido** nesta máquina: falta o dono ouvir o `rufar.wav` e o jogo.

## No caminho

- A primeira versão da captura dizia que a câmera não andava. Não era o jogo: a captura esperava "algum foguete no ar", e
  um foguete comum de antes da salva encerrava a espera no primeiro quadro. Ela passou a esperar o primeiro foguete da
  própria salva (`finale_left`).
