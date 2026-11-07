# Plano da Fase 160 — Cunhais de pedra

**Estado: feita em 31/10/2026**, a primeira do roteiro `docs/plano_fases_160_164.md` (cunhal, deriva e horta, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingKit.Spec.quoins`, na chave da forma): as casas de `TierDef.HouseTrim.FLOWER_BOXES` (artesãos) e `BALCONIES`
  (engenheiros), as que já têm a cornija e as vergas de pedra clara. Os investidores ficam sem: a parede deles já é de pedra
  clara (o cunhal quase não aparece) e a casa passaria do teto de 20.000 triângulos (de 19.480 para 20.572).
- **Os blocos** (`_quoins`, chamado pelo `_ornament`): nas quatro quinas do corpo, da soleira até a cornija, fiadas de
  `QUOIN_COURSE_M` com a junta de `QUOIN_JOINT_M`, o lado comprido (`QUOIN_LONG_M`) alternando entre as duas faces da quina e o
  curto (`QUOIN_SHORT_M`) na outra, saltados `QUOIN_OUT_M` da parede, em pedra clara (`UV_LIGHT_STONE`). A quina do lado da ala
  (Fase 96) para no alto da ala; no balanço (Fase 102) a quina da frente sobe pela frente que avançou.

## No caminho

- O teste das sacadas da Fase 24 (`test_building_kit.gd`) compara os engenheiros com os investidores: ele passa a desligar os
  cunhais, como já desligava as floreiras da Fase 153.

## Como testar

- `tests/presentation/test_phase160_quoins.gd` (com janela): só artesãos e engenheiros; a forma muda e soma triângulos na
  mesma casa; os blocos encostam na quina, saltam da parede pelas duas faces, ficam entre a soleira e a cornija e alternam o
  lado comprido; na casa com ala, a quina da ala para no alto dela.
- Captura: `cunhais.png` no `tools/capture_phase95.tscn` (os artesãos de quina, com o balanço).
