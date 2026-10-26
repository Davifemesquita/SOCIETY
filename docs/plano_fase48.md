# Plano da Fase 48 — Godot 4.8

**Estado: ensaio feito em 26/10/2026, à espera da 4.8 estável e do dono.** Décima sétima fase do roteiro de
`docs/plano_melhorias.md`. A 4.8 estável **ainda não saiu**: a mais nova é a **4.8-beta1** (15/10/2026, no
`godotengine/godot-builds`). O plano manda subir num ramo separado só com a estável; então o que se fez foi o ensaio
com a beta no ramo **`godot-4.8`** (sem merge), mais dois consertos achados medindo, que valem para a 4.7.2 e vieram
para o `main`. Nada apareceu na tela do dono (testes sem janela; benchmark e capturas na área de trabalho escondida).

## 1. Os nomes de verdade na 4.8-beta1 (lidos do binário, as notas não dizem)

| Recurso | Onde |
|---|---|
| Sombras de contato em espaço de tela | `rendering/lights_and_shadows/contact_shadow/enabled` (`shadow_length`, `surface_thickness`); por luz, `Light3D.shadow_contact_shadows_allow` e `shadow_contact_shadows_blur` |
| AO com vários quiques | `rendering/lights_and_shadows/multi_bounce_occlusion/enabled` |
| Mipmaps com cobertura de alpha | opção de importação `mipmaps/preserve_alpha_test_coverage` |
| Texture streaming | `rendering/textures/streaming/*` (`enabled`, `min_lod`, `max_lod`, `memory_budget_mb`…) |

## 2. O ramo `godot-4.8` (commit 26a9259, enviado)

- `project.godot` na 4.8, com as sombras de contato e o AO de vários quiques ligados; `GraphicsPresetDef.contact_shadows`
  (alto e ultra) aplicado ao sol em `GraphicsQuality.apply`.
- As `.import` ganham `mipmaps/preserve_alpha_test_coverage=false` (a 4.8 grava o padrão). **Nenhuma textura do projeto
  usa recorte de alpha** (as folhas são geométricas; a folha recortada da Fase 41 espera a textura do dono): a opção fica
  para quando ela chegar. Texture streaming fica desligado (o plano o liga só com a Fase 50).
- O CI do ramo baixa a beta (`GODOT_RELEASES` no `testes.yml`, URL montada no `action.yml`).
- `tests/world/test_phase48_engine.gd`: o motor é o 4.8, as duas opções ligadas, só alto e ultra pedem a sombra de
  contato.

## 3. Resultados na 4.8-beta1

- `check_scripts`: 378 scripts, nenhum erro (as duas quebras do GDScript na lista da beta — herdar a própria classe
  interna e string como comentário — não nos atingem).
- core, data, sim, tools e world: tudo verde, **inclusive os testes dourados do v0, v1 e v2** (o `FastNoiseLite` e o
  `hash()` não mudaram) e o determinismo do v2. Os testes de interface da Fase 47, 43 e 10 também passam.
- Benchmark (área de trabalho escondida, o mesmo quadro): GPU 11,4 contra 11,0 ms na 4.7.2, 81,9 contra 85,2 FPS no dia
  inteiro, tick e obra iguais, objetos e draw calls iguais (2.891 · 1.213); o pior quadro do dia foi 76 ms (contra 32),
  um engasgo a investigar na estável. De perto (capturas da Fase 39 nas duas versões) a sombra de contato é discreta: pé
  das chaminés e junções dos telhados um pouco mais escuros.

- **Com janela** (área de trabalho escondida, depois de trazer o `main` para o ramo): presentation 143/143 e ui 153/153
  na 4.8-beta1, iguais à 4.7.2. Dois testes de interface falhavam só na beta e foram consertados nos testes (não no
  jogo): a 4.8 faz a câmera ler o cursor de verdade da área de trabalho (no canto), não o mouse simulado, e o pan pela
  borda cancelava a centralização e mexia no zoom — os testes que simulam mouse desligam o pan pela borda, como o da
  Fase 5 já fazia.

## 4. Achados no ensaio, consertados no `main`

- **Pan pela borda sem mouse**: na área de trabalho escondida a 4.8 lê o mouse num canto, e a câmera saía andando (o
  primeiro benchmark da 4.8 deu um falso 172 FPS, com a câmera olhando o mar). O xvfb do CI tinha o mesmo problema (o
  teste da Fase 5 desligava o pan). Agora o pan pela borda só vale depois de um movimento de verdade do mouse na janela
  (`StrategyCamera.mouse_seen`) — também melhor para o jogador com a janela recém-aberta.
  `tests/world/test_phase48_edge_pan.gd`.
- **Filtro de nós liberados**: na 4.8 um lambda com parâmetro tipado recusa o objeto já liberado ("Cannot convert
  argument 1 from Object to Object"), justo o que os filtros de `BuildingView` tiram; o parâmetro virou `Variant`.

## Fica de fora

- O merge no `main` (só com a estável e a aprovação do dono); HDDAGI, XeGTAO, ray tracing, D3D12.
- Conferir os addons na estável (Sky3D 2.1.0, SunshineClouds2, Dialogue Manager 4.1.0, gdUnit4 6.2.2, Boujie): na beta
  todos carregaram e a suíte passou, mas a compatibilidade declarada é da 4.7.

## Pronto quando

Na 4.8 estável: o ramo atualizado para ela, o CI do ramo verde, assinaturas iguais, benchmark sem regressão e o ganho
visual aprovado; só então o merge. **Proposta à espera do dono**: decidir quando subir e medir na 3060 (a GPU sobe ~0,4
ms com as duas opções ligadas).
