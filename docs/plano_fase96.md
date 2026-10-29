# Plano da Fase 96 — Casa em mais de um volume

**Estado: feita em 29/10/2026**, segunda do roteiro `docs/plano_fases_95_99.md` (formas mais redondas, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save; o lote, a porta e os moradores são os mesmos.

## O que entrou

- **A ala mais baixa** (`BuildingKit.Spec.wing`, `in_wing`, `main_part`, `wing_part`, `column_m`): metade das casas dos
  operários para cima (pelo `house_hash`, `WING_SHARE`), com lote de três ou mais células, dois ou mais andares e telhado
  de duas águas, perde o último andar na coluna de células de −X. A coluna vira uma ala mais baixa, com telhado próprio
  **cruzado** com o do corpo (com a cumeeira do corpo ao longo de x, a da ala corre em z; senão, quatro águas) e da altura
  que cabe no andar tirado (`WING_ROOF`, `WING_ROOF_FLOOR`: a cumeeira da ala fica abaixo do beiral do corpo). O corpo leva
  o telhado de sempre, uma coluna mais estreito, e ganha a parede lisa do lado da ala no último andar. A chaminé fica no
  outro lado. Os camponeses (a casinha com quintal) e o telhado plano não têm ala.
- **Uma regra só para as paredes**: `slot()` devolve `&"none"` nas células que a ala tira, e tudo o que já lia o `slot`
  acompanha sozinho — as peças de parede, os vidros acesos à noite (`windows()`, `WindowLightsView`), o caixilho, as
  floreiras, as vergas e os peitoris.
- **Cornija**: a do alto só sobre o corpo; a ala ganha a dela no topo (a floreira dos artesãos não tem as faixas entre
  andares, que nos engenheiros e investidores já passam ali).

## No caminho

- A primeira versão dava à ala 70% da altura do telhado do corpo: numa ala de uma coluna isso virava uma agulha que
  passava do beiral do corpo (11,6 m numa casa de 11). O teste pegou; a altura passou a caber no andar tirado.

## Números

- Constantes de apresentação. As formas de casa em cache dobram (com e sem ala); cada malha nova custa ~18 ms na primeira
  vez (o aquecimento atrás da cortina, Fase 32, cobre as do rascunho).

## Como testar

- `tests/presentation/test_phase96_house_wings.gd`: a ala tira só o último andar da coluna da ponta (frente, fundo e o
  lado dela); as janelas acesas perdem exatamente as que a ala tirou e nenhuma fica acima dela; nada passa por cima da
  ala além do telhado dela; camponeses e telhado plano sem ala, e as outras metade com e metade sem.
- Captura: `tools/capture_phase95.tscn` ganhou a tomada em diagonal de cada rua (`rua_<classe>_c.png`).
