# Plano da Fase 329 — Praia em curva

**Estado: feita em 07/11/2026**, a quinta e última do roteiro `docs/plano_fases_325_329.md` (prado e mata). Na praia, a beira da
areia com a água e a faixa de seixos faziam escadinha (os cantos das células) e um degrau marrom entre as duas; no Anno, a beira da
praia é uma curva que entra na água.

## O diagnóstico

O degrau não era cor: era o relevo. O perfil da praia da vila na semente 1840 (`CAPTURA_MAR=perfil` do `tools/capture_phase295.tscn`)
sai `1,25 1,21 −1,20 −1,20…`: o patamar da praia fica a 1,2 m e cai 2,4 m em um lado de canto (2 m) até o fundo. A face dessa
parede, quase de pé, levava a areia escura, os seixos (a inclinação dos dados contava como rocha perto, Fase 292) e as rochas
encaixadas (Fase 56); a borda de cima dela seguia as linhas da grade: a escadinha. O terreno da simulação (e as assinaturas) não
pode mudar, então a correção é só no desenho.

## O plano

- **Arquivos**: `world/terrain/terrain_detail.gd` (a rampa), `world/terrain/terrain_view.gd` (o bake pela altura desenhada e o
  prédio novo), as vistas que põem coisas na beira da praia, o teste novo, o da Fase 36, `AGENTS.md` e o roteiro.
- **Risco**: a célula plana da praia pode receber prédio, e até ali a malha fica abaixo da simulação (a prévia do prédio fica no ar
  até ele ser posto); as peças da praia que leem a altura da simulação flutuariam; a linha d'água não pode andar (a espuma e a
  areia molhada saem da costa da simulação).
- **Como testar**: o teste novo, o da Fase 36, a pasta `world`, as capturas antes e depois (`tools/capture_phase280.tscn`).

## O que entrou

- **A rampa** (`TerrainDetail._add_beach`, somada no `offsets` onde o detalhe das encostas não mexeu): os pontos da linha d'água
  saem de cada lado de canto a canto que cruza o zero com o mar de verdade (o rio fica de fora); cada canto a até `BEACH_REACH`
  (4) cantos ganha a distância até o ponto mais perto e a altura da terra dele. Terra até `BEACH_MAX_M` (2,5 m) desce até a rampa
  de `BEACH_SLOPE` (0,3 m por m, ±`BEACH_SLOPE_VARIATION` pelo ruído); o fundo do mar em frente sobe até a mesma rampa, no máximo
  `BEACH_SEA_RAISE_M` (1,5 m). A linha d'água fica onde estava (nenhum canto troca de lado) e a falésia não muda (a terra do
  ponto mais perto acima de 2,5 m).
- **Onde não**: nos cantos de célula com prédio, estrada, trilho, árvore (ou derrubada) ou rio (`holds_something`). A célula plana
  da praia pode ter rampa; a `TerrainView` a volta à altura da simulação quando um prédio chega (`_on_building_placed`, o mesmo
  conserto da estrada da Fase 36).
- **O bake** dos dados do terreno (inclinação, curvatura) sai das alturas desenhadas: a rampa não vira rocha. A distância da
  água e a costa seguem da simulação.
- **As peças da praia** sentam na altura desenhada (`TerrainDetail.shown_at`): focas, casco naufragado, barco na areia, farol,
  cabines de banho, guarda-sóis, secadouro de peixe, cervos, coelhos, cabras e o tapete de capim.
- **De quebra**: a linha de detritos da Fase 35, que ficava na parede, agora corre pela areia (é a linha de sargaço da maré); as
  rochas encaixadas e a faixa de seixos que nasciam da parede saíram com ela (os seixos seguem junto da rocha de verdade).

## Medida

Na semente 1840: 3.556 cantos da terra baixados, 5.975 do fundo erguidos, 320 degraus de praia desfeitos; o lado de canto mais
íngreme na beira de fundo raso caiu de ~2,4 m para 0,70 m em 2 m. A rampa custa ~134 ms nas oito ilhas, uma vez, ao montar o
terreno (o detalhe das encostas inteiro, ~210 ms). Nada no quadro: as malhas têm os mesmos vértices.
Benchmark com a máquina no estado lento: 63,5 FPS, GPU 14,6 ms, carregar 6.958 ms; o A/B no commit da Fase 328 deu 61,6 FPS, GPU
15,1 ms, carregar 6.878 ms.

## Como testar

- `tests/world/test_phase329_beach_ramp.gd`: a rampa sem mover a linha d'água, o degrau desfeito, a falésia e o que tem algo da
  simulação sem rampa, determinístico e o `shown_at`, e o prédio na praia voltando a célula à altura da simulação.
- `tests/world/test_phase36_slopes.gd`: as células planas podem ter a rampa da praia, as que têm algo da simulação não.
- Captura: `tools/capture_phase280.tscn` com `CAPTURA_SO=dia`; antes em `F:\ferramentas\capturas\fase329\antes\`, depois em
  `depois\`.
