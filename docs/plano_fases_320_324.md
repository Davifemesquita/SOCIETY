# Roteiro das Fases 320 a 324 — Garganta de perto

**05/11/2026.** Sexto ciclo da ideação de 02/11/2026, sem abrir o Anno. A referência é a garganta do Anno em `c10_06` e `c10_08`
(`F:\ferramentas\capturas\anno\`), comparada com a garganta da semente 1840 vista de perto depois das Fases 315 a 319
(`02_garganta_de_perto` do `tools/capture_phase317.tscn` e `05_rio` do `tools/capture_phase280.tscn`). **Só a ideia.**

## O diagnóstico

- **Franja em pente.** De perto (abaixo de ~15 m), a franja de capim das Fases 312 e 316 são onze folhas chatas, iguais e
  paralelas, em fileira reta ao longo da célula: parece um pente verde. No Anno, o capim da borda vem em tufos soltos, cada um
  abrindo em leque, de tamanhos e tons diferentes.
- **Risco laranja na crista.** No alto da garganta sobra uma linha de terra alaranjada (a beira do barranco da Fase 289) entre o
  capim e a rocha. No Anno, a beira é capim e pedra.
- **Parede esticada.** A face das paredes da garganta tem a textura da rocha esticada em riscos verticais. No Anno, a parede é de
  pedra em camadas, com o mesmo grão de perto e de longe.
- **Cantos em esquadro.** As paredes da garganta seguem as células, com quinas retas onde o rio faz curva. No Anno, a parede
  avança e recua.
- **Fundo claro.** No rio estreito e fundo, a água do fundo da garganta sai clara (o céu refletido), como se estivesse ao sol. No
  Anno, a água no fundo da garganta é escura, na sombra das paredes.

## As fases

| Fase | O quê |
|---|---|
| 320 — Franja em tufos | na `CliffFringeView`, a malha da franja vira tufos em leque (folhas de rumo, comprimento, largura, torção e tom sorteados), e cada pedaço sai um pouco girado |
| 321 — Crista sem risco | no `shaders/terrain.gdshader`, nas temperadas, a beira do barranco da Fase 289 acima de `gravel_top_m` vira capim e pedra em vez da terra alaranjada |
| 322 — Parede sem esticado | na face íngreme da garganta, a rocha projetada sem esticar (triplanar pela normal) e com as camadas da Fase 310 |
| 323 — Parede que avança | o detalhe visual do relevo (Fase 36) também nos cantos da parede da garganta junto do rio, quebrando as quinas em esquadro, fora de estrada, ponte e prédio |
| 324 — Fundo na sombra | no `shaders/water.gdshader`, a água do canal escurece pela abertura do céu entre as paredes (a altura da terra em volta, do mapa da costa) |

Cada fase segue a regra de sempre: plano curto, testes, captura e benchmark, commit e push.

## Estado

- **320 feita em 05/11/2026** (`docs/plano_fase320.md`): antes em `F:\ferramentas\capturas\fase317\garganta3\`, depois em
  `F:\ferramentas\capturas\fase320\depois\`.
- **321 feita em 05/11/2026** (`docs/plano_fase321.md`): a linha era a beira do barranco da Fase 289, não a lama; depois em
  `F:\ferramentas\capturas\fase321\depois\`.
- **322 feita em 05/11/2026** (`docs/plano_fase322.md`): o esticado era a normal do vértice (a média do alto com o leito), não a
  falta de triplanar; capturas em `F:\ferramentas\capturas\fase322\`.
- **323 tentada e deixada de fora em 05/11/2026** (`docs/plano_fase323.md`): a beira de cima da parede é a borda das células do
  planalto e o pé é o leito, os dois presos pela simulação; empurrar os pontos do meio da face não aparece. Quebrar as quinas pede
  mudar o traçado do rio no gerador (proposta para o dono do produto).
- **324 feita em 05/11/2026** (`docs/plano_fase324.md`): a abertura do céu pela altura da terra em oito rumos; só cortar o reflexo não
  bastava, a água precisou ficar fosca; capturas em `F:\ferramentas\capturas\fase324\`.

**Roteiro concluído em 05/11/2026**: quatro fases feitas e uma (323) deixada de fora com o motivo. O benchmark ficou neutro em todas,
mas a máquina esteve mais lenta o dia todo (~31 FPS, contra ~72 na 319, e o código da 319 medido nas mesmas condições deu 30,9): os
números de hoje só valem comparados entre si.
