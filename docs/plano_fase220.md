# Plano da Fase 220 — Bomba de incêndio no quartel

**Estado: feita em 01/11/2026**, a primeira do roteiro `docs/plano_fases_220_224.md` (bomba, barril e lençol, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`FirePumpView.sites`, `cells`): em cada quartel de bombeiros, as duas células do meio do lado de −X do modelo, depois o
  de +X e por fim o de trás, pelo `SideYard` da Fase 219, fora dos pátios de lado de antes (tábuas, carvão e escola). O recheio e
  as bombas d'água as deixam limpas.
- **A bomba** (`pump_mesh`, `_wheel`): a caixa vermelha sobre duas rodas grandes atrás e duas menores na frente (rodas de raios,
  com o aro em doze lanços), os dois cilindros de latão e a câmara de ar com a cúpula, os dois braços compridos dos bombeadores
  no eixo e as travessas das pontas, e o timão até o chão; ao lado, o carretel da mangueira enrolada em duas rodas; na parede, a
  escada deitada e a trave com os baldes de couro. Um MultiMesh, no meio das duas células.

## Como testar

- `tests/world/test_phase220_fire_pumps.gd`: nas quatro rotações a bomba fica de lado, encostada no quartel, nunca na frente; com
  uma das células bloqueada, vai para o outro lado; outros prédios não têm; o recheio e as bombas d'água deixam as células; a
  malha cabe nas duas células e as rodas não se tocam.
- Captura: `tools/capture_phase220.tscn` (dois quartéis na ilha plana; `bomba_de_perto.png`, `bomba_e_quartel.png`,
  `bomba_de_longe.png`).
