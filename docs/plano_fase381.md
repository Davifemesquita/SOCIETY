# Plano da Fase 381 — Tábuas com veio

**Estado: feita em 08/11/2026**, a primeira do roteiro `docs/plano_fases_381_385.md` (texturas do MegaKit).

## O problema

Os telhados de tábuas (Fases 303 e 350: metade das casas dos operários e um terço das dos artesãos) eram desenhados no shader com
um tom por tábua e um ruído fraco: de perto pareciam ladrilhos lisos.

## O que entrou

- No `shingle_shade` do `shaders/building_kit.gdshader`, com o MegaKit (`megakit_stone`), o brilho de cada tábua sai da faixa clara
  da madeira do pacote (`megakit_shingle_v`, v de 0,02 a 0,28), com o veio descendo a água, cada tábua num trecho sorteado da faixa,
  dividido pelo brilho médio (`megakit_shingle_luma`, 0,166 em linear); a cor segue a do telhado (cinza ou marrom).
- A faixa escura da textura foi tentada primeiro: ela é quase lisa (de 0,065 a 0,089) e as tábuas só escureceram.

## Como testar

- `tests/presentation/test_phase381_pack_textures.gd`: os uniformes no shader compilado (com tela) e as faixas.
- Captura: `rua_artisans_c.png` no `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase381\dia2`, contra a `fase378\dia`).
