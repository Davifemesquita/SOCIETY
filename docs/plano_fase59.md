# Plano da Fase 59 — Mata tropical

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir"; era a proposta que ficou de fora da Fase 58: a mata
tropical de folhosas misturada aos coqueiros). Só apresentação: a simulação (as árvores por célula, o lenhador), o
terreno e as assinaturas não mudam; nada vai no save.

## O que faltava

Depois da Fase 58 a ilha tropical era um coqueiral só, do pé da praia ao alto do morro: nada de mata fechada.

## O que entrou

- **`TreeModel.Species.TROPICAL_BROADLEAF`** (`presentation/tree_model.gd`): tronco reto, claro e liso até 5,6 a 6,6 m,
  quatro sapopemas (raízes em aleta) no pé, quatro galhos quase deitados com uma massa de folhagem achatada na ponta
  e a do meio: copa em guarda-chuva, mais larga que alta, de verde mais escuro que a mata temperada. Duas variantes;
  malha de longe sem galhos nem sapopemas.
- **`TreeView`**: nas ilhas tropicais, cada árvore da célula sorteia entre coqueiro e folhosa tropical pela altura do
  terreno: abaixo de 3 m (`PALM_HEIGHT_M`, a terra baixa da costa), 80% coqueiro; acima, 30%. As camadas da folhosa se
  chamam `Tropical<n>` e há `tropical_count`, ao lado do `palm_count`.
- Na semente 1840: 360 coqueiros e 584 folhosas nas ilhas tropicais (eram 944 coqueiros); 80% de coqueiros na terra
  baixa e 32% no alto.

## Números

- Benchmark (alto, RTX 5060): mesmas 28837 árvores e 1109 draw calls, GPU média 10,7 ms como na Fase 58 (o FPS
  oscilou com a máquina; ver `docs/benchmark.md`). Até duas camadas a mais por trecho tropical.

## Como testar

- `tests/presentation/test_phase59_tropical_forest.gd`: a folhosa tropical de pé no chão, de 7,5 a 11,5 m, mais larga
  que 0,6 da altura, sem folha na metade de baixo, no orçamento, com malha de longe; as variantes diferem; na semente
  1840, coqueiros e folhosas nas ilhas tropicais e nenhum nas temperadas, com a parte de coqueiros na terra baixa maior
  que no alto.
- Capturas: `tools/capture_phase58.tscn -- <pasta>` mostra a mistura (em `F:\ferramentas\capturas\fase59`).

## Fica de fora (proposta à espera do dono)

- Sub-bosque tropical (bananeira, samambaia) e flores na mata; tornar o rochedo não construível; afinar a malha da
  falésia.
