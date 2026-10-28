# Plano da Fase 63 — Jornal

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir com o jornal"; das propostas novas depois da Fase 62,
a primeira: o jornal semanal do Anno, simplificado). Mexe na simulação, mas só nas partidas com os eventos ligados
(como os eventos e as encomendas da Fase 11): o mundo novo da simulação, os testes, o robô e as assinaturas não mudam.

## O que entrou

- **Manchetes** (`HeadlineDef`, `data/headlines/`, `GameData.headlines`): seis de notícia (semana tranquila, elogio do
  porto, boatos de carestia, medo do cólera, escândalo na Companhia, visita real; de −8 a +10 de felicidade, com peso
  e marco) e três de propaganda (o progresso, prosperidade, orgulho da Companhia; +8, +10 e +12, liberadas pelos
  marcos). Título `HEADLINE_<ID>`, texto `HEADLINE_<ID>_DESC`, em português e inglês.
- **Edição** (`NewspaperSystem`, depois das encomendas): a primeira sai `newspaper_first_after_s` (300 s) depois do
  começo, as seguintes a cada `newspaper_interval_s` (600 s). A manchete é sorteada pela semente e pelo número da
  edição, entre as de notícia liberadas pelos marcos, e vale até a próxima: soma a felicidade dela ao alvo das casas
  de todas as ilhas (`EventEffects.happiness`).
- **Propaganda** (`BuyPropagandaCommand`): uma vez por edição, por `newspaper_propaganda_cost` (2.500 moedas), troca a
  manchete pela de propaganda escolhida até a próxima edição. Recusa antes da primeira edição, repetida, manchete que
  não é de propaganda ou ainda bloqueada pelo marco, e sem dinheiro.
- **Save**: a edição, a próxima, a manchete e a propaganda usada vão no estado dos eventos; o save de antes do jornal
  carrega sem edição (sem migração), e manchete desconhecida recusa o save.
- **Tela**: o jornal ("Gazeta do Arquipélago") no alto da janela das encomendas (J, agora "Jornal e encomendas"), com
  a manchete, o texto, o efeito e o tempo até a próxima edição, e um botão por propaganda com o preço (desligado depois
  da compra ou sem dinheiro). A edição nova vira aviso (categoria encomendas e eventos) que abre a janela, verde se a
  manchete sobe a felicidade e laranja se tira. Sem asset novo (o ícone é o do aviso de encomenda).

## Números

- Benchmark (alto, RTX 5060): tick médio 1,27 ms, a etapa dos eventos e do jornal 0,01 ms (o benchmark roda com os
  eventos desligados, como o robô), dia inteiro 87,6 FPS, GPU 10,8 ms; nada no desenho (`docs/benchmark.md`).

## Como testar

- `tests/sim/test_phase63_newspaper.gd`: dados válidos (notícia boa e ruim, propaganda que sobe), nada com os eventos
  desligados, edições na hora e no intervalo, a mesma semente dá as mesmas manchetes, a felicidade da manchete em
  todas as ilhas e no alvo da casa, a propaganda uma vez por edição pelo preço, as recusas, o save e a continuação
  iguais, o save antigo e a manchete desconhecida.
- `tests/ui/test_phase63_newspaper_window.gd`: a manchete, o efeito e o tempo na janela, a compra pelo botão (e os
  botões desligados depois), antes da primeira edição e com os eventos desligados, o aviso que abre a janela.
- Capturas: `tools/capture_phase63.tscn -- <pasta>` (a janela com a notícia e com a propaganda; em
  `F:\ferramentas\capturas\fase63`).

## Fica de fora (proposta à espera do dono)

- Manchetes que dependem do estado do jogo (falta de um bem, incêndio, colônia nova), uma prensa/redação como prédio
  e propaganda que mexe em outra coisa além da felicidade (produção, chegada de moradores).
- O balanceamento dos números (efeitos, intervalo, preço) é provisório, à espera do dono.
