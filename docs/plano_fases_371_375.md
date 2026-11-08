# Roteiro das Fases 371 a 375 — Peças do MegaKit II

**08/11/2026.** Depois do roteiro `docs/plano_fases_366_370.md` (acabamento do MegaKit), o dono disse "pode continuar". As paredes
já são do Medieval Village MegaKit (Quaternius, CC0); o resto do prédio (telhado, grade, sacada, chaminé) ainda é gerado no código
com a paleta do Kenney. O pacote traz essas peças e texturas, e este roteiro as usa onde couber. O Anno não foi aberto.

## As fases

| Fase | O quê |
|---|---|
| 371 — Telhas redondas | as águas de telha com a textura de telhas redondas do pacote, projetada ao longo da água, com o relevo dela |
| 372 — Postigos do pacote | com o MegaKit, as folhas abertas do pacote (de tábuas, com a volta redonda) nas janelas que têm postigo, no lugar das geradas |
| 373 — Sacada do pacote | as sacadas dos engenheiros com o guarda-corpo de madeira em xis do pacote |
| 374 — Chaminé do pacote | a chaminé das casas com a de tijolo irregular do pacote, a boca da fumaça no mesmo lugar |
| 375 — Cerca do pacote | a cerca do quintal dos camponeses com a cerca de tábuas do pacote |

A grade de ferro trabalhada do pacote (`Prop_MetalFence_*`) ficou de fora: tem ~4 mil triângulos por 2 m e quase 3 m de altura.
As trepadeiras (`Prop_Vine*`) também: a folha é recortada pelo alfa, e o material do kit é opaco.

Cada fase confere peso (triângulos) e custo antes de entrar; peça pesada demais fica de fora, registrada.

## Estado

- **371 feita em 08/11/2026** (`docs/plano_fase371.md`).
- **372 tentada e deixada de fora em 08/11/2026** (`docs/plano_fase372.md`): as tábuas do pacote quase não aparecem na folha.
- **373 feita em 08/11/2026** (`docs/plano_fase373.md`).
