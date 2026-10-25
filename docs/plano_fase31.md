# Plano da Fase 31 — Obra e combate (nossa)

**Estado: executado em 25/10/2026 (versão 0.31.0).** O que mudou em relação ao plano: as balas caem até
`BALL_SHORT_M` antes do alvo e até `BALL_SPREAD_M` (14 m) para os lados, porque com 5 m em volta caíam debaixo do casco
da fragata e o respingo sumia; o adernamento usa seno em vez de cosseno (começa no prumo, vai ao máximo e volta: com o
cosseno ele já estava quase reto quando se olhava). Detalhes em `AGENTS.md`, "Obra e combate (Fase 31, nossa)". Texto
original abaixo.

**Estado original: proposta, escrita em 25/10/2026** a partir das candidatas que a Fase 30 deixou (`docs/plano_fase30.md`,
"Fora desta fase"). O dono do produto pediu "a próxima fase"; ficaram três das candidatas, as que se veem a cada
minuto de partida. Menu animado, som de vitória e derrota, SSR no ultra e gradação de cor ficam para depois.

Só apresentação: **nada muda na simulação nem no save**. Como na Fase 30, tudo é direto com
`SceneFader.is_instant()` (o `tools/godot.sh testes` liga `SOCIETY_SEM_TRANSICAO`), porque os testes leem a cena logo
depois da ação; as animações seguem com o jogo pausado (a pausa é do `TickClock`).

## 1. Construir e demolir (`presentation/building_view.gd`)

- **Construir** (`EventBus.building_placed`, não o `rebuild` do carregamento nem a casa que sobe de classe, que já
  tem andaime): o prédio nasce achatado e sobe com squash & stretch — escala `(1, 0.05, 1)` → passa do ponto
  (`y` 1,12, `xz` 0,94) → assenta em 1, em `BUILD_POP_S` ≈ 0,45 s — e solta um pouco de poeira na base (a mesma
  nuvem do andaime, extraída para `_dust(size)`).
- **Demolir** (`EventBus.building_removed`): o nó sai das contas na hora (`building_count()`, `_nodes`, `_labels`
  continuam iguais), esconde o ícone, afunda a altura do prédio em `DEMOLISH_S` ≈ 0,9 s, com poeira, e só então
  `queue_free`. No máximo `MAX_DEMOLISHING` ao mesmo tempo (demolir uma rua inteira com o arrasto): o excedente some
  na hora. O `rebuild` e a troca de mundo apagam os que estiverem afundando.

## 2. Combate naval (`presentation/ship_view.gd`)

- **Balas em arco**: cada `EventBus.ship_fired(atacante, alvo)` lança `BALLS_PER_SALVO` balas (esfera escura,
  malha única) do costado do atacante até o alvo em `BALL_FLIGHT_S`, num arco de `BALL_ARC_M`; cada bala cai num
  ponto espalhado alguns metros em volta do alvo (posição do alvo no momento do tiro). Pool de `MAX_BALLS`.
- **Respingo**: onde a bala cai, uma coluna de espuma (partículas brancas `one_shot`, `ABOVE_WATER`) — o mesmo
  `render_priority` da espuma do rastro, senão a água transparente a apaga.
- **Navio atingido inclinando**: o alvo ganha um adernamento amortecido (`HEEL_RAD` × `exp(-t/HEEL_DECAY_S)` ×
  `cos`), somado ao balanço das ondas no `_process`. Navio que afunda no meio da salva continua afundando como hoje.

## 3. Zoom suave no cursor (`world/camera/strategy_camera.gd`)

- Hoje a roda pula a distância de uma vez (mantendo o ponto do chão sob o cursor). Passa a ir até a distância-alvo
  em `camera_zoom_seconds` (novo no `GameConfig`, 0,12 s, com a validação), mantendo o ponto sob o cursor quadro a
  quadro; toques seguidos somam no alvo. `CameraRig.zoom()` continua imediato (os testes das contas usam).
- Instantâneo nos testes: `test_wheel_zooms_toward_the_point_under_the_cursor` lê a distância logo depois da roda.

## Riscos

- Testes que contam nós (`building_count`, `flash_count`, `sinking_count`) logo depois da ação: as contas saem na
  hora, e com `instant` nada fica pendurado.
- Prédio demolido afundando sob o chão e um novo no mesmo lugar: o novo nasce por cima; o velho some em < 1 s.
- Robô e rivais constroem muito: a animação é um `Tween` por prédio, de vida curta. Conferir no benchmark.
- O prédio afundando continua ocultando o que está atrás (`OccluderInstance3D`): tirar o ocultador ao demolir.

## Como testar

- `tests/presentation/test_phase31_juice.gd`:
  - construído: escala começa achatada, termina em `Vector3.ONE`; direto com `instant`;
  - demolido: sai de `building_count()` na hora; o nó afunda e some; teto de `MAX_DEMOLISHING`;
  - tiro: lança `BALLS_PER_SALVO` balas, elas somem ao cair e deixam respingo; teto de `MAX_BALLS`; o alvo aderna e
    volta;
  - zoom: a distância chega ao alvo e o ponto sob o cursor fica (já coberto no `test_game_screen_input.gd`, instantâneo).
- Suíte inteira: `tools/godot.sh testes` (conferir `pgrep -fa godot` antes) e o CI.
- Captura: `tools/capture_phase31.tscn` (prédio subindo, prédio afundando com poeira, balas no ar e respingo).
- Fechamento: benchmark, seção "Obra e combate (Fase 31, nossa)" e linha na tabela do `AGENTS.md`, versão 0.31.0,
  commit.
