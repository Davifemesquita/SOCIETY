# Plano da Fase 98 — Abóbadas e tonéis

**Estado: feita em 29/10/2026**, quarta do roteiro `docs/plano_fases_95_99.md` (formas mais redondas, olhando o Anno do
dono: só a ideia). Só apresentação: nada muda na simulação nem no save (a silhueta nova é um número nos `.tres`).

## O que entrou

- **Abóbada** (`BuildingKit.Spec.vault`, `VAULTED`, `vault_profile`, `_vault`): o mercado, a tecelagem, a fábrica de
  máquinas de costura, as conservas, a saboaria, a janelaria e a torrefação trocam as duas águas por um arco abatido sobre
  o lado curto, que passa pelo beiral dos dois lados e sobe `VAULT_RISE` da altura do telhado de antes. As faixas
  (`VAULT_SEGMENTS`) levam a normal do arco (`_smooth_quad`), e a abóbada sai lisa; as telhas do shader (Fase 95) seguem a
  curva. Empena em arco nas duas pontas, borda grossa e beiral redondo.
- **Tonéis no pátio** (`BuildingDef.Silhouette.VATS`, no fim do enum, na cervejaria, nas duas destilarias e na adega;
  `vat_layout`, `_vats`): a fileira da frente vira pátio (`court_rows = 1`) com até `VATS_PER_SIDE` tonéis de cada lado do
  caminho da porta — aduelas com o bojo (`VAT_BULGE`, sólido de revolução), três arcos de ferro, a tampa e um cano de cobre
  até a parede do corpo.
- **Chaminé redonda** (`SmokeView.stack_mesh`): o fuste de tijolo afina de `STACK_SIDE_M` até `STACK_TAPER` dele na boca e
  ganha o colar em volta da boca; uma malha só para todas.

## No caminho

- Erro de tipo num arquivo de teste com a janela aberta deixa o Godot parado (sem saída e sem log) até o tempo acabar; sem
  janela (`testes_society.ps1`) o erro aparece em segundos.
- A pasta `world`, que não tinha rodado nas Fases 96 e 97, pegou duas sobras da ala: o telhado do corpo ficava 4 cm curto
  do beiral no lado de +X (`Spec.main_offset` passou a usar a diferença das larguras, não a de uma coluna) e o teste das
  casas variadas da Fase 39 contava as formas sem a ala (o limite dobrou).
- O teste "só os serviços de cúpula têm cobre" (Fase 97) usava a cervejaria, que agora tem o cano de cobre dos tonéis:
  trocada pela padaria.

## Como testar

- `tests/presentation/test_phase98_vaults_vats.gd`: só os de `VAULTED` têm abóbada; o arco desce sem degrau, simétrico, do
  alto (`VAULT_RISE` do telhado) ao beiral e nada passa dele; os tonéis ficam na fileira da frente, dentro do lote e longe do
  caminho da porta nas quatro rotações; os outros prédios não têm tonéis; a chaminé é um círculo da largura de antes.
- Captura: `tools/capture_phase95.tscn` ganhou a tecelagem e a destilaria na rua dos prédios grandes e as tomadas
  `mercado_de_lado.png` e `fabricas_de_perto.png`.
