# Plano da Fase 43 — Interface enxuta

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
segunda fase do roteiro de `docs/plano_melhorias.md`. Nada muda na simulação nem no save; as preferências novas vão no
`user://settings.cfg`. Nada aparece na tela do dono (testes sem janela; benchmark na área de trabalho escondida).

O papel das fontes, as cores corrigidas e o feed de avisos são **proposta à espera do dono** — e do primeiro teste com
uma pessoa de fora, que o roteiro pede.

## 1. Contraste e fontes (`ui/theme/`)

- **WCAG**: o texto passa de 4,5:1 sobre o fundo dele e o foco e as bordas de 3:1 (teste com a luminância relativa
  do WCAG, que lineariza o sRGB — o `get_luminance()` do Godot não lineariza). O verde e o âmbar dos indicadores e, no
  modo para daltonismo, o laranja e o vermelhão escureceram o mínimo; o contorno do foco ganhou cor própria
  (`UiPalette.FOCUS`, o dourado ficava em 2,1:1).
- **Fontes**: a Playfair só nos títulos grandes (TitleLabel, BigLabel e o novo PeriodTitle); cabeçalhos e os botões
  grandes do menu na Old Standard em negrito; o dinheiro e a população com algarismos tabulares (`NumberLabel`).
- **Variações novas**: PeriodTitle, NumberLabel, PlainCard (cartela lisa sob números e listas) e MedallionButton.
- **Escala até 200%** (`ui_scale_max`), com o aviso nas opções quando o corpo do texto fica abaixo de 18 px. As capturas
  mostraram a HUD cortada a 200% em 1080p: a escala aplicada é limitada pela largura da janela (a HUD pede 1.920 px
  lógicos; 200% cabe inteiro a partir de 4K), com um aviso nas opções quando a escolhida não cabe. **Fonte
  legível** (uma sem serifa do sistema, com a Old Standard de reserva) e **reduzir movimento** (contadores, pulso, obra,
  demolição, avisos e zoom suave param; `SceneFader.still()`).

## 2. Avisos (`ui/hud/notification_feed.gd`)

- A mesma situação com o aviso na tela vira **um bloco com contador** ("×3"), renovado e levado para cima.
- **Categorias** (economia, alertas, frota, diplomacia, encomendas e eventos, marcos e conquistas), cada uma
  silenciável nas opções; **pausa automática** num alerta grave (opção); **duração** escolhida nas opções (6 a 48 s).
- O clique que leva ao objeto já existia.

## 3. Menu de construção (`ui/hud/hud.gd`)

- Os prédios da categoria num **painel próprio que encolhe ao conteúdo** (no máximo oito cartões por linha): o porto,
  com três, deixa de ficar num painel de 1.000 px quase vazio.
- A aba de produção escolhida mostra **o nome da classe ao lado do medalhão**.

## 4. Som e créditos

- **`UiSfx`** (autoload): clique ao apertar e um toque leve ao passar o mouse em todo botão, em qualquer tela (antes, só
  dentro da partida), no barramento Interface.
- **`CREDITS.md`**: a tabela dos ícones do game-icons.net por autor, com os desenhos de cada um; os três selos sem autor
  registrado foram para `assets/TODO_ASSETS.md`.

## Fica de fora

- **`DPITexture`** nos ícones (experimental na 4.7): o atlas 2× continua.
- **Barra de cima reorganizada** e o ruído do papel limitado nas áreas de texto: pedem o teste com gente de fora antes.
- Interruptor de "UI antiga"; tooltips aninhados; menu principal (Fase 44).

## Como testar

- `tests/ui/test_phase43_interface.gd` (roda sem tela): contraste WCAG do texto, dos estados e do foco; tamanhos de fonte
  e o aviso abaixo de 18 px; a cadeia de foco do menu principal; as chaves novas em pt_BR e en; o contador, o silenciar,
  a pausa e a duração dos avisos; o "reduzir movimento"; o painel dos prédios que encolhe e o nome da classe na aba.
- Os testes da interface que já existiam (tema e ícones, avisos, menus) sem tela, e a pasta `ui` no CI.
- Benchmark sem regressão.

## Pronto quando

O menu de construção não tem painel vazio; os avisos repetidos viram um bloco com contador; o teste de contraste passa;
200% não corta conteúdo (a conferir nas capturas da HUD em 1080p, 1440p e 4K); uma pessoa de fora testa a HUD nova e o
dono aprova o papel das fontes.
