# Plano da Fase 234 — Fogareiro de castanhas

**Estado: feita em 01/11/2026**, a última do roteiro `docs/plano_fases_230_234.md` (sinal, cormorão e castanha, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ChestnutRoasterView.cells`): no canto de dentro das esquinas calçadas, pela mesma busca das colunas de anúncios da Fase
  150 (`AdColumnView._paved`, `_free`, `_taken`), nas esquinas do resto `ROASTER_REST` de `ROASTER_EVERY` — ímpar, então nunca a
  célula de uma coluna, que fica no resto 0 de 2 —, fora das células dos outros enfeites; o carrinho de frente para a esquina, um
  pouco para o canto dela. O recheio deixa as células limpas.
- **O carrinho** (`roaster_mesh`, `ember_mesh`): as duas rodas de raios de ferro e o eixo, a caixa de tábuas com os varais para trás e
  o pé, o fogareiro redondo de ferro com a tampa larga e as castanhas, a chaminezinha, o saco e o cesto; as brasas na boca do
  fogareiro no material dos lampiões (`shaders/night_glow.gdshader`, como vidro: escuras de dia, acesas à noite — a chama encolhe
  para o pé da malha, que aqui é o chão). Dois MultiMesh.

## Como testar

- `tests/world/test_phase234_chestnut_roasters.gd`: numa rua calçada com várias ruas de través, os fogareiros ficam no canto de
  dentro das esquinas, do resto certo, longe das colunas, em células livres; rua de terra não tem; o carrinho cabe na célula.
- Captura: `tools/capture_phase234.tscn` (as esquinas calçadas na ilha plana; `fogareiro_de_perto.png`,
  `fogareiro_na_esquina.png`, `fogareiro_de_noite.png`).
