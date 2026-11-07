# Plano da Fase 102 — Enxaimel saliente

**Estado: feita em 29/10/2026**, terceira do roteiro `docs/plano_fases_100_104.md` (a rua habitada, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save; o lote e a porta são os mesmos.

## O que entrou

- **Quem tem** (`BuildingKit.Spec.jetty`): as casas dos operários e dos artesãos com o telhado de cumeeira ao longo da
  frente (o beiral fica na frente e cobre o avanço) e dois andares ou mais.
- **O avanço** (`JETTY_M`, menor que o menor beiral): está no `_cell_transform`, a conta que põe tudo pela célula da
  fachada. Os andares de cima da frente avançam, e as paredes, os vidros acesos à noite (`windows()`), o caixilho, as
  floreiras, as vergas e os peitoris acompanham sozinhos. O térreo e os outros três lados não mudam.
- **O balanço e o enxaimel** (`_jetty`): a viga do balanço sob o primeiro andar, uma mão-francesa em cada divisa de célula
  (`JETTY_BRACKET_M`), e na frente de cada andar de cima o baldrame, o frechal, os esteios nas divisas e as escoras (uma de
  cada lado da janela; na parede lisa, uma diagonal). Nas pontas de cada trecho da frente que avançou, um pedaço de parede
  fecha o vão até a parede do lado (também onde a ala da Fase 96 tira o último andar).
- **Cornija** dos artesãos: ganha a parte da frente que acompanha o avanço.

## Como testar

- `tests/presentation/test_phase102_jetty.gd`: só operários e artesãos com cumeeira ao longo da frente e dois andares têm o
  avanço; só as janelas dos andares de cima da frente andam, exatamente `JETTY_M` para a rua; o corpo dos andares de cima
  fica no avanço (o peitoril passa um pouco) e o beiral passa dele; o enxaimel acrescenta madeira à fachada.
- `tests/presentation/test_window_lights.gd`: o alcance das janelas na fachada conta o avanço.
- Captura: `tools/capture_phase95.tscn` ganhou `enxaimel_de_perto.png`.
