# Plano da Fase 333 — Ar de longe

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_330_334.md` (luz e sombra). No Anno a ilha do fundo fica mais
clara e mais azulada que a da frente (perspectiva aérea); no Society, desde a Fase 255, o longe tinha a cor do perto.

## O plano

- **Arquivos**: `data/game_config.gd` (a neblina do domo), `world/sky/sky_adapter.gd` (o fim dela), a captura do ciclo (o horizonte de
  dia, no fim da tarde e à noite), o teste novo, os das Fases 53 e 255 (que limitavam a densidade), `AGENTS.md` e o roteiro.
- **Risco**: voltar ao cinza leitoso de antes da Fase 255, e a vista de cima (a 420 m) ficar lavada.
- **Como testar**: o laboratório `CAPTURA_AR` (começo/fim/densidade), o horizonte e a vila de longe antes e depois.

## O que entrou

- **A neblina atmosférica do Sky3D** (o `AtmFog` do domo; a cor sai da dispersão do céu, azulada de dia e quente no fim da tarde) só
  a partir de `sky_fog_start_m` (250 m; era 60), cheia em `sky_fog_end_m` (3000 m, novo; o Sky3D usava 1000) e mais densa,
  `sky_fog_density` 0,0012 (era 0,0001). Perto da câmera nada muda; as ilhas do fundo e o horizonte clareiam e azulam.
- **No laboratório** (`lab\`): 60/1000/0,0001 (antes), 250/2500/0,0004, 150/1800/0,0007 e 300/3000/0,001. As duas primeiras quase
  não se distinguem; a de 0,001 já mostra o ar, sem lavar a vista de cima. Ficou um pouco mais forte.

## Medida

Os números da neblina que o domo já desenhava: sem custo de quadro, sem benchmark à parte.

## Como testar

- `tests/world/test_phase333_aerial_haze.gd`: a neblina começa longe, vai até bem mais longe, mais densa, e o domo recebe os três
  valores. Os testes das Fases 53 e 255 aceitam a densidade maior com o começo a 200 m ou mais.
- Captura: `tools/capture_phase330.tscn -- <pasta>` (vistas `07_horizonte`, `08_horizonte_fim_de_tarde` e `09_horizonte_noite`);
  `CAPTURA_AR_ANTIGO=1` põe a neblina de antes. Antes em `F:\ferramentas\capturas\fase333\antes\`, depois em `depois\`.
