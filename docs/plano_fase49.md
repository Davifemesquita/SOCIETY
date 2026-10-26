# Plano da Fase 49 — Desfazer e planta

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
oitava fase do roteiro de `docs/plano_melhorias.md`. **O save sobe para a versão 16** (com migração). As regras abaixo
(janela, reembolso, a planta não reservar a célula) são **proposta à espera do dono**. Nada apareceu na tela do dono
(testes sem janela; benchmark na área de trabalho escondida).

## 1. Desfazer e refazer (`sim/undo_history.gd`, `sim/commands/undo_command.gd`, `Simulation`)

- `Simulation.execute_undoable(comando)`: obra, estrada, demolição, substituição e plantas entram no histórico (mover,
  pausar e o resto só são executados). Cada ação guarda o que o comando mexeu: dinheiro e estoque da ilha antes e
  depois, estradas, árvores e árvores derrubadas do retângulo dele, os prédios que criou e os que tirou (o próprio
  registro, com classe, moradores e carroça) e as plantas.
- `undo_last` executa o `UndoCommand`: tira o que a ação criou, devolve o que ela tirou e volta o retângulo. **No mesmo
  tick, os valores exatos** (construir e desfazer deixa o mundo idêntico); **depois, o reembolso integral** (a diferença
  que a ação fez no dinheiro e no estoque; o que a produção mudou nesse meio tempo fica). Recusado sem mexer em nada se o
  lugar mudou (outro prédio no lote, estrada refeita) ou fora da janela.
- `redo_last` refaz o mesmo comando (que volta ao histórico); uma ação nova apaga o que havia para refazer.
- **Janela**: `GameConfig.undo_window_s` (120 s de jogo), no máximo `undo_max_entries` (30). Fundar colônia e mexer na
  frota ficam fora. **O histórico não vai para o save e zera ao trocar de mundo** (carregar).
- Na demolição desfeita, o especialista que estava no prédio volta para a lista sem posto, e o estado de incêndio/doença
  recomeça (registrado; o resto do prédio volta inteiro).

## 2. Plantas (`sim/plan_record.gd`, `PlacePlanCommand`, `RemovePlansCommand`, `BuildPlansCommand`)

- `WorldState.plans` e `next_plan_id`, no save. A planta confere lugar e terreno, não cobra nem confere desbloqueio, e não
  cobre outra planta. **Não reserva a célula** para as regras da simulação: um prédio de verdade pode ser feito por cima;
  a planta então fica listrada até o jogador apagá-la.
- Construir as plantas da ilha: cada uma pelo `PlaceBuildingCommand` de sempre, em ordem de id; a que der certo vira
  prédio e sai, a que não der fica. Pelo histórico: desfazer tira todas as casas e as plantas voltam.
- Fantasma: `presentation/plan_view.gd` (`PlanView`), o mesmo da prévia da Fase 33 (`build_ghost.gdshader`), em azul;
  listrado em vermelho a que não pode mais.

## 3. Substituir em área (`ReplaceCommand`)

- Ctrl + arrastar na obra: todo prédio no retângulo, do mesmo tamanho e de outro tipo, vira o escolhido no mesmo lugar e
  rotação; o velho devolve a fração de demolição, o novo é cobrado inteiro; terreno, desbloqueio e o custo de todos
  conferidos antes de mexer. O entreposto fica. Pelo histórico.

## 4. Interface

- `BuildTool`: tudo passa por `execute_undoable`; `plan_mode` (a obra vira planta, o arrasto de demolir apaga plantas),
  `replace_drag`, `build_plans`, `undo`, `redo`. A prévia fica azul no modo planta e mostra o retângulo de substituir.
- HUD: ao lado da busca, planta (liga e desliga), construir as plantas, desfazer e refazer (acesos só com o que fazer).
- Teclas: **Ctrl+Z** desfaz, **Ctrl+Shift+Z** ou **Ctrl+Y** refaz (fixas: `InputActions.CTRL_KEYS`); o modo planta é a
  ação `build_plan`, sem tecla padrão.

## 5. Nome e grupo da rota (a Fase 47 deixou para cá)

- `TradeRoute.name` e `group` no save; `RenameRouteCommand` (corta em 32 letras); na janela de rotas, dois campos
  na rota escolhida, e a lista mostra o nome (ou "Rota N") com o grupo na frente, ordenada por grupo.

## 6. Save versão 16

- `SaveSystem.SAVE_VERSION = 16`; `SaveMigrations.from_15_to_16` cria `plans` vazio e `next_plan_id = 1` e dá nome e
  grupo vazios a cada rota. O save da 15
  abre sem perda; sem a migração, o mundo sem `plans` é recusado (teste).

## Números

- Benchmark (área de trabalho escondida, ilha cheia): obra pelo histórico 14,6 ms e o desfazer dela 15,3 ms (limite 50
  ms); tick, quadro, salvar (56 KB) e carregar iguais.

## Fica de fora

- Stamps (layouts salvos); desfazer de comércio, diplomacia, rotas, mover e pausar.

## Como testar

- `tests/sim/test_phase49_undo_plans.gd`: construir e desfazer idêntico (casa e estrada sobre árvores, com custo);
  demolição desfeita com moradores e estradas; reembolso integral depois de ticks; janela vencida; refazer e a ação nova
  que apaga o refazer; lugar mudado recusa sem mexer; histórico fora do save e zerado com o mundo; plantas sem custo,
  sobrepostas recusadas, no save; construir plantas (a coberta fica) e desfazer; apagar por área; substituir e desfazer;
  versão 16 e a migração; plantas salvas e carregadas pelo `SaveSystem`; nome e grupo da rota no save e na migração.
- `tests/ui/test_phase49_interface.gd`: modo planta, construir, desfazer e refazer pela ferramenta, arrasto de demolir
  apagando plantas; Ctrl+arrastar substituindo; teclas fixas com Ctrl; botões da HUD e fantasmas (listrado quando
  coberto); a lista de rotas ordenada por grupo com o nome; textos nas duas línguas.

## Pronto quando

Ctrl+Z e Ctrl+Shift+Z funcionam dentro da janela; plantas sobrevivem a salvar e carregar; saves antigos abrem sem perda.
**Proposta à espera do dono**: a janela (120 s), o reembolso integral, a planta não reservar a célula e a subida do save.
