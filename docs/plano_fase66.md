# Plano da Fase 66 — Prefeitura e políticas

**Estado: feita em 27/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima"; a proposta da prefeitura
com políticas de raio, como os itens de raio da prefeitura do Anno, simplificada). Mexe na simulação (prédio novo,
estado novo no save); as assinaturas (terreno e matemática determinística) não mudam.

## O que entrou

- **Prefeitura** (`data/buildings/town_hall.tres`): serviço de pedra 4 × 4 com campanário, 3.000 moedas, 10 tábuas e
  8 tijolos, 60/min de manutenção, liberada com 150 operários; na aba dos serviços, com ícone (o pergaminho do lorc,
  game-icons, que já estava no projeto). `BuildingDef.policy_radius_cells` (20) marca a prefeitura.
- **Políticas** (`PolicyDef`, `data/policies/`): jornada longa (+15% na velocidade da produção, 40/min), vigia de
  incêndio (chance de fogo × 0,4, 20/min), feriados (+8 de felicidade nas casas, 30/min) e coletoria (+15% no imposto
  das casas, 30/min, depois do primeiro marco).
- **Regra** (`DerivedState._apply_policies`): a prefeitura com política e estrada aplica o efeito nas casas e na
  produção a até 20 células do lote (distância entre os retângulos) e soma a manutenção da política. A mesma política
  de duas prefeituras vale uma vez no prédio; políticas diferentes somam. A produção, os riscos e a população leem os
  efeitos já somados (`policy_speed`, `policy_fire`, `policy_happiness`, `policy_tax`).
- **Comando** `SetPolicyCommand` (escolhe ou tira; só prefeitura, só política liberada pelo marco; trocar não custa).
- **Save**: `BuildingRecord.policy`, gravado só quando há; política desconhecida ou fora de prefeitura recusa o save.
- **Painel**: a política, quantos prédios ela alcança e a manutenção (ou o aviso de sem estrada), um botão por política
  (marcado o da escolhida, desligado o bloqueado, com o efeito e a manutenção na dica) e o de tirar.

## Números

- Benchmark (alto, RTX 5060): tick médio 1,30 ms, construir com a ilha cheia 15,1 ms, desenho igual (o benchmark não
  constrói prefeitura: o recálculo só ganha o laço vazio das prefeituras; `docs/benchmark.md`).
- A foto do menu (`ui/photos/building_town_hall.png`) saiu do `tools/bake_building_photos.tscn`, como as da Fase 51.

## Como testar

- `tests/sim/test_phase66_town_hall.gd`: dados e textos, o alcance e a manutenção, a mesma política sem somar e as
  diferentes somando, feriados na felicidade e coletoria no imposto (+15%), jornada longa na velocidade, sem estrada
  sem política, as recusas do comando e o save.
- `tests/ui/test_phase66_town_hall_panel.gd`: o painel escolhe e tira a política pelos botões (a bloqueada desligada),
  sem chave sem tradução; a prefeitura na aba dos serviços.
- Capturas: `tools/capture_phase66.tscn -- <pasta>` (a prefeitura com casas em volta e o painel; em
  `F:\ferramentas\capturas\fase66`).

## Fica de fora (proposta à espera do dono)

- O desenho do alcance da política na grade (hoje o destaque é o do serviço pela estrada), mais vagas de política por
  prefeitura, políticas que custam bens e o robô usando a prefeitura. Os números são provisórios.
