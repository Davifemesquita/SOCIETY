# Plano da Fase 58 — Coqueiro gerado no código

**Estado: feita em 27/10/2026, a pedido do dono** ("pode seguir para a próxima fase"; das propostas que ficaram de
fora das Fases 56 e 57, "palmeiras e mata tropical nas ilhas do sul"). Só apresentação: a simulação, o terreno e as
assinaturas não mudam; nada vai no save.

## O que faltava

As ilhas tropicais (Fase 11) desenhavam as três palmeiras do Kenney Nature Kit, recoloridas, sem malha de longe: as
únicas árvores do jogo ainda de pacote, no estilo de desenho animado, ao lado da mata temperada gerada no código
(Fase 22) e das rochas geradas (Fases 56 e 57).

## O que entrou

- **`TreeModel.Species.COCONUT_PALM`** (`presentation/tree_model.gd`): coqueiro de ~8 m (sorteio de 0,9 a 1,15), tronco
  curvo para um lado em sete gomos com o anel escuro da junta e o pé alargado; coroa de dez folhas compridas (3,4 a 4,2
  m) que sobem e caem — as de cima mais em pé, as de baixo caídas e mais amarelas —, com os folíolos em serra (a largura
  alternando), dobradas em V; cacho de quatro cocos sob a coroa. Malha de longe com três gomos, seis folhas de quatro
  passos e sem cocos. Mesma superfície com cor no vértice e o material da folhagem (balança ao vento).
- **`TreeView`**: as palmeiras são três variantes do coqueiro, com a camada de longe como as outras árvores
  (`NEAR_UNTIL_M`, histerese).
- Conserto achado no benchmark: `instance_count` e `palm_count` separavam a camada de longe pelo nome ("…Far"), mas as
  camadas de todos os trechos ficam no mesmo nó e o Godot renomeia as repetidas ("@Trees0Far@123"): parte das de longe
  contava como de perto (com as palmeiras ganhando camada de longe, as "árvores desenhadas" do benchmark pularam de
  47010 para 55219). Agora a camada de longe é a que começa longe (`visibility_range_begin`).
- A pasta `assets/models/nature/` (as palmeiras e a licença do Kenney Nature Kit) saiu; o `CREDITS.md` guarda a linha
  como histórico.
- Fica de fora: a mata tropical de folhosas (a ilha tropical continua só de coqueiros).

## Números

- Benchmark (alto, RTX 5060): draw calls iguais às da Fase 57 (1107 a 1109), GPU média 11,5 e 10,7 ms em duas rodadas;
  o FPS oscilou com a máquina (78,8 e 40,6 com a mesma GPU). A semente 1840 tem 944 coqueiros; ~560 triângulos de perto
  e ~120 de longe cada.

## Como testar

- `tests/presentation/test_phase58_palms.gd`: o coqueiro de pé no chão, de 7 a 10,5 m, copa de mais de 5 m, dentro do
  orçamento, sem folha na metade de baixo, malha de longe com menos de um terço dos triângulos e da mesma altura, no
  material da folhagem; as variantes diferem; numa ilha tropical da semente 1840, as camadas de perto e de longe com as
  malhas do `TreeModel` e as mesmas instâncias.
- `tests/world/test_terrain_water_trees.gd` (só a ilha tropical tem palmeiras) continua valendo.
- Capturas: `tools/capture_phase58.tscn -- <pasta>` (coqueiros de perto, de meia distância e de longe; em
  `F:\ferramentas\capturas\fase58`).

## Fica de fora (proposta à espera do dono)

- Mata tropical de folhosas misturada aos coqueiros; tornar o rochedo não construível; afinar a malha da falésia.
