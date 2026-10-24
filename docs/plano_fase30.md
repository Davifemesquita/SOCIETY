# Plano da Fase 30 — Transição e retorno visual (nossa)

**Estado: executado em 24/10/2026 (versão 0.30.0)**, confirmado pelo dono do produto. O que mudou em relação ao
plano: as notificações só aparecem e esmaecem (o deslizar lateral não cabe no `VBoxContainer`, que manda na posição
dos filhos); a cortina tem `change_with`, para o teste rodá-la sem trocar a cena do executor; nos testes, a troca é
direta pela variável `SOCIETY_SEM_TRANSICAO`, porque a suíte roda com tela; as moedas saem acima das paredes do
entreposto (`BuildingDef.height_m`). As perguntas ficaram com as propostas daqui (500 moedas ou 5%; anima na pausa).
Detalhes em `AGENTS.md`, "Transição e retorno visual (Fase 30, nossa)". Texto original abaixo.

**Estado original: proposta, aguardando a confirmação do dono do produto.** Escrito em 24/10/2026 a partir do curso
"CRIE SEU JOGO 3D na Godot 4.2" (playlist `PL-oJEh-N3A3QwZnrr94NHHmkkyy9LtGib`): quase tudo do curso o projeto
já faz melhor; o que sobra de útil é retorno visual (*juice*), e o projeto não tem nenhum `Tween` até aqui.

Só apresentação e interface: **nada muda na simulação nem no save**.

## 1. Transição entre telas

- **Novo** `core/scene_fader.gd`, autoload `SceneFader` (registrar em `project.godot`): um `CanvasLayer` alto com
  um `ColorRect` preto e `change_to(path: String)` — escurece em ~0,35 s, troca a cena, clareia.
- Durante a montagem do mundo, um texto no centro: "Gerando o arquipélago…" (jogo novo) ou "Carregando…" (save),
  por chaves novas em `ui/translations/strings.csv` (`pt_BR` e `en`; nunca string literal).
- Pontos de troca hoje diretos:
  - `ui/screens/boot_screen.gd:163` (`_start`, jogo novo e carregar);
  - `ui/screens/game_screen.gd:434` (menu da partida → menu principal);
  - `ui/screens/game_screen.gd:450` (tela de vitória → menu principal).
  - O `boot_screen.gd:31` (benchmark) continua direto.
- O fim do escuro vem de um sinal próprio emitido no fim do `GameScreen._ready()` (o `_ready` monta o arquipélago
  inteiro e todas as vistas de forma síncrona). **Não contar com `SceneTree.scene_changed`** sem conferir que existe
  na 4.7.2.
- Com `DisplayServer.get_name() == "headless"`, nos testes e no benchmark: troca direta, sem fade.
- Enquanto visível, a cortina bloqueia mouse (`MOUSE_FILTER_STOP`) e teclado (consome em `_input`), para um atalho
  apertado no escuro não cair na cena que está saindo.

## 2. Contadores animados na barra (`ui/hud/hud.gd`)

- Dinheiro (`_money_label`, preenchido em `_refresh`, linha ~222) e população por classe (`_population_labels`) vão
  até o valor novo em ~0,4 s com `create_tween()` + `tween_method`; mata o tween anterior a cada atualização (o
  `_refresh` roda a cada `REFRESH_SECONDS` = 0,5 s).
- Ganho grande (comerciante, encomenda entregue): pulso de escala no rótulo (com `pivot_offset` no centro) e um brilho
  dourado rápido. Limite proposto: ≥ 500 moedas ou ≥ 5% do saldo (**confirmar com o dono do produto**).
- Respeitar a cor de saldo baixo (`UiPalette.paint`/`unpaint`): o brilho volta para a cor do estado, não para branco.
- **`instant`** (ligado no headless e nos testes): o texto vai direto ao valor final, porque os testes leem o rótulo
  logo depois de atualizar.

### Notificações (`ui/hud/notification_feed.gd`)

- `push`: o botão entra deslizando da lateral e aparecendo (`modulate:a` 0 → 1).
- `_remove`: a chave sai de `_items`/`_ages`/`_notices` **na hora** (o `shown()`, o limite `notice_max_visible` e os
  testes continuam iguais); só o desenho esmaece e o `queue_free` vem no fim do tween. Atenção: `shown()` percorre os
  filhos, e o botão que está sumindo não está mais em `_items`, então não aparece. `get_child(get_child_count() - 1)`
  no laço do limite precisa ignorar os botões que já estão saindo.

## 3. Dinheiro visível no mundo

- **Novo** `presentation/money_fx_view.gd`: algumas moedas (malha cilíndrica dourada gerada no código, sem asset
  novo) saltam em arco sobre o entreposto e um "+1.240" sobe e some (`Label3D`, billboard; nada no projeto usa
  `Label3D` ainda).
- Dispara em `EventBus.trader_visited(island_id, earned, spent)` (emitido em `sim/ships/trader_visits.gd:112`), no cais
  do entreposto da ilha (achar a posição por `sim/ships/harbors.gd`). Só quando `earned > 0`.
- `EventBus.mission_completed(def_id, bonus)` não traz a ilha: o "+X" aparece só ao lado do dinheiro na barra.
- Nunca no imposto de cada tick. No máximo 4 efeitos ao mesmo tempo, com nós reaproveitados (pool).
- Montar em `GameScreen._ready()` como as outras vistas.
- Pausa (`TickClock`, não `get_tree().paused`): os tweens seguem andando. Proposta: a interface anima na pausa;
  as moedas no mundo também (**confirmar com o dono do produto**).

## Riscos

- Testes que leem texto de rótulo ou contam filhos logo depois de uma ação: cobertos pelo `instant` e pela remoção
  imediata das chaves.
- Tipagem estrita: `tween_method` com `Callable` tipado; o valor animado é `float`, formatado com `Fmt.integer`.
- `_rebuild()` (troca de idioma) recria a interface: os tweens presos a nós que somem morrem com eles (o tween é do
  nó), mas confirmar que nada fica pendurado.
- Desempenho: desprezível, mas conferir no benchmark.

## Como testar

- Testes gdUnit4 novos (`tests/ui/test_phase30_feedback.gd`):
  - o `SceneFader` troca de cena e libera a entrada no fim (e é direto no headless);
  - o contador termina no valor exato;
  - a notificação sai de `shown()` na hora e o nó some depois;
  - o efeito de dinheiro dispara no `trader_visited` com `earned > 0`, não dispara com 0, e respeita o teto de 4.
- Suíte inteira: `tools/godot.sh testes` (conferir `pgrep -fa godot` antes) e o CI.
- Captura: `tools/capture_phase30.tscn` com o menu escurecendo, a tela "Gerando o arquipélago…" e as moedas no
  entreposto; registrar o comando em `AGENTS.md`.
- Fechamento: benchmark (`docs/benchmark.md`), seção "Transição e retorno visual (Fase 30, nossa)" e linha na tabela
  de fases do `AGENTS.md`, versão 0.30.0 em `project.godot`, commit.

## Fora desta fase (candidatas à 31)

Balas em arco, respingo e o navio atingido inclinando no combate naval (`presentation/ship_view.gd`,
`_animate_combat`); construir com squash & stretch e demolir com poeira e afundando (`presentation/building_view.gd`);
zoom suave mantendo o ponto do cursor (`world/camera/camera_rig.gd`); menu principal animado (só no primeiro
`_build`, não no `_rebuild` do idioma); som de vitória e derrota; SSR no nível ultra e gradação de cor de época.
