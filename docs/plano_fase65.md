# Plano da Fase 65 — Festa na cidade

**Estado: feita em 27/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima"). Só apresentação: a
simulação, o terreno e as assinaturas não mudam; nada vai no save.

## O que faltava

O evento da festa (Fase 11, `festival`: +12 de felicidade numa ilha por 8 minutos) só aparecia no aviso, no selo da
barra e na janela das encomendas: a cidade em festa não mudava em nada.

## O que entrou

- **`FestivalView`** (`presentation/festival_view.gd`, montada pela `GameScreen` com os pássaros): enquanto a festa
  vale numa ilha, cada praça dela — praça com chafariz, coreto e mercado (até seis); sem nenhum, o entreposto — ganha
  um mastro de 7,5 m na célula da porta e cordas de bandeirolas (cinco cores alternadas, a corda cedendo no meio) que
  descem até postes de 3,6 m no último trecho reto de rua de até cinco células para cada lado. As cordas só passam por
  cima da estrada: nunca cruzam um telhado. Obra, demolição ou rua nova durante a festa refazem as cordas.
- **Fogos de artifício**: à noite (a partir de 0,45 do `DayClock.night_factor`), um estouro a cada 0,9 a 2,2 s de jogo
  sobre um mastro sorteado, a 28–42 m, em seis cores (seis bombas de partículas reaproveitadas, mistura aditiva).
- Acabou a festa (`world_event_ended`), somem as bandeirolas e os fogos.

## Números

- Benchmark (alto, RTX 5060): neutro — os mesmos draw calls e a GPU no nível da Fase 64 com a máquina no mesmo estado
  (22,2 ms); o benchmark roda sem eventos, então nada da festa entra no quadro (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase65_festival.gd`: as praças (o mercado antes do entreposto), as cordas só sobre a
  estrada e com o desnível do mastro ao poste, a vista enfeitando só enquanto a festa dura (com o lugar dos fogos e o
  estouro no alto), e outro evento sem enfeite.
- Capturas: `tools/capture_phase65.tscn -- <pasta>` (um bairro com mercados no maior pedaço de terra da ilha
  principal, a festa posta à mão; as bandeirolas de dia e os fogos à noite; em `F:\ferramentas\capturas\fase65`).

## Fica de fora (proposta à espera do dono)

- Som dos fogos (sem asset de áudio livre escolhido), gente dançando na praça e a festa como algo que o jogador
  compra ou marca (hoje só vem do sorteio dos eventos).
