# Plano da Fase 290 — Estratos na rocha

**Estado: feita em 02/11/2026**, a primeira do roteiro `docs/plano_fases_290_294.md` (a rocha e a costa no jeito do Anno). As
encostas e as falésias eram a textura de rocha cinza da Fase 261, sem estrutura. No Anno, a rocha tem camadas e sulcos descendo.

## O que entrou

- **`shaders/rock_strata.gdshaderinc`**, dividido pelo `terrain.gdshader` e pelo `sea_rock.gdshader`: `strata_factor`, um fator de
  cor pela altura e pelo lugar no mundo, só na face inclinada (de 1 na plana a cheio com a normal abaixo de 0,55).
  - **Camadas** de `strata_m` (1,15 m), onduladas pelo ruído (`strata_warp_m`, não fatias retas). A borda de cima de cada uma fica
    mais clara (`strata_light`, o ressalto que pega luz) e a faixa logo embaixo, na sombra (`strata_shade`).
  - **Sulcos** descendo pela encosta (`gully_strength`): o ruído esticado ao longo da descida.
  - Pelo mundo e não pelo modelo: a rocha do terreno, as falésias, os rochedos e as pedras soltas batem nas mesmas camadas.
- **No terreno** o fator só roda onde há rocha.
- **Os parâmetros da função** se chamam `at` e `normal_w`. Com `world_position`, o nome dos varyings dos dois shaders, ela não
  compilava ("Redefinition of 'world_position'").
  - O teste da fase só via a lista de uniformes vazia e passava como se estivesse sem tela; a captura mostrou o terreno branco.
  - Agora o teste exige a lista cheia quando há tela.
- **A primeira medida** (borda 0,22, sombra 0,3) quase não aparecia nas capturas.

## Medida

O benchmark deu a GPU em 12,5 ms em três rodadas. A Fase 289, medida na mesma hora numa cópia no commit anterior
(`F:\repos\society_ref`), deu 12,4 ms: os estratos custam ~0,1 ms. O resto foi a máquina mais lenta nessa hora (o FPS desceu ao
longo da sessão).

## Como testar

- `tests/world/test_phase290_strata.gd`:
  - os dois shaders incluem os estratos e os aplicam depois da cor cinza da rocha (no terreno, só onde há rocha);
  - só na face inclinada, com os números suaves;
  - os dois shaders compilando com os uniformes novos. Com tela, a lista vazia falha: é o shader que não compilou.
- Captura: `tools/capture_phase290.tscn -- <pasta>`, a captura do ciclo da rocha e da costa. Mostra a falésia de perto e de meia
  distância, o barranco aberto, a costa de pedra de frente e de lado e a encosta íngreme perto da vila.
