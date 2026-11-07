# Plano da Fase 99 — Arcos

**Estado: feita em 29/10/2026**, a última do roteiro `docs/plano_fases_95_99.md` (formas mais redondas, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Janela em arco** (`BuildingKit.Spec.arched`, `_arch_head`, `_arches`, `arch_spring`, `arch_radius`): a igreja, o
  teatro, a universidade, a prefeitura, o museu e as casas dos investidores trocam a verga reta por uma cabeça em arco de
  volta inteira em cima do vão — o tímpano de vidro em meio círculo (`ARCH_SEGMENTS` trechos), a arquivolta de pedra clara
  de `ARCH_BAND_M` saltando `ARCH_PROUD_M` da parede (face, borda de fora e intradorso) e a pedra de fecho no alto. Nos
  investidores as ombreiras da Fase 25 continuam e a pedra de fecho da verga sai (`_window_frame(..., keystone)`); os
  serviços, que não têm o ornamento das casas, ganham só a cabeça. As portas desses serviços já eram em arco (`Door.ARCH`).
- **Arcada do mercado** (`arcade_bays`, `_arcade`): a fileira do pátio junto do corpo vira arcada — um pilar de pedra em
  cada divisa de célula com o capitel, o arco de volta inteira nascendo a `ARCADE_SPRING_M`, o tímpano na frente e atrás, o
  intradorso, a cornija e a água de telhas subindo `ARCADE_ROOF_RISE_M` até a parede do corpo. As bancas ficam só na
  fileira da rua.

## Números

- Constantes de apresentação. As casas dos investidores e os serviços de pedra trocam de forma (uma por tipo; as casas já
  tinham as variações das Fases 39 e 96).

## Como testar

- `tests/presentation/test_phase99_arches.gd`: quem tem e quem não tem janela em arco; cada janela ganha exatamente o leque
  de vidro do tímpano; a arquivolta cabe no andar; o mercado tem uma arcada de uma baia por célula, na frente do corpo,
  dentro do lote e abaixo do beiral, e a padaria não.
- Captura: `tools/capture_phase95.tscn` (`mercado_de_lado.png` com a arcada, `grandes_a.png` com as janelas em arco).
