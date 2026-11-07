# Plano da Fase 101 — Toldos listrados

**Estado: feita em 29/10/2026**, segunda do roteiro `docs/plano_fases_100_104.md` (a rua habitada, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem tem toldo** (`BuildingKit.Spec.awning`): as lojas de `AWNING_SHOPS` (padaria, açougue e taverna; o mercado tem a
  arcada da Fase 99) e uma casa em `AWNING_HOUSE_SHARE` dos artesãos e engenheiros (pelo `house_hash`), que fica com loja
  no térreo. A cor da listra é sorteada pelo tipo na loja (vermelho, verde ou azul) e fixa por classe na casa (vermelho nos artesãos,
  verde nos engenheiros): cada forma nova custa ~18 ms na primeira vez, e três cores triplicavam as casas com loja. Camponeses,
  operários e investidores não têm.
- **O toldo** (`awning_cells`, `_awnings`): sobre cada porta e janela do térreo da frente, preso a `AWNING_AT` do andar,
  saindo `AWNING_OUT_M` e caindo `AWNING_DROP_M`, em `AWNING_STRIPES` listras alternando a cor e o creme, com a sanefa na
  ponta e as abas dos lados; lona dos dois lados (vista de baixo também).
- **A lona no shader** (`shaders/building_kit.gdshader`): as células (3..6, 1) da paleta, que o kit não usa (o teste
  confere peça por peça), viram as três cores e o creme (`awning_red`, `awning_green`, `awning_blue`, `awning_cream`), com
  a trama por ruído.

## No caminho

- O teste das casas variadas da Fase 39 conta as formas no cache: o limite passou a incluir as casas com loja dos artesãos
  e dos engenheiros.

## Como testar

- `tests/presentation/test_phase101_awnings.gd`: as lojas têm toldo e células com toldo, os outros prédios não; de 15 a 50
  em cada 99 casas dos artesãos e dos engenheiros têm loja, nenhuma das outras classes; a lona fica no térreo da frente,
  saindo para a rua; nenhuma peça do kit usa as células da lona.
- Captura: `tools/capture_phase95.tscn` ganhou a padaria na rua dos prédios grandes e a tomada `loja_toldo.png`.
