# Plano da Fase 37 — Luz e cor de época (nossa)

**Estado: em andamento desde 25/10/2026**, com a confirmação do dono do produto ("pode ir para a próxima fase do
projeto"). Sexta fase do roteiro de `docs/plano_melhorias.md`. Só configuração e apresentação. **Feita sem tela**
(decisão do dono): o visual fica atrás de uma opção desligada por padrão, para ele comparar quando liberar a tela.

## 1. Cor de época (opção, desligada por padrão)

- `PeriodGrade`: LUT 3D de 33³ gerado no código a partir do neutro (não há LUT CC0 de época pronto): realces âmbar,
  sombras levemente frias, verdes e azuis ~15% menos saturados, preto levemente erguido. Função pura (`grade`).
- Com a opção "Cor de época" (Opções → Gráficos; `Settings.period_look`, gravada nas preferências): o LUT no
  `Environment.adjustment_color_correction` e o AgX com `white` 7 e `contrast` 1,1 (`GameConfig.period_agx_*`).
  Desligada, o `Environment` volta exatamente ao de antes.

## 2. Por nível gráfico

- **SSR** e **sol com tamanho** (`light_angular_distance` de 0,5°, que liga a sombra suave de contato, PCSS): **só no
  ultra**, e o SSR lá na resolução cheia. O plano pedia SSR em meia resolução no alto e PCSS no alto e no ultra; mas o
  alto já está em ~46 FPS na RTX 5060, e o dono tirou o hex-tiling do alto pelo mesmo motivo. A troca é um campo do
  `GraphicsPresetDef` (`ssr`, `ssr_half_size`, `sun_angular_distance_deg`).
- A oclusão especular já vem ligada no projeto (`rendering/reflections/specular_occlusion/enabled`).

## 3. Auditoria das luzes noturnas (512 elementos por tela, 88 sombras posicionais)

Todas as luzes do jogo são **sem sombra** (só o sol e a lua do Sky3D têm): as 88 sombras não chegam perto. Elementos
clusterizados na tela, no pior caso: até 24 luzes de área das janelas (ultra; 12 no alto), 10 lampiões, uma luz por
incêndio e um decal de fuligem por fábrica pesada à vista. Cabe nos 512 com folga; só uma cidade com centenas de
fábricas pesadas na mesma tela chegaria perto (os decals saem no nível baixo).

## 4. Para o dono comparar (`tools/capture_phase37.tscn`)

A ilha a 420 m e o litoral do entreposto a 110 m, às 7h, 11h, 18h30 e 22h, com a cor de época desligada e ligada.
Precisa de GPU: roda quando o dono liberar a tela.

## Fica de fora (e por quê)

- **Névoa de distância com perspectiva aérea e espalhamento do sol**: o Sky3D já faz a névoa do céu; somar a do
  `Environment` sem poder olhar arrisca dobrar o efeito. Entra numa rodada com tela.
- **Temperatura e ângulo do sol, hora padrão**: o Sky3D os controla pela hora do dia; mexer sem ver é chute.
- **Inclinação da câmera** (A/B de `camera_pitch_far_deg` entre 55° e 60°): decisão do dono, olhando.
- **Recolorido dos navios do Kenney**: escolha de cor, olhando (as pedras já mudaram na Fase 36).
- **Janelas emissivas ao anoitecer**: já existem (`WindowLightsView`).
- Contact shadows e AO multi-bounce (Fase 48); GI; vinheta e grão.

## Como testar

- `tests/world/test_phase37_light.gd` (sem tela): a gradação (preto erguido, realce quente, sombra fria, cinza quase
  cinza, verdes e azuis contidos, vermelho não), o LUT de 33³, o `Environment` com e sem a opção, SSR e PCSS só no
  ultra, e a opção gravada e desligada por padrão.
- Quando o dono liberar a tela: `tools/capture_phase37.tscn` e o benchmark do ultra (SSR e PCSS custam).

## Pronto quando

O dono escolhe, pelas capturas, se a cor de época fica ligada por padrão; o ultra com SSR e PCSS medido no PC.
