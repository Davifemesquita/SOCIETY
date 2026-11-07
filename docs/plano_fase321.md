# Plano da Fase 321 — Crista sem risco

**Estado: feita em 05/11/2026**, a segunda do roteiro `docs/plano_fases_320_324.md` (garganta de perto). No alto da garganta sobrava
uma linha de terra alaranjada entre o capim e a rocha. A captura com `bank_edge=0` mostrou de onde ela vem: é a beira do barranco
da Fase 289, cuja terra sai da textura da estrada (alaranjada) com `bank_soil_tint`. A lama do alto já tinha virado capim na Fase 315.

## O plano

- **Arquivos**: `shaders/terrain.gdshader`, `world/terrain/terrain_view.gd`, `tools/capture_phase317.gd` e o teste novo.
- **Risco**: a beira é a mesma em todo barranco (patamares, falésias, gargantas). Por isso só muda acima de `gravel_top_m` e só nas
  temperadas; a faixa, as pedras e as raízes continuam lá (o capim não acaba de uma vez na rocha).
- **Como testar**: o teste novo, o da Fase 315, a captura da garganta e o benchmark.

## O que entrou

- **`shaders/terrain.gdshader`**, dentro da beira da Fase 289, antes de a cor sair da terra: com `bank_edge_grass` (a `TerrainView`
  põe 1 nas temperadas), acima de `gravel_top_m` (no mesmo `high_bank_fade_m` da Fase 315) a terra vira a grama do lugar em
  `bank_turf_shade` (capim rente, mais escuro e mais seco), e a pedra aparece mais (`bank_turf_stones`, de 0,45 em vez de 0,55).
- **`tools/capture_phase317.gd`**: `CAPTURA_TERRENO` e `CAPTURA_AGUA` (`nome=valor,nome=valor`) trocam uniformes dos shaders, para
  tirar o antes e o depois sem mexer no código.

## Medida

31,3 FPS (320: 31,0), GPU 26,7 ms (320: 26,9), com a máquina ainda na condição lenta da 320. Neutra.

## Como testar

- `tests/world/test_phase321_bank_turf.gd`: o capim rente no lugar da terra, só acima do cascalho, depois da terra de antes e antes
  da cor da beira; desligado por padrão; ligado só nas temperadas; o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase317.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase320\depois\`, depois em
  `F:\ferramentas\capturas\fase321\depois\` (e a beira desligada, o diagnóstico, em `fase321\diag_sem_beira\`).
