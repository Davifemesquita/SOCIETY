# Plano da Fase 364 — MegaKit ligado por padrão

**Estado: feita em 07/11/2026**, a quarta do roteiro `docs/plano_fases_361_365.md`. As paredes, janelas e portas do Medieval Village
MegaKit (Quaternius, CC0) são agora o padrão dos prédios; `SOCIETY_MEGAKIT=0` volta ao kit do Kenney (para comparar e medir).

## O que entrou

- `BuildingKit.megakit_walls()` ligado por padrão (só `SOCIETY_MEGAKIT=0` desliga); `test_phase360_megakit` confere o padrão.
- As fotos dos cartões do menu (Fase 51, `tools/bake_building_photos.tscn`) refeitas com os prédios novos (69 fotos em `ui/photos/`).

## Como testar

- A suíte inteira no padrão novo: core 57, data 18, sim 374, tools 15, world 826, presentation 425 e ui 167 casos, nenhuma falha.
- Benchmark (área de trabalho escondida, estado lento da máquina): 63,5 FPS, 1% low 35,9, GPU 14,8 ms, carregar 7,0 s. No A/B da
  Fase 362, o MegaKit custa ~0,2 ms de GPU e ~1 FPS sobre o Kenney.
- Capturas das fases 360 a 362 em `F:\ferramentas\capturas\fase36x\`.

## Fica para depois (Fase 365)

- A linha escura atravessando as paredes de pedra a meia altura do andar (casas dos artesãos) e as frestas entre os andares na
  frente do enxaimel saliente.
- O telhado e as quinas do pacote.
