# Plano da Fase 32 — Medida e nitidez (nossa)

**Estado: concluída em 25/10/2026**, fechada pelo dono do produto com a medição no PC dele (RTX 5060, 1080p, Vulkan e
D3D12; `docs/benchmark.md`); 4K, VSync desligado, o export com o baker e as nuvens no olho ficaram para depois. Primeira fase do roteiro de `docs/plano_melhorias.md` ("Fase 32 — Medida e
nitidez"); o dono do produto pediu para retomá-la em 25/10/2026, depois que a sessão que fazia o levantamento fechou
antes de escrever este plano.

Só configuração e ferramentas: **nada muda na simulação nem no save**, e nenhuma forma muda na tela além do
antisserrilhado. A parte que só se faz no PC com a RTX 3060 (a primeira tabela de FPS, a escolha entre Vulkan e D3D12,
o export com o shader baker e as nuvens volumétricas na placa) fica pronta para o dono rodar e é o que fecha a fase.

## 1. Teste dourado do terreno (primeiro, antes de mexer em qualquer coisa)

- `tests/sim/test_terrain_golden.gd`: a assinatura (`ArchipelagoGenerator.fingerprint`) de cada ilha da semente 1840 no
  arquipélago padrão, de quatro sementes num arquipélago pequeno e da ilha plana (v0), gravada como número. Falha se o
  gerador mudar sem subir `VERSION`, se um ajuste no `GameConfig` mexer nos patamares do v1 ou se o motor mudar o
  `FastNoiseLite` (a subida à 4.8).

## 2. Antisserrilhado em todos os presets (`data/graphics/*.tres`, `GraphicsPresetDef`, `Settings.apply`)

- Sai o `msaa` (era 1 só no ultra; MSAA trocado em jogo recompila pipelines). Entram `screen_space_aa`
  (`Viewport.ScreenSpaceAA`: FXAA no baixo, SMAA 1x no médio e no alto), `temporal_native` (FSR 2.2 na resolução
  cheia, como AA, no ultra) e `fsr_sharpness` (0,2 no ultra).
- Com o FSR 2.2 ligado (escala abaixo de 100% ou `temporal_native`), o AA de tela desliga: o FSR já é o AA.
- Trocar o nível nas opções passa a acontecer atrás da cortina (`SceneFader.change_with`), com o texto "Aplicando os
  gráficos…": a compilação de pipelines da troca cai no escuro, e não na tela.

## 3. Régua de desempenho (`tools/benchmark.gd`, `docs/benchmark.md`)

- Trajeto de câmera fixo no dia inteiro, com o tempo bruto de cada quadro (`Time.get_ticks_usec`, não o `delta`), o
  tempo de CPU e de GPU do viewport (`viewport_set_measure_render_time`), o tick que caiu em cada quadro e os
  contadores `PIPELINE_COMPILATIONS_*`.
- Resumo com p50, p95, p99, 1% e 0,1% lows e o pior quadro; os quadros brutos vão num JSON versionado
  (`format` = 1) ao lado do `.md` (`user://benchmark.json` no executável).
- `-- --nivel N` e `-- --todos-os-niveis` (os quatro presets numa rodada, para a tabela da RTX 3060).

## 4. Primeira vez atrás da cortina (`presentation/warm_up.gd`)

- No jogo novo e no carregar, uma vez por partida: cada prédio do jogo (e a obra com andaime), poeira, fumaça, respingo
  e bala desenhados por alguns quadros na frente da câmera, fora da simulação, antes de a cortina clarear. Some sozinho.
- O benchmark mostra os contadores de pipeline antes e depois de construir um de cada prédio na partida.

## 5. `custom_aabb` nos MultiMeshes que mudam sempre

- Carroças, pilhas de estoque e carga do convés passam a ter uma caixa fixa (a da ilha ou da região), como a
  `PedestrianView`: cada atualização deixa de recalcular a caixa percorrendo as instâncias na CPU.

## 6. Export e captura

- `export_presets.cfg`: `shader_baker/enabled=true` no preset do Windows. O baker não roda em `--headless` (o export
  do CI e desta VM sai sem ele); o export de release sai do editor, no Windows.
- `tools/capture_phase32.tscn`: o conjunto padrão do roteiro (arquipélago 1.500 m, ilha 420 m, vila no relevo 110 m,
  litoral 70 m, jazida 55 m e a vila a 40 m) em cada preset, para comparar o serrilhado.

## Fica de fora

Qualquer mudança visual além do AA; trocar o driver sem número; ampliar as nuvens volumétricas; monitores por sistema
do tick no profiler do editor (o benchmark já mede por etapa).

## Riscos

- Ghosting do FSR 2.2 nos pedestres (VAT) e na água no ultra: só se vê na placa; se aparecer, o ultra volta ao SMAA.
- O SMAA e o FSR no lavapipe podem deixar a suíte e as capturas mais lentas: a suíte segue no nível baixo.
- Os contadores de pipeline podem se comportar diferente no lavapipe (não verificado): o teste confere o warm-up sem
  exigir zero.
- O D3D12 não tem cache de pipeline na 4.7.2: o primeiro carregamento nele é mais lento; medir antes de decidir.

## Como testar

- `tests/sim/test_terrain_golden.gd` (acima).
- `tests/core/test_graphics_aa.gd`: nenhum preset fica sem AA, nenhum usa MSAA, o `Settings.apply` põe no viewport o
  modo de cada um (e desliga o AA de tela com o FSR), a troca de nível pelas opções passa pela cortina.
- `tests/presentation/test_warm_up.gd`: o warm-up monta um de cada prédio e os efeitos, some sozinho e não mexe na
  simulação.
- `tests/tools/test_frame_stats.gd`: percentis e lows de uma lista de quadros conhecida.
- Benchmark na VM só para tick e geração; no PC, 1080p e 4K, Vulkan e D3D12, com e sem VSync:
  `Society.exe -- --benchmark --todos-os-niveis` e `Society.exe --rendering-driver d3d12 -- --benchmark --todos-os-niveis`.

## Pronto quando

`docs/benchmark.md` tem a primeira tabela da RTX 3060 (FPS médio, 1% low, pior quadro e tempo de GPU por preset, em
1080p e 4K, nos dois drivers) e a decisão de driver registrada; nenhum preset fica sem AA; as nuvens volumétricas foram
conferidas na placa; o build rodou fora da VM.
