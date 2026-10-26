# Plano da Fase 41 — Mata e recheio

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam. Décima fase
do roteiro de `docs/plano_melhorias.md`. Só apresentação: nada no save, nada na simulação. Nada aparece na tela do dono
(testes sem janela; benchmark e capturas na área de trabalho escondida). A densidade é **proposta à espera do dono**.

O roteiro sugeria dividir em 41a (árvores) e 41b (recheio): as duas partes foram juntas, cada uma no tamanho que cabe sem
arte nova.

## 1. Árvores (`presentation/tree_model.gd`, `tree_view.gd`, `shaders/foliage.gdshader`)

- **Copa fofa**: a normal de cada vértice da folhagem puxa para a da copa inteira (`CROWN_ROUND`: a esfera em volta do
  meio dela) — a copa vira um volume de luz macia em vez de um monte de bolas facetadas — e tufos pequenos (o icosaedro
  sem subdividir) entre as massas quebram a silhueta (carvalho 4, faia 3, pinheiro 4; só no nível de perto, sem mudar o
  sorteio do de longe).
- **Luz de trás** nas folhas (`BACKLIGHT` no shader da folhagem, só onde a cor puxa para o verde: a madeira não ganha).
- **Histerese** na troca de perto para longe (`LOD_MARGIN_M`, 24 m nas margens do alcance): a câmera parada na divisa
  não fica piscando.

## 2. Recheio (`presentation/scatter_view.gd`, `ScatterView`)

- Em cada célula de terra livre (sem árvore, estrada, prédio nem porta), pelo que há em volta: arbustos, capim e flores
  na beira da mata; capim, flores, pedrinhas e um arbusto ou outro na beira da estrada; capim de duna no litoral; e,
  encostados na parede do prédio vizinho, arbustos, flores, barris, lenha e caixotes (nas casas) ou caixotes e barris
  (nas fábricas, armazéns e serviços). No gramado aberto, capim alto, flores e arbustos esparsos.
- Determinístico pela célula, fora do save (salvar e carregar dá a mesma lista), em MultiMesh por trecho de 32 células e
  por peça, até 220 m (com margem); só as peças grandes fazem sombra. Refaz só os trechos atingidos por obra, demolição
  (pela diferença da ocupação), estrada (pela diferença das linhas) ou derrubada de árvores.
- Ao carregar segue o mundo novo da simulação; a vista que a `GameScreen` cria no mesmo quadro não refaz duas vezes.

## Fica de fora

- **Folha recortada** (alpha-scissor com textura CC0) e o **impostor assado** por SubViewport: pedem arte e um spike de
  GPU com as ~94 mil árvores (overdraw das folhas, atlas preto no addon de referência). Ficam para quando o dono escolher
  a textura de folha; o nível de longe atual continua.
- Mesh decals de poças e palha; grama densa em partículas; addons de scatter.

## Riscos

- Tempo de jogo novo e de carregar: o recheio do arquipélago inteiro custa ~0,45 s (era 0,75 antes de tirar as chamadas
  da grade do laço por célula).
- Densidade que atrapalhe a leitura dos pedestres: as peças miúdas são baixas e sem sombra.

## Como testar

- `tests/world/test_phase41_scatter.gd` (sem tela): normais da copa para fora do meio dela e histerese nas camadas; o
  recheio é determinístico e nunca cai em prédio, estrada ou porta; a casa ganha coisas encostadas nela; uma obra refaz
  de 1 a 4 trechos; salvar e carregar dá a mesma lista; a vista não mexe na simulação; o tempo do arquipélago inteiro.
- `tests/presentation/test_tree_model.gd` (orçamento de triângulos e o nível de longe), sem tela.
- Benchmark na área de trabalho escondida, comparado com o da Fase 39; capturas do conjunto padrão no alto.

## Pronto quando

Não há gramado vazio entre as casas; a mata lê como volume; o preset alto segue na meta na 3060; o dono aprova a
densidade e escolhe a textura de folha (para a parte que ficou de fora).
