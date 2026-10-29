# Plano da Fase 88 — Duas etapas e vivas calmas

**Estado: feita em 28/10/2026, a pedido do dono** ("pode continuar"; das propostas da Fase 87: a faixa calma das vivas
para pouca gente e a bomba de duas etapas). Só apresentação: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **Bomba de duas etapas** (`FestivalView.Shape.DOUBLE`, no fim do enum, peso 1,5): `DOUBLE_STARS` (10) estrelas grandes
  e rápidas que, ao apagar, estouram de novo em `DOUBLE_SPARKS` (12) faíscas na segunda cor sorteada. Usa o sub-emissor
  das partículas do Godot: cada bomba ganhou um filho `Sub` (`_burst`, com as faíscas montadas por `_sparks`), ligado
  só nesta forma (`SUB_EMITTER_AT_END`); as outras o desligam.
- **Vivas calmas** (`FestivalSounds.CHEER_SOFT_PATH`, `cheer_mix`, `_mix_cheers`): a faixa "Soft cheering - II" do mesmo
  pacote de Gregor Quendel (CC BY 4.0, crédito no `CREDITS.md`; `assets/audio/sfx/crowd_cheer_soft.mp3`, sem
  alteração). As duas tocam juntas em laço; até `CHEER_MIX_FROM` (0,35) do nível só a calma, a partir de `CHEER_MIX_TO`
  (0,8) só a forte, e entre elas a mistura em potência igual. Com 3 pessoas reagindo, só a calma; com 12, só a forte; ao
  sumir, a forte dá lugar à calma.

## Fica de fora

- **Cortar a gravação** (proposta da 87): pede o `ffmpeg`, que iria para o disco C (quase cheio), e não faz falta — a
  faixa toca em laço a partir de um ponto sorteado.
- **O som não foi ouvido** nesta máquina: falta o dono ouvir as duas faixas misturadas no jogo.

## Números

- Constantes de apresentação e de som, não de jogo.
- Benchmark: o mundo do benchmark não tem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase88_double_and_soft.gd`: a bomba tem o sub-emissor, a forma de duas etapas o liga com as
  quantidades e a segunda cor e as outras o desligam; a forma sai no sorteio; a mistura vai da calma à forte pelo nível
  (3 pessoas só a calma, 12 só a forte); as duas gravações estão lá.
- `tests/presentation/test_phase87_shapes_and_cheers.gd`: o sorteio segue os pesos das cinco formas.
- Captura: `tools/capture_phase88.tscn -- <pasta>` (a da 87 com `forma_dupla.png`: os grupos de faíscas espalhados, um
  por estrela; em `F:\ferramentas\capturas\fase88`).

## Proposta para depois

- Fogos sincronizados em salva (vários foguetes de uma vez no fim da noite, o "grand finale").
