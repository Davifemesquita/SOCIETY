# Plano da Fase 361 — Vão da janela

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_361_365.md` (ligar o MegaKit). O MegaKit continua
desligado por padrão (`SOCIETY_MEGAKIT=1` liga); com ele desligado nada muda.

## O problema

Tudo o que se desenha em volta da janela saía de três números do vão do Kenney (`WINDOW_WIDTH`, `WINDOW_CENTER`,
`WINDOW_HEIGHT`): as janelas acesas (Fase 4), vergas, peitoris e guarnições (Fases 18, 24 e 25), arcos (99), escoras do enxaimel
(102), floreiras (13), postigos (177), cortinas (217) e o tapete na janela (232). Na janela do pacote eles cruzavam a moldura.

## O que entrou

- **`BuildingKit.opening(spec)`**: o vão (largura, centro, altura e o x do vidro) da peça que a forma usa; no Kenney, as
  constantes de sempre; no MegaKit, `MEGAKIT_OPENINGS`, medido pelo vidro de cada peça convertida. **`window_index(spec)`**: qual
  das três janelas a forma usa; no MegaKit os prédios de janela em arco levam a janela em arco do pacote.
- As janelas acesas ficam logo à frente do vidro do pacote (no fundo da parede grossa, atrás da moldura); os postigos, fora da
  moldura (`MEGAKIT_FRAME_M`); as cortinas, logo à frente do vidro; as escoras, as floreiras e o tapete pelo vão novo.
- Na janela do pacote **não vão as vergas, peitoris, arcos e guarnições de pedra**: a moldura dela já é a dela.
- **`tools/pack_megakit.gd`**: só a peça de parede se simplifica; a janela, a porta e o vidro ficam inteiros (simplificada, a
  moldura da janela virava cacos e duas das três perdiam o vidro).

## Medida (área de trabalho escondida, Alta, alternando, duas rodadas cada)

| | FPS médio | GPU média | primitivas |
|---|---|---|---|
| Kenney | 64,6 / 64,7 | 14,5 / 14,5 ms | 19,9 M |
| MegaKit (janela inteira) | 62,3 / 62,1 | 15,2 / 15,2 ms | 22,8 M |

A janela inteira custa ~0,7 ms de GPU: é o que a Fase 362 ataca.

## Como testar

- `tests/presentation/test_phase361_megakit_openings.gd`: o vão do Kenney e o do pacote, a janela em arco nos prédios de arco, o
  tamanho e a profundidade das janelas acesas e a pedra das vergas que sai.
- Capturas: `tools/capture_phase95.tscn` e `CAPTURA_SO=noite` no `tools/capture_buildings.tscn`, com `SOCIETY_MEGAKIT=1`
  (`F:\ferramentas\capturas\fase361\dia2\` e `noite\`).

## Fica para depois

- Com ele ligado, os investidores (30.818 triângulos) e os prédios grandes passam dos tetos, e os testes da paleta pegam a UV do
  pacote (Fases 362 e 363). Frestas escuras entre os andares na frente do enxaimel saliente.
