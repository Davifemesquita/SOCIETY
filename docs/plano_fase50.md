# Plano da Fase 50 — Kit de época

**Estado: caminho pronto em 26/10/2026, à espera da arte do dono.** Décima nona e última fase do roteiro de
`docs/plano_melhorias.md`. A troca das caixas de fantasia por arquitetura do século XIX depende de peças que **o dono
modela, gera ou compra** (o plano previa até uma subfase por classe); sem nenhuma peça no repositório, esta fase
entregou tudo o que não é arte: as regras de importação com teste, a validação no CI, o gancho que põe a peça no lugar
da forma procedural sem quebrar a montagem por célula, e a lista do que falta. Nada apareceu na tela do dono.

## 1. Regras de importação (`tools/import/asset_rules.gd`, `AssetRules`)

- **Orçamento de triângulos** do LOD0 por categoria (objeto até 1.000, casa 3–8 mil, fábrica 8–20 mil, navio 4–8 mil):
  o teto é erro; abaixo do piso, aviso.
- **Uma malha só** (a BuildingView usa uma por prédio); **frente** marcada por um nó `Front` em −Z (a rotação 0 do jogo
  olha para −Z); **pivô** no centro do lote e no chão; **tamanho** dentro do lote (2 m por célula, com folga de 0,3 m);
  **LOD** ligado na importação (`meshes/generate_lods` no `.import`); **nome** começando pelo id do prédio
  (`<prédio>_<classe>` nas casas); **crédito**: o arquivo ou a pasta dele no `CREDITS.md`.
- `scan(pasta)` confere tudo de uma pasta; `def_for` acha o prédio pelo nome.

## 2. Validação (`tools/import/validate_assets.tscn`)

- Uma cena (não `--script`: o jogo inteiro carrega) que confere `res://assets/kit/` e sai com código 1 se alguma peça
  tiver problema. Entrou no CI, no job "Compilar os scripts" ("Conferir o kit de época"). Hoje: 0 arquivos.

## 3. O gancho no `BuildingKit`

- `BuildingKit.kit_root` (`res://assets/kit`), `asset_path(prédio, classe)` (a peça da classe antes da geral, `.glb` ou
  `.tscn`), `asset_mesh(caminho)` e `Spec.asset`: com peça, `BuildingKit.mesh(spec)` devolve a malha dela, e a
  BuildingView, a prévia e as plantas a põem no mesmo lote, piso e rotação. Sem peça, a forma procedural de sempre (o
  benchmark não mudou: montar 9,5 s, carregar 2,46 s, obra 17,9 ms).
- A peça usa o material do kit (o atlas por UV): ela tem de vir com a UV na trim sheet do material — a regra que o plano
  previa ("material por UV nas peças com trim").

## 4. O que falta (com o dono)

- As peças: `assets/TODO_ASSETS.md` ganhou a seção "Kit de época (Fase 50)" com cada arquivo esperado, o orçamento, a
  fonte pensada (Medieval Village MegaKit da Quaternius, CC0, para camponeses e operários; kit próprio no Blender para o
  resto) e o prompt de referência.
- Comprar os níveis Pro ou Source da Quaternius, se quiser; modelar ou gerar as peças; aprovar a retirada do Hunyuan3D
  da especificação; revisar a divulgação de IA (Steam) se alguma peça vier de IA.
- Nenhum arquivo pago entra no repositório público; cada peça no `CREDITS.md` (a validação cobra).

## Fica de fora

- A arte em si; pedestres e retratos (fases próprias depois, como o plano diz); texture streaming (Fase 48, quando a 4.8
  estável sair e houver texturas de fachada).

## Como testar

- `tests/tools/test_phase50_asset_rules.gd`, com peças sintéticas feitas no teste: a casa boa passa; cada regra acusa o
  seu problema (teto, piso como aviso, duas malhas, sem frente, frente em +Z, maior que o lote, sem LOD, nome, crédito);
  categorias e nomes; a varredura de uma pasta e o gancho (a padaria usa a peça de 10 mil triângulos, a casa sem peça
  segue procedural); a pasta do kit do repositório limpa.

## Pronto quando

Cada classe tem kit próprio que encaixa na grade; nenhum arquivo sem crédito; o alto segue na meta na 3060. **Proposta à
espera do dono**: a arte (e as compras e aprovações acima).
