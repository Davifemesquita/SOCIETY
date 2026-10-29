# Plano da Fase 83 — Moradores na festa

**Estado: feita em 28/10/2026, a pedido do dono** ("continue o projeto"; proposta deixada de fora na Fase 82: "os
moradores também irem ver os fogos"). Só visual: a simulação, o save e as assinaturas não mudam.

## O que entrou

- **Os moradores também vão ver os fogos** (`Crowd._resident_festival`): na hora dos fogos (`Crowd.fireworks_now`, a
  mesma noite em que a `FestivalView` os solta), `RESIDENT_WATCH_SHARE` (60%) dos moradores que saem de casa vão direto a
  uma das praças da festa que a casa alcança pela estrada (`_festival_squares`, agora pela casa também); o serviço de quem
  sai do trabalho vira a festa na mesma parte. Lá ficam em volta do mastro como os turistas da Fase 82 (`_watch_spot`).
- **A festa enche a rua** (`FESTIVAL_NIGHT_ACTIVITY`, `_count_festival_agents`): à noite só ~18% dos pedestres saem
  (`pedestrian_activity_by_hour`), e a primeira captura mostrou a festa vazia — 4 de 24 na rua, todos ocupados com outra
  coisa. Na hora dos fogos, os pedestres das ilhas da festa (moradores e turistas, contados a cada rebalanceamento) contam
  com pelo menos 50% na rua. De dia a hora já põe mais que isso, e nada muda.
- **Sair do lugar** (`Agent.watching`): quem está num lugar de ver a festa anda primeiro dele até a porta da praça. Na Fase
  82 isso dependia de ser turista e da distância; agora é a marca do lugar, a mesma para os dois.

## Números

- Constantes de apresentação (`RESIDENT_WATCH_SHARE`, `FESTIVAL_NIGHT_ACTIVITY`), não de jogo.
- A cota extra da festa é somada à da multidão inteira: com festa numa ilha e outra sem, quem sai da fila de casa pode ser
  da ilha sem festa. Com uma festa por vez na ilha principal (o caso comum) não aparece.
- Benchmark: o mundo do benchmark não tem festa; neutra (`docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase83_fireworks_residents.gd`: à noite na festa os moradores parados na praça estão em volta
  do mastro, de frente para ele; ao sair, andam do lugar; a festa põe mais gente na rua de noite (e não muda o dia); sem
  festa, nenhum morador vai à praça.
- Capturas: `tools/capture_phase83.tscn -- <pasta>` (o bairro da Fase 82 com as casas cheias, a hora presa às 22 h até
  haver moradores em volta do mastro; o resumo vai em `<pasta>/fase83.txt`; em `F:\ferramentas\capturas\fase83`: 75
  pedestres, 35 na rua, 6 moradores vendo a festa depois de 9 s). A captura da Fase 82 deixa a hora andar enquanto espera
  e, nesta máquina, já tinha passado da noite quando fotografou; a da 83 prende a hora.

## Fica de fora (proposta à espera do dono)

- Os pedestres olharem para o céu (o boneco só gira em volta do eixo vertical) e baterem palmas a cada estouro.
- A cota extra só para os pedestres da ilha da festa (hoje é somada à da multidão inteira).
