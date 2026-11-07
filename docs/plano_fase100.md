# Plano da Fase 100 — Fumaça das casas

**Estado: feita em 29/10/2026**, primeira do roteiro `docs/plano_fases_100_104.md` (a rua habitada, olhando o Anno do dono:
só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **A boca da chaminé** (`BuildingKit.chimney_top`, `_chimney_place`): a mesma conta que põe a chaminé do kit no telhado da
  casa dá o meio do alto dela, no referencial do prédio; `ChimneySmokeView.chimney_world` a leva ao mundo com o mesmo
  assento e giro do modelo (como as janelas acesas).
- **As baforadas** (`ChimneySmokeView`, `shaders/chimney_smoke.gdshader`): `PUFFS` por chaminé, desencontradas no ciclo,
  todas num MultiMesh só com a caixa do arquipélago (`WorldBounds`). O shader as faz subir (mais devagar no fim), crescer,
  deitar com o vento do clima (`wind_direction`, `wind_strength`, Fase 22) e sumir, no tempo visual (para na pausa), de
  frente para a câmera e esmaecendo com a distância (`fade_begin_m`, `fade_end_m`, pelo alcance do nível gráfico).
- **Quando sai fumaça**: só de casa com morador (conferido a cada `REFRESH_SECONDS`, mexendo só no dado da instância); a
  quantidade segue a hora (`amount_at`: o fundo do dia `BASE_AMOUNT` e os picos do fogão às 7h e às 19h, lisos); de noite a
  fumaça escurece (`NIGHT_BRIGHTNESS`, sem luz própria). No nível baixo (sem partículas), nada.
- A vista se refaz no quadro seguinte a uma obra, demolição ou casa que sobe de classe, e entra no aquecimento atrás da
  cortina (`WarmUp`, Fase 32).

## Como testar

- `tests/presentation/test_phase100_chimney_smoke.gd`: a boca fica acima do beiral, dentro da planta; casa sem chaminé não
  tem boca; só casas com chaminé entram e só a com morador fumega; a vista acompanha a obra e a demolição; a quantidade
  tem os picos da manhã e da noite e não dá degrau em hora nenhuma.
- Captura: `tools/capture_phase95.tscn` põe morador nas casas e tira `fumaca_manha.png` às 7h30.
