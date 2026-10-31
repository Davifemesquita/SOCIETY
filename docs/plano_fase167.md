# Plano da Fase 167 — Capim alto nos terrenos vazios

**Estado: feita em 31/10/2026**, terceira do roteiro `docs/plano_fases_165_169.md` (chão batido, feno e gaivota, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`ScatterView.tall_grass_patch`): manchas pelo mesmo ruído de valor das papoulas da Fase 156, com outro passo
  (`TALL_GRASS_PATCH_CELLS`), outra semente e outro limite (`TALL_GRASS_THRESHOLD`), e os nós da última célula guardados à parte.
- **Peça** (`ScatterView.Kind.TALL_GRASS`, no fim do enum e no fim da lista `OPEN`): na célula da mancha, `TALL_GRASS_CHANCE`, só
  nas ilhas temperadas e fora dos canteiros de papoulas, quase no meio da célula.
- **A touceira** (`tall_grass_mesh`): `TALL_GRASS_BLADES` folhas finas e altas num disco de `TALL_GRASS_RADIUS_M`, cada uma um
  triângulo comprido verde no pé e cor de palha na ponta, inclinada para fora, e uma espiga em cada terceira; o material das
  plantas (balança com o vento).

## Como testar

- `tests/world/test_phase167_tall_grass.gd`: a peça entrou no fim do campo aberto; as manchas são juntas, cobrem de 3 a 30% e
  quase não coincidem com as papoulas; o capim só aparece nas manchas das temperadas, fora dos canteiros; a touceira é leve,
  alta e cabe na célula.
- Captura: `tools/capture_phase167.tscn` (o trecho da ilha principal com mais capim alto, de perto, a meia distância e de longe).
