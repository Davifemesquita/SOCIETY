# Roteiro das Fases 386 a 405 — De bonito a jogável

**09/11/2026.** Depois do roteiro `docs/plano_fases_381_385.md`, o dono pediu os próximos roteiros com outro rumo: "pesquisar como
podemos dar um salto grande no jogo, deixando ele de fato jogável, eliminando principalmente os bugs, e deixando ele legal de se
jogar". As ~300 fases desde a 85 foram quase todas de visual. Este roteiro para de enfeitar e cuida de três coisas, nesta ordem:
achar os bugs sozinho, tirar as travas da primeira hora e deixar o estado do jogo sempre explicável. Só no fim mexe na
profundidade. O Anno não foi aberto.

## O que a pesquisa achou

Duas frentes, em 09/11/2026: uma auditoria do código pelo lado de quem joga e uma pesquisa na web. Na web entraram postmortens e
palestras da GDC (Battlefield V, The Division), os Friday Facts da Factorio, Kingdoms and Castles, Frostpunk, Against the Storm,
Banished e reviews do Farthest Frontier e do Manor Lords.

**O caminho padrão do jogo quase não foi testado.** O jogador-robô e o critério das 3 horas rodam numa ilha plana, sem eventos, sem
rivais e sem riscos. Em todo esse tempo o git tem só três commits de conserto. O jogo padrão nunca foi jogado de ponta a ponta por
ninguém, nem pelo robô. Esse jogo padrão é o arquipélago v4, com eventos, rivais, riscos, expedições, jornal, turismo, petróleo e
estaleiro.

**Travas confirmadas no código:**

- **Subida que desfaz a meta.** A casa sobe sozinha de classe assim que o básico é atendido e há o material
  (`population_system.gd:88`). A meta "roupas" pede 100 camponeses vestidos, e o mercado que ela manda construir transforma
  camponeses em operários. O robô só joga porque trava a subida, e nada ensina ao jogador que essa trava existe.
- **Fila de metas presa.** As metas andam em fila (`goal_system.gd:15`). A meta da colônia depende de sobrar uma ilha temperada
  livre, e as rivais podem tomar três das quatro antes dos 40 minutos.
- **Meta que aponta prédio bloqueado.** A meta da olaria aparece aos 100 operários, mas a olaria só libera com 150, e o painel não
  avisa.
- **Pouco litoral no v4.** O v4 garante só um lote de costa, o do entreposto. A pescaria, que é o alimento dos camponeses, a olaria,
  o areal, o píer e o estaleiro disputam as mesmas enseadas. Ninguém mediu quantos cabem.
- **Dívida sem aviso.** O dinheiro desce sem limite e sem aviso. O único sinal é o número ficar vermelho abaixo de −10.000.

**Bugs confirmados no código:**

- **Carroça presa para sempre.** Demolir a estrada debaixo de uma carroça a deixa presa: a busca de caminho exige estrada na célula
  de partida (`road_router.gd:50`), e o teste só cobre o corte à frente dela.
- **Expedição fora do limite de navios.** O navio em expedição sai da lista e deixa de contar no limite (`placement_rules.gd:177`).
  Dá para comprar outro e passar do teto quando ele volta.
- **Encomenda do estaleiro perdida em silêncio.** Demolir o estaleiro, ou perdê-lo no fogo, apaga a encomenda paga sem aviso e sem
  devolver nada.
- **Navio parado sem aviso.** O navio cuja rota não tem nenhuma parada válida fica parado, e ninguém é avisado.
- **Cenário herdando o terreno.** O cenário usa o terreno escolhido no último jogo novo (`game_screen.gd:1290`).
- **Entreposto da ilha principal demolido sem confirmação.** Depois dessa demolição, reconstruí-lo pede navio com materiais.

**O que o jogador não fica sabendo.** Não há histórico de avisos: cada um some em 12 s e só cabem 5 na tela. Ninguém avisa quando:

- uma casa fica sem estrada ou perdendo moradores;
- um navio fica sem caminho ou uma carroça bloqueada;
- um prédio novo é liberado ou chegam especialistas à venda (o sinal existe e ninguém escuta);
- um evento termina;
- o saldo fica negativo.

**O que é raso.** O comerciante compra e vende pelo mesmo preço, sem margem e sem saturação. Os sete eventos são multiplicadores
passivos, sem escolha. As rivais são um número de moradores numa ilha. No combate o navio atira sozinho pelo alcance.

**O que a pesquisa diz que funciona:**

- **Metas curtas ensinam sem tutorial**, como em Kingdoms and Castles e Frostpunk.
- **Uma pressão com consequência visível e sempre uma saída**, como em Against the Storm.
- **O estado sempre explicável**, como no Anno: t/min de produção contra consumo, o "por que não sobe" e a causa, não o sintoma.
- **Robôs que jogam a partida inteira para achar travas**, como a DICE e a Ubisoft fazem.
- **Invariantes conferidos a cada tick e replay determinístico**, como na Factorio.
- **Um bug relatado vira teste.**

## As fases

### Bloco A — Rede de segurança (386 a 390): o jogo acha os próprios bugs

| Fase | O quê |
|---|---|
| 386 — Invariantes | `WorldInvariants.check(simulation)`: estoque entre 0 e a capacidade; ocupação igual à refeita pelos prédios; todo id referenciado (carroça, rota, especialista, encomenda, risco, expedição) existe; dinheiro finito; carroça e navio não presos além do limite. Chamado nos testes longos e no robô |
| 387 — Robô no jogo de verdade | o jogador-robô no arquipélago v4 da semente, com eventos, rivais e riscos ligados, achando lugar pelo `SiteFinder` e colonizando; relatório do que cabe no litoral e de onde ele travou |
| 388 — Embaralhador de comandos | sequências sorteadas pela semente de todos os comandos (construir, demolir, mover, estrada, trilho, rota, desfazer, diplomacia, expedição, estaleiro), válidos e inválidos, com os invariantes a cada passo e o save → load → mesma partida |
| 389 — Replay | a partida grava a semente e os comandos com o tick; `tools/replay.tscn` refaz e para no primeiro invariante quebrado; um replay de bug vira teste |
| 390 — Consertos do bloco | os bugs confirmados acima e o que 386 a 389 acharem, cada um com o teste que o pega |

### Bloco B — Primeira hora sem trava (391 a 395)

| Fase | O quê |
|---|---|
| 391 — Metas que não travam | a meta da colônia aceita qualquer ilha que o jogador possa fundar; as rivais deixam ao jogador pelo menos uma temperada livre até ele colonizar; a meta que aponta prédio bloqueado diz o que falta para liberá-lo; a ordem das metas segue os desbloqueios |
| 392 — Subida explicada | a meta das roupas conta os moradores vestidos de qualquer classe; o conselheiro ensina a trava da subida na primeira subida; o painel da casa diz "vai subir quando…" |
| 393 — Litoral de trabalho | pela medida da 387: se a ilha principal do v4 não couber o litoral mínimo da primeira hora (pescarias, olaria, píer), o v5 aplaina lotes de costa como o v4 faz o do entreposto (versão nova, o v4 segue para os saves) |
| 394 — Dívida com aviso e saída | aviso ao ficar no vermelho e a cada piora; o painel do dinheiro mostra o que mais pesa e as saídas (pausar ociosa, vender ao comerciante); um empréstimo do banco com juros, pago aos poucos |
| 395 — Critério da primeira hora | um robô "jogador comum" (sem trava de subida, ordem das metas) em várias sementes do v4 chega a 100 operários e à primeira colônia sem nenhum invariante quebrado e sem meta parada mais de 15 min |

### Bloco C — Estado sempre explicável (396 a 400)

| Fase | O quê |
|---|---|
| 396 — Histórico de avisos | os avisos da partida numa lista que se abre (atalho), com a hora, o clique que leva a câmera e o filtro por categoria |
| 397 — Avisos que faltam | casa sem estrada ou perdendo moradores, carroça bloqueada, navio sem caminho ou sem parada válida, prédio liberado, especialistas à venda, evento acabado, encomenda vencendo, saldo negativo |
| 398 — Por que não sobe | no painel da casa, a linha que diz o que falta para subir (bem, serviço, material, trava), com o clique até o produtor ou o prédio que falta |
| 399 — Causa em cadeia | o painel do prédio parado segue a cadeia até a causa ("padaria parada: falta farinha → moinho sem trigo → fazenda sem campos") |
| 400 — Saldo das necessidades | na barra de cima, o saldo de cada bem de necessidade da ilha em semáforo, com as rotas contadas, e a dica com a produção, o consumo e o que entra pelo navio |

### Bloco D — Decisões que valem (401 a 405)

| Fase | O quê |
|---|---|
| 401 — Comerciante com margem | compra mais barato do que vende e o preço cai com o volume vendido na volta (saturação), voltando aos poucos |
| 402 — Eventos com escolha | parte dos eventos chega com duas opções (pagar e evitar, aceitar e ganhar), na janela das encomendas |
| 403 — Rivais no comércio | a rival compra e vende no comerciante e mexe no preço; o acordo deixa de ser renda de graça e vira desconto de comércio |
| 404 — Ordens no combate | escoltar, atacar o alvo, recuar ao porto; o bloqueio do porto pela fragata inimiga para o comércio da ilha |
| 405 — Primeira hora com gente | o checklist da primeira hora (`docs/primeira_hora.md`) e a telemetria local, desligada por padrão e gravada num arquivo do jogador: tempo até cada meta, onde para, os avisos ignorados |

## Regras do roteiro

- **Todo conserto entra com o teste que o pega** antes de ser consertado.
- **Mudança de regra do jogo é proposta à espera do dono**, registrada no plano da fase: a subida automática, o empréstimo, a margem
  do comerciante e o bloqueio. Ela entra pelo `GameConfig`, com número fácil de desfazer.
- **Save que muda sobe a versão**, com migração.
- **Os blocos A e B vêm primeiro.** Sem a rede de segurança, o resto quebra sem ninguém ver.
- O visual para: só entra se um conserto precisar.

## Estado

- Roteiro escrito em 09/11/2026.
- **386 feita em 09/11/2026** (`docs/plano_fase386.md`); os presos ao longo do tempo passaram para a 387.
