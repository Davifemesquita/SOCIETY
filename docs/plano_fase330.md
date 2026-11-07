# Plano da Fase 330 — Sombra funda

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_330_334.md` (luz e sombra). No Anno cada casa e cada árvore
deixa no capim uma sombra escura e firme; no Society a sombra do sol quase não aparecia.

## O diagnóstico

A sombra existia e estava ligada (opacidade 1, 400 m, quatro cascatas): o sol é que ficava **às costas da câmera**. A câmera padrão
fica em +z olhando para −z, e o Sky3D (latitude 45°, abril) põe o sol do dia do lado +z (às 10h30 a direção para ele é
(0,38; 0,76; 0,53)). Cada sombra caía atrás da casa ou da árvore que a fazia, escondida, e a cena saía chapada. Baixar só a luz
ambiente (o primeiro laboratório, de 1,0 a 0,4) escurecia tudo por igual sem mostrar sombra nenhuma.

## O plano

- **Arquivos**: `world/sky/sky_adapter.gd` (o giro do sol), `world/graphics_quality.gd` (a luz ambiente pela altura do sol),
  `data/game_config.gd`, o teste novo, a captura do ciclo, `AGENTS.md` e o roteiro.
- **Risco**: com o sol na frente, as fachadas viradas para a câmera ficam na sombra; luz ambiente fraca demais as apaga. O giro não
  pode se somar a cada hora.
- **Como testar**: o laboratório (`CAPTURA_AMBIENTE` do `tools/capture_phase330.tscn`), o teste novo, os do céu e o benchmark.

## O que entrou

- **O sol girado** (`GameConfig.sun_azimuth_offset_deg`, 180°): o `SkyAdapter._turn_sky` soma o giro ao azimute do sol e da lua
  logo depois de cada conta do Sky3D (que recalcula do zero a cada hora nova: o giro não se acumula); o céu simples gira junto. De
  manhã o sol fica na frente e à esquerda da câmera padrão, ao meio-dia na frente, à tarde na frente e à direita: as sombras vêm para
  o jogador e para a direita, como no Anno. O nascer e o pôr do sol não mudam (só a altura do sol conta para eles).
- **A luz ambiente de dia** (`ambient_day_energy`, 0,75, cheia com o sol a `ambient_day_sun_high`): o `GraphicsQuality.follow_sun`,
  a cada quadro, põe a força da luz ambiente pela altura do sol (`ambient_factor`), inteira com o sol baixo e de noite. Com 0,6 as
  fachadas na sombra escureciam demais.
- **O mar de longe áspero** (`far_sea_roughness`, 0,5, de `far_sea_from_m` a `far_sea_to_m`): com o sol na frente, o reflexo dele
  nas ondas lisas de longe virava manchas brancas grandes (o laboratório `CAPTURA_AGUA` mostrou que só a rugosidade as tira; zerar
  a cintilação ou baixar o especular não adiantava). A cintilação da Fase 110 troca o `fract(sin(...))` pelo `reef_hash` (com as
  coordenadas do arquipélago os pontos se juntavam em bolhas) e some a 260 m (era 900).
- **`SkyAdapter.refresh`**: refaz o céu na mesma hora (o laboratório troca o giro; sem forçar a conta, o Sky3D não recalculava e o
  giro somava duas vezes).

## Medida

Benchmark: 63,9 FPS, GPU 14,5 ms, carregar 6.893 ms (a 329 na mesma sessão: 63,5 FPS, GPU 14,6 ms). A sombra é a mesma de antes, só
que à vista.

## Como testar

- `tests/world/test_phase330_deep_shadow.gd`: o sol da manhã na frente da câmera padrão (sem o giro, às costas), o giro igual ao da
  configuração e sem se somar hora após hora, o céu simples girado, a luz ambiente mais fraca com o sol alto, sem degrau, e o mar
  de longe áspero com a cintilação sem seno.
- Captura do ciclo: `tools/capture_phase330.tscn -- <pasta>` (a vila de cima e de perto, a mata alta e a baixa e a vila de longe);
  antes em `F:\ferramentas\capturas\fase330\antes\`, depois em `depois3\` (lado a lado em `antes_depois.png`); os laboratórios em
  `lab3\` (`CAPTURA_AMBIENTE="180/1.0,..."`) e `agua\` (`CAPTURA_AGUA="roughness=0.5|..."`).
