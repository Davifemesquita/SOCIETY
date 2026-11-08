# Plano da Fase 380 — Fotos e conferência

**Estado: feita em 08/11/2026**, a última do roteiro `docs/plano_fases_376_380.md` (peças do MegaKit III).

## Por que mudou

A fase planejada (os degraus de pedra do pacote no plinto do barranco) saiu junto com a 377: os degraus já são blocos da cantaria do
pacote, em escala de verdade. A escada pronta do pacote (`Stairs_Exterior_Straight`) tem 1 m de altura fixa e não segue a altura de
cada degrau do barranco.

## O que entrou

- As fotos do menu refeitas (`tools/bake_building_photos.tscn`): o madeiramento, o alicerce, as lucarnas e o caixote novos.
- A pasta `tests/presentation` rodada com o MegaKit (o padrão) e com o Kenney (`SOCIETY_MEGAKIT=0`).

## Resultado

- Com o MegaKit: 464 casos, 2 falhas no `test_phase114_front_railing.gd` (o teste procurava a célula do ferro pela UV, e a UV do
  alicerce de cantaria da Fase 377, que é da textura do pacote, caía nela por acaso). O teste passou a pular os vértices do pacote
  (UV2.x > 0) e passa sozinho; a pasta inteira não foi rodada de novo depois da correção.
- Com o Kenney (`SOCIETY_MEGAKIT=0`): 465 casos, nenhuma falha.
- **Teste que procura uma célula da paleta pela UV pula os vértices do pacote** (UV2.x > 0): a UV deles é da textura do MegaKit.
