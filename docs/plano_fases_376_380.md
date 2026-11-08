# Roteiro das Fases 376 a 380 — Peças do MegaKit III

**08/11/2026.** Depois do roteiro `docs/plano_fases_371_375.md` (peças do MegaKit II), o dono disse "continue". As paredes, as
janelas, as portas, as telhas, a sacada dos engenheiros e a cerca já são do Medieval Village MegaKit (Quaternius, CC0). O que se
gera no código em volta delas (o madeiramento, o alicerce, as lucarnas, a carga, os degraus) ainda sai na paleta lisa do Kenney,
e ao lado da textura do pacote parece de plástico. Este roteiro leva a textura e as peças do pacote a essas partes. O Anno não foi
aberto.

## As fases

| Fase | O quê |
|---|---|
| 376 — Madeiramento do pacote | com o MegaKit, as vigas, esteios, escoras e mãos-francesas geradas (a célula `UV_TIMBER`) na madeira do pacote |
| 377 — Alicerce de cantaria | o alicerce que aparece no pé dos prédios e o plinto do barranco na cantaria do pacote |
| 378 — Lucarna do pacote | as lucarnas do telhado com a lucarna de telhas redondas do pacote (`Roof_Dormer_RoundTile`), se o peso couber |
| 379 — Caixote do pacote | os caixotes das pilhas de estoque, da carga e do cais com o caixote do pacote (`Prop_Crate`) |
| 380 — Fotos e conferência | os degraus já saíram na 377: a 380 refaz as fotos do menu e roda a suíte com os dois kits |

Ficam de fora a carroça do pacote (`Prop_Wagon`, ~1.700 triângulos, e há centenas de carroças) e as escoras soltas
(`Prop_Support`, que é uma barra só: a 376 já dá a madeira do pacote às geradas).

Cada fase confere o peso (triângulos) e olha a captura antes de entrar; peça que sai pior que a gerada fica de fora, registrada.

## Estado

- **376 feita em 08/11/2026** (`docs/plano_fase376.md`).
- **377 feita em 08/11/2026** (`docs/plano_fase377.md`), com os degraus da porta: a 380 muda (ver abaixo).
