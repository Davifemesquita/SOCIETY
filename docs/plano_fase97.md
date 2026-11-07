# Plano da Fase 97 — Cúpulas e torreões

**Estado: feita em 29/10/2026**, terceira do roteiro `docs/plano_fases_95_99.md` (formas mais redondas, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Cúpula de cobre** (`BuildingKit.Spec.dome`, `_dome`, `DOMED`): o teatro, a universidade, a prefeitura e o museu, quando
  o telhado é de quatro águas, ganham no meio dele um tambor de pedra clara que sai das águas até `DRUM_M` acima da
  cumeeira, com cornija e oito vãos escuros, a meia esfera de cobre (`DOME_RISE` do raio; raio de `DOME_SHARE` do lado
  menor, até `DOME_MAX_M`) e o lanternim com a capinha de cobre e o remate.
- **Torreão** (`Spec.turret`, `_turret`, `turret_center`): as casas de pórtico (investidores) com três andares ou mais
  ganham no canto da frente de +X um torreão redondo em balanço desde o primeiro andar: o cone de pedra que o segura, o
  fuste na cor da parede subindo `TURRET_ABOVE` de um andar acima do beiral, a cornija, vãos por andar para a frente, o
  canto e o lado, e o telhado cônico com remate de ferro. A sacada encurta uma célula para não atravessar o torreão.
- **Peças torneadas** (`_turned`): um perfil girado em volta do eixo vertical, com as normais do perfil — a mesma ideia
  do poste da Fase 26, agora no kit dos prédios.
- **Cobre no shader** (`shaders/building_kit.gdshader`, célula (2, 1) da paleta, `UV_COPPER`, livre no kit): verde de
  azinhavre entre `copper_dark` e `copper_light`, com escorridos pelo ruído do musgo e rugosidade 0,5.

## Números

- Constantes de apresentação. Uma forma a mais em cache por casa com torreão e por serviço com cúpula.

## Como testar

- `tests/presentation/test_phase97_domes_turrets.gd`: o teatro tem cobre e passa da cumeeira; a cúpula cabe no telhado;
  igreja, mercado, cervejaria e armazém sem cúpula nem cobre; a casa alta dos investidores tem o torreão no canto da frente
  passando do beiral; as outras classes, sem.
- Captura: `tools/capture_phase95.tscn` (`grandes_a.png` com as cúpulas, `rua_investors_a.png` com os torreões).
