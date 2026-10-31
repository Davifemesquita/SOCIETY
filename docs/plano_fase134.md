# Plano da Fase 134 — Ardósia nos prédios de pedra

**Estado: feita em 31/10/2026**, a última do roteiro `docs/plano_fases_130_134.md` (sapê, bueiro e ardósia, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingView.SLATE_ROOFS`): a igreja, a escola, o mercado, a prefeitura, o teatro, a universidade e o museu. A
  `BuildingView` põe o parâmetro de instância `slate` no corpo deles.
- **A ardósia** (`shaders/building_kit.gdshader`, `slate_shade`): nas águas do telhado (e na abóbada do mercado), no lugar
  das telhas da Fase 95, placas retangulares de `slate_width_m` em fiadas de `slate_row_m` desencontradas, a sombra sob a
  borda reta, a junta fina e um tom cinza-azulado por placa (algumas mais azuladas), mais lisa e um pouco brilhante; de
  longe só o tom. A capa da cumeeira, o beiral redondo e o telhado plano ficam na cor da ardósia, lisos.

## No caminho

- As bancas do pátio do mercado são peças do kit que usam a célula do telhado: ficaram de ardósia também. Fica como está
  (cinza, como lona velha), e a cor própria das bancas pode entrar num roteiro seguinte.

## Como testar

- `tests/presentation/test_phase134_slate.gd`: a lista é de serviços (nenhuma produção nem casa); com tela, o shader do kit
  compila com os parâmetros novos.
- Captura: a rua dos prédios grandes do `tools/capture_phase95.tscn` (`grandes_a.png`, `grandes_b.png`,
  `mercado_de_lado.png`).
