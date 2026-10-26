# Plano da Fase 42 — Quadro estável e carregamento real

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
primeira fase do roteiro de `docs/plano_melhorias.md`. Nada muda no resultado da simulação nem no save. Nada aparece na
tela do dono (testes sem janela; benchmark na área de trabalho escondida).

## 1. Jogo novo em threads com progresso de verdade

- `sim/world/archipelago_job.gd` (`ArchipelagoJob`): uma tarefa do `WorkerThreadPool` por ilha (as ilhas são
  independentes: cada uma com o ruído e o sorteio dela, a partir da semente). O mundo é montado na thread principal, na
  ordem das specs, por `ArchipelagoGenerator.assemble` — o mesmo que o `new_world` usa —, então o resultado é idêntico
  com ou sem thread e com qualquer número delas. O progresso é a área das ilhas prontas e só sobe. Nada no job toca a
  árvore de cena nem a GPU (nada de `load_threaded_request`, pelo vazamento de `LoadToken` da 4.7.2).
- **Cortina** (`SceneFader.change_with_job`): escurece, gera mostrando a porcentagem, a barra e uma dica
  (`LOADING_TIP_1` a `8`, em pt_BR e en), troca a cena com o mundo pronto (`GameScreen.prepared_world`, usado uma vez)
  e mostra "Montando a partida…" enquanto as vistas são montadas. Direta (sem tela, testes): gera de uma vez e troca.
- **Menu** (`BootScreen._start`): o jogo novo do arquipélago passa pelo job; carregar e a ilha plana seguem como antes.
  A partida sem o menu (testes, ferramentas, benchmark) gera de forma síncrona, como antes.

## 2. O que já estava de pé (conferido)

- **Interpolação**: carroças e navios entre o tick anterior e o atual (`GameClock.clock.interpolation_alpha()`),
  pedestres e bichos pelo `visual_time`; nada pula de tick em tick no benchmark.
- **Recálculo de construção**: o estado derivado já é refeito sob demanda (o benchmark mede 0,0 ms de recálculo na hora
  da obra; o custo é o do comando e das vistas, ~18 ms, abaixo da meta proposta de 33 ms).
- **Ticks em 2× e 4×**: o `TickClock` limita os ticks por quadro (`max_ticks_per_frame`) e descarta o excedente — o 4×
  desacelera em vez de entrar em espiral.

## Fica de fora (medido)

- **Montar as vistas fora da thread principal**: depois da geração (~0,43 s em threads, ~1 s em série), montar
  terreno, água, árvores, recheio e prédios ainda leva ~5 s na thread principal, e a janela fica parada nesse trecho
  (com o texto "Montando a partida…" na cortina). Dividir esse trabalho em quadros ou em threads pede mexer em cada
  vista; fica para quando o tempo de jogo novo pesar no PC alvo.
- Dividir pedestres e carroças por distrito (a multidão custa 0,28 ms por quadro na CPU: não pesa).
- Rodar o CI com `threading/worker_pool/max_threads` 1, 2 e 3: o teste compara o job com o caminho direto, que é o
  mesmo resultado com qualquer número de threads.

## Como testar

- `tests/sim/test_phase42_threaded_world.gd` (sem tela): o mundo em threads é idêntico ao direto (o JSON do save e as
  impressões digitais das ilhas) em três sementes, e sem thread também; o progresso só sobe até 1; tamanho e
  dificuldade chegam ao mundo.
- `tests/ui/test_phase42_loading.gd`: a partida usa o mundo preparado uma vez só; a cortina direta gera e troca; as dicas
  estão traduzidas.
- Benchmark: a linha nova com a geração em série e em threads e o pior quadro durante a geração; tick p95 e pior quadro
  ao construir.

## Pronto quando

A cortina mostra progresso real e a janela não congela durante a geração; o tick p95 cabe nos 4 ms; o 4× não entra em
espiral; o pior quadro ao construir tem folga (abaixo de 33 ms). O dono mede no PC dele e aprova as metas de quadro.
