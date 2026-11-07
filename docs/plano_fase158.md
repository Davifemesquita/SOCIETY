# Plano da Fase 158 — Carroça de lona

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_155_159.md` (carneirinho, papoula e colheita, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quais** (`CartView.covers`): a carroça de um prédio a cada `COVER_EVERY` pelo id cujo bem vai em saco ou caixote
  (`COVERED_PILES`); toras, barris e montes seguem à mostra. A escolha é pelo bem da casa (guardada por casa, refeita ao trocar
  de mundo): a carroça não perde a lona na volta vazia.
- **A lona** (`canvas_mesh`): meia volta um pouco mais alta que larga (`CANVAS_RISE`) da tábua da frente à de trás da caçamba
  do modelo do kit (medida: de z −0,59 a 1,35, lados a ±0,63 m, borda a 0,54 m), três arcos de madeira saltando dela e o escuro
  de dentro um pouco para dentro de cada ponta; sem esconder a face de trás (pela ponta aberta se vê o lado de dentro). Um
  MultiMesh (`Covers`) com a mesma transformação da carroça; a carga da carroça coberta fica escondida debaixo da lona.

## No caminho

- A primeira lona deixava 0,2 m da traseira da caçamba de fora (a primeira medida do modelo, em faixas de 20 cm, errou a
  tábua de trás); medida de novo pelos triângulos, ela vai de ponta a ponta.
- O log de toda partida tinha um erro da Fase 137 (`set_normal` depois de vértices sem normal na `FurnaceGlowView.glow_mesh`):
  a normal já vinha do `generate_normals`, e a chamada saiu.

## Como testar

- `tests/presentation/test_phase158_covered_carts.gd` (com janela): só saco e caixote, metade das casas; a lona fica nos lados
  da caçamba e dentro do comprimento do modelo, nasce na borda e passa da carga; na rua, das duas moendas (ids seguidos) uma
  anda de lona e a farinha dela não aparece, e as toras do lenhador seguem à mostra.
- Captura: `tools/capture_phase158.tscn` (ilha plana, três moendas e um lenhador soltando as carroças, a câmera na carroça de
  lona mais adiantada).
