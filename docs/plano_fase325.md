# Plano da Fase 325 — Prado sem xadrez

**Estado: feita em 05/11/2026**, a primeira do roteiro `docs/plano_fases_325_329.md` (prado e mata). O capim aberto tinha quadrados
claros e escuros alinhados com os eixos, de perto (90 m) e de cima (420 m); no Anno, o prado varia em manchas sem forma de grade.

## O plano

- **Arquivos**: `shaders/terrain.gdshader`, `shaders/grass_carpet.gdshader`, o include novo `shaders/meadow_patch.gdshaderinc`, a
  captura `tools/capture_phase280.gd` e o teste novo.
- **Risco**: a causa não era conhecida (o hex-tiling da Fase 34 fica só no ultra, e a repetição de 12 m da textura era suspeita). O
  tapete de capim da Fase 286 pinta os tufos pelas mesmas manchas: as duas contas precisam continuar iguais.
- **Como testar**: capturas com cada efeito desligado pelo `CAPTURA_TERRENO`, o antes e depois do prado de perto e de cima, o teste
  novo e o benchmark.

## A causa

Com o prado capturado cinco vezes (`F:\ferramentas\capturas\fase325\xadrez\`): o hex-tiling ligado, a reamostragem de longe
desligada e a macro-variação desligada deixam o xadrez igual; **só `meadow_patches=0` o tira**. As manchas do prado da Fase 285 eram
duas oitavas de ruído de valor, cujos nós ficam numa grade alinhada com os eixos. Cada nó vira um quadrado de cantos redondos, e
as curvas de nível dentro da célula são quase retas. Com o corte estreito do capim alto (0,52 a 0,62) e do baixo (0,38 a 0,48)
por cima, o prado ficava em quadrados.

## O que entrou

- **`meadow_patch`** (`shaders/meadow_patch.gdshaderinc`), incluído no terreno e no tapete de capim depois do `value_noise`: as
  coordenadas torcidas por um ruído largo (`MEADOW_WARP` vezes a mancha, em `MEADOW_WARP_SCALE` manchas), a oitava larga em **ruído
  de gradiente** (`meadow_gradient`, Perlin com a curva de quinto grau) girada `MEADOW_TURN_RAD`, com `MEADOW_GRADIENT_GAIN` para
  ficar com o espalhamento de antes, e a oitava fina de valor girada mais uma vez.
- Tentativas que não bastaram (capturas em `depois` e `depois2`): só girar e torcer o ruído de valor deixou os quadrados girados.
  A média de duas leituras giradas tirou o xadrez de perto, mas de cima ainda deixava facetas triangulares de 15 a 40 m.
- **Captura**: o `tools/capture_phase280.tscn` ganhou `CAPTURA_TERRENO` (`nome=valor,...`, `true`/`false` nos bool) e `CAPTURA_SO`
  (`prado`: a falésia e o mar de cima; `dia`: as vistas de dia).

## Medida

71,2 FPS, GPU 13,1 ms (319: ~72 FPS, GPU de 12,8 a 13,0 ms), com a máquina de volta à condição normal. Neutra.

## Como testar

- `tests/world/test_phase325_meadow_noise.gd`: os dois shaders pela mesma função, as constantes iguais às do teste, a conta portada
  cobrindo de capim alto e baixo o mesmo tanto do prado que a de antes (a 8 pontos percentuais), e os shaders compilando (com tela).
- Captura: `CAPTURA_SO=prado tools/capture_phase280.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase325\xadrez\a_base\`,
  depois em `depois3\` e `depois_dia\`, e a comparação em `antes_depois3.png`.
