# Plano da Fase 44 — Primeira tela

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
terceira fase do roteiro de `docs/plano_melhorias.md`. Nada muda no gerador nem no save. Nada aparece na tela do dono
(testes sem janela; capturas na área de trabalho escondida).

A carta no fundo do menu e o som do fim da partida são **proposta à espera do dono** (o roteiro dava a escolha entre a
gravura e o diorama 3D: ficou a gravura, que é o fallback que o roteiro pedia de qualquer jeito e não custa GPU no menu).

## 1. Fundo do menu (`ui/screens/menu_background.gd`)

- Sem a grade de 96 px: a carta gravada (a mesma `ArchipelagoMap.engrave` da janela de rotas, na escala cheia) de um
  arquipélago de semente fixa, desbotada no papel, com o grão por cima, a rosa dos ventos e a moldura de sempre.
- Sai de uma thread enquanto o menu já está na tela (~1,6 s); até lá, o papel liso. Deriva devagar (90 s de período);
  parada com "reduzir movimento". Sem tela (testes), só o papel.
- Os botões entram um a um, esmaecendo (parados com "reduzir movimento"); já usavam as variações da Fase 43.

## 2. Prévia do jogo novo (`ui/screens/archipelago_preview.gd`, `new_game_dialog.gd`)

- `ArchipelagoPreview`: o mundo da semente pelo mesmo `ArchipelagoGenerator.new_world` da partida (as mesmas alturas,
  provado em teste pelas impressões digitais) e a carta gravada, numa tarefa do `WorkerThreadPool`; nada toca a árvore.
- O diálogo mostra a carta ao lado das opções, refeita depois de um respiro de 0,35 s a cada troca de semente ou de
  tamanho: a prévia velha é cancelada (o resultado descartado) e a tarefa recolhida quando termina — fechar o diálogo
  no meio passa a prévia para `ArchipelagoPreview.adopt`, recolhida pelo `SceneFader` a cada quadro (nenhuma tarefa fica
  sem `wait_for_task_completion`, nada trava a tela). ~1,7 s para o arquipélago médio.

## 3. Som

- O fim da partida (`VictoryDialog`): a fanfarra do marco na vitória e o alerta mais grave e lento na derrota
  (`UiSfx.end_of_game`, com os efeitos que o jogo já tinha).

## Fica de fora

- O diorama 3D com o Sky3D e a câmera em trilho (o roteiro o deixava como alternativa; pede GPU no menu e warm-up).
- A pré-carga dos recursos do jogo durante o menu (`load_threaded_request` vaza `LoadToken` na 4.7.2; o jogo novo já
  gera o mundo em threads desde a Fase 42).
- Usar o mundo da prévia para começar a partida (a dificuldade e as opções mudam depois dela).

## Como testar

- `tests/ui/test_phase44_first_screen.gd` (sem tela): a prévia tem as mesmas impressões digitais do mundo da partida e a
  carta do tamanho da carta náutica; a prévia cancelada não devolve nada nem deixa tarefa; o diálogo cancela e refaz
  depois do respiro; o fundo sem a grade e o menu abrindo em menos de 3 s (~85 ms); o tempo da prévia; o som do fim da
  partida; as chaves.
- Capturas: `tools/capture_phase44.tscn` (o menu com a carta pronta e o jogo novo com duas sementes).

## Pronto quando

O menu não tem grade e tem movimento; trocar a semente mostra a carta em poucos segundos sem travar a interface; o dono
aprova a gravura (ou pede o diorama) e o som.
