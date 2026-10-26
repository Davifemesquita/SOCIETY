# Plano da Fase 47 — QoL de interface

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima
sexta fase do roteiro de `docs/plano_melhorias.md`. Nenhum campo novo no save: o que pedia campo (nome e grupo da rota)
foi para a Fase 49, que já sobe a versão. Nada aparece na tela do dono (testes sem janela; capturas e benchmark na área
de trabalho escondida). **A prioridade dos itens e o teste com uma pessoa de fora continuam com o dono.**

## 1. Copiar prédio (`ui/build/build_tool.gd`, `ui/hud/selection_panel.gd`)

- `BuildTool.copy_building(id)`: a obra do mesmo tipo, com a rotação do original; cada cópia sai com a configuração dele
  (pausado e o bloqueio de subida de classe, pelos comandos que já existem). Qualquer obra nova desfaz o modo cópia.
- O botão "Copiar" vale para todo prédio (antes só a produção, e só o tipo); a ação `build_copy` copia o selecionado ou o
  prédio sob o cursor.

## 2. Busca e lista dos existentes (`ui/hud/hud.gd`)

- Campo "Buscar prédio" na linha das abas: o texto vira a lista dos prédios de todas as abas cujo nome o contém, sem
  diferença de maiúsculas e acentos (`Hud.folded`, `search_results`), na língua da vez; Enter escolhe o primeiro, Esc
  limpa, clicar numa aba desfaz a busca. Ação `build_search` põe o foco nele.
- Os existentes: a dica de cada cartão diz quantos há; o painel do selecionado tem "Próximo igual", que passa pelos
  prédios do mesmo tipo em todas as ilhas e leva a câmera (`SelectionPanel.same_kind`, `next_same`).

## 3. Do prédio e do bem para a estatística e os produtores

- "Estatística" no painel da produção abre a janela no bem que ela produz, na ilha dela (`StatisticsWindow.show_good`).
- Na janela, cada bem tem um botão que vai ao próximo prédio que o produz (`producer_requested`, `Hud.next_producer`).

## 4. Dicas que decompõem (`sim/breakdown.gd`, `ui/hud/breakdown_label.gd`)

- `Breakdown` (simulação, só leitura): cada bem por fonte — a produção de cada tipo de prédio, o consumo dos prédios que o
  usam e o das casas repartido pelas classes na proporção do que cada uma pede; o dinheiro — imposto por classe, acordos,
  manutenção por tipo de prédio (com pausa e especialista), navios e salários. As parcelas fecham exatamente com a tela
  (produção menos consumo da linha; receita menos manutenção do último tick, para a qual as parcelas são escalonadas).
- `BreakdownLabel`: a dica (`_make_custom_tooltip`, `RichTextLabel`) só calcula quando o mouse para em cima. Está no nome
  de cada bem nas estatísticas e na linha das finanças.

## 5. Rotas (`ui/hud/route_window.gd`, `ui/hud/archipelago_map.gd`)

- Duplicar (uma rota nova com cópias das paradas e ordens, sem os navios, pelos comandos que já existem); Shift ao pôr
  uma ordem enche a vaga do navio (a menor vaga dos navios da rota, ou a do mercante); o mouse sobre uma rota da lista a
  destaca no mapa (`hover_route_id`); filtro por ilha guardado nas opções (`Settings.route_filter`).

## 6. Modo foto (`ui/screens/photo_mode.gd`)

- Do menu da partida ("Modo foto") ou da ação `photo_mode`: a HUD e os ícones de estado somem, a partida pausa, o clique
  no mundo não seleciona; um painel pequeno com a hora do dia e a inclinação da câmera (`CameraRig.pitch_offset_deg`, de
  −20° a +15°, sempre entre 5° e 89°), que some depois de 3 s sem mexer o mouse. Esc ou "Sair" devolve hora, inclinação,
  velocidade e interface.

## Atalhos

`build_copy`, `build_search` e `photo_mode` entram **sem tecla padrão** (não roubam tecla de ninguém, como o Anno 117
no patch 2.0) e aparecem na lista de remapear das opções.

## Achado junto: o terreno v2 no Linux

O CI das Fases 45 e 46 falhou em `sim`: as assinaturas do v2 só valiam no Windows (seno, cosseno e `pow` da biblioteca do
sistema). Consertado num commit próprio da Fase 45 (`DetMath`), conferido no Linux pelo WSL; ver `docs/plano_fase45.md`.

## Números

- Benchmark (área de trabalho escondida): tick 1,27 ms de média (igual), obra com a ilha cheia 18,1 ms (igual), quadro e
  GPU iguais. A linha nova mede a dica no pior caso, com a cidade do benchmark: um bem em todas as ilhas 0,18 ms, o
  dinheiro 1,5 ms (só no hover).

## Fica de fora

- Nome e grupo da rota (campo novo no save: Fase 49, com a versão nova); tooltips aninhados e traváveis; desfazer e
  planta (Fase 49); stamps; notas no mapa.
- Lista dos existentes como janela própria: ficou como contagem na dica e o "Próximo igual".

## Como testar

- `tests/sim/test_phase47_breakdown.gd`: cada bem fecha com a linha das estatísticas; o consumo das casas por classe; todas
  as ilhas = a soma de cada; o dinheiro fecha com receita − manutenção (com uma padaria pausada e com navios); ler não
  mexe no estado.
- `tests/ui/test_phase47_qol.gd`: cópia (tipo, rotação, pausa, bloqueio), busca em pt_BR e en, atalhos sem tecla e
  remapeáveis, estatística e produtores, texto da dica com a soma, ações de rota, filtro guardado, modo foto entrando e
  devolvendo tudo, os textos novos nas duas línguas.
- Capturas: `tools/capture_phase47.tscn` (busca, painel, estatísticas, as duas dicas, rotas, modo foto com e sem painel).

## Pronto quando

Copiar, buscar, ir à estatística, decompor e as ações de rota funcionam por mouse e por teclado (as teclas que o jogador
escolher). **Proposta à espera do dono**: priorizar os itens, testar com alguém de fora e escolher teclas padrão, se
quiser alguma.
