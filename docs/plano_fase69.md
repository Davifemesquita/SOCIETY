# Plano da Fase 69 — Expedições

**Estado: feita em 28/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima"; as expedições do Anno,
simplificadas: uma viagem sorteada, sem a tela de escolhas). Mexe na simulação (comando, sistema e estado novo no
save); só acontece se o jogador manda um navio, então os testes antigos, o robô e as assinaturas não mudam.

## O que entrou

- **Destinos** (`ExpeditionDef`, `data/expeditions/`): costa das savanas (traz um animal), ruínas antigas (traz uma
  peça de museu), ilhas das especiarias (9.000 moedas) e mares do norte (16.000 moedas, depois do segundo marco), de 8
  a 15 minutos, por 2.500 a 4.000 moedas, com 20–30% de chance de voltar de mãos vazias e 5–15% de naufrágio.
- **Comando** `StartExpeditionCommand`: o navio da companhia parado num porto do jogador, fora de rota, sai pelo custo
  do destino; fica guardado no `ExpeditionsState` (fora de `ships`: nenhum sistema de navio precisa saber dele).
- **Volta** (`ExpeditionSystem`, conferido a cada `events_check_ticks`, com ou sem os eventos ligados): no fim do prazo, o sorteio pela semente e pelo
  número da expedição dá naufrágio (o navio se perde), mãos vazias ou a recompensa — um animal ou uma peça ainda não
  comprados (vão guardados, para expor de graça no zoológico ou no museu da Fase 67; sem nenhum sobrando, o dobro do
  custo) ou as moedas. O navio volta parado ao porto de onde saiu.
- **Save**: as viagens (com o navio inteiro) e o número da próxima; o save antigo carrega sem expedição; navio em
  viagem que também esteja no mapa, de outro dono ou com id não dado recusa o save.
- **Tela**: no painel do navio parado num porto da companhia, "Mandar em expedição" com um botão por destino (custo,
  duração, chances e recompensa na dica; desligado com o motivo); na janela das encomendas (J), cada viagem com o
  tempo da volta; a volta vira aviso da frota (verde com a recompensa, vermelho no naufrágio) que abre a janela.

## Números

- Benchmark (alto, RTX 5060): neutro — tick médio 1,32 ms, construir 15,0 ms, desenho igual (o benchmark não manda
  expedição; `docs/benchmark.md`).

## Como testar

- `tests/sim/test_phase69_expeditions.gd`: dados e textos; o navio sai, paga e volta ao porto de origem (ou se perde);
  o sorteio dá os três resultados e paga a recompensa (o animal guardado ou o dobro do custo), igual pela semente; as
  recusas (bloqueado, sem dinheiro, navegando, navio que não existe); o save e a continuação iguais, e o antigo.
- `tests/ui/test_phase69_expedition_panel.gd`: os botões do painel do navio, mandar pelo botão, a viagem na janela, o
  aviso da volta.

## Fica de fora (proposta à espera do dono)

- As escolhas no meio da viagem (o texto com decisões do Anno), levar bens ou especialistas para melhorar a chance e o
  navio de volta danificado. Os números são provisórios.
