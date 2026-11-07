# Plano da Fase 302 — Sujeira nas paredes

**Estado: feita em 02/11/2026**, a terceira do roteiro `docs/plano_fases_300_304.md`. No Anno, a base das paredes é suja de terra e
respingo, e a chuva escorre pela parede.

## O que entrou

- **`shaders/building_kit.gdshader`**, só nas células de parede viradas para o lado (fora do vidro), depois do escurecimento da base
  de antes e antes do musgo da Fase 39:
  - **o respingo de terra** no pé, na cor `splash_color`, até `splash_height_m` (0,7 m) vezes um ruído ao longo da parede (a borda
    de cima irregular), manchado por um ruído miúdo, em `splash_strength`;
  - **os escorridos de chuva**: riscos verticais (ruído compridíssimo na vertical) a partir de ~0,4 m do chão, escurecendo
    `wall_streak_strength`.
- **O que ficou de fora**: o roteiro previa escorridos mais fortes debaixo dos peitoris e do beiral. O shader não sabe onde fica
  a janela; os riscos são da parede inteira.

## Medida

GPU 12,6 ms (301: 12,5). Neutra.

## Como testar

- `tests/presentation/test_phase302_wall_grime.gd`:
  - o bloco só na parede de lado, entre a sujeira de antes e o musgo, com o respingo e os escorridos;
  - o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase300.tscn -- <pasta>`; o recorte está em `F:\ferramentas\capturas\fase302\antes_depois.png`.
