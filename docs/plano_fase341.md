# Plano da Fase 341 — Cabeceira de capim

**Estado: feita em 07/11/2026**, a segunda do roteiro `docs/plano_fases_340_344.md` (campos em faixa). Entre os campos do Anno corre uma
faixa de capim ou de terra batida; os nossos quase encostavam um no outro.

## O plano

- **Arquivos**: `presentation/crop_view.gd` (o recuo do contorno, a margem das plantas e a cabeceira), o teste novo, o de `test_crops`
  (o comprimento da leira), `AGENTS.md` e o roteiro.
- **Risco**: plantas e leiras saindo da terra para o capim; menos fileiras no campo.
- **Como testar**: o teste novo, os dos campos (Fases 40, 157, 175, 249, 262 e 270) e a captura.

## O que entrou

- **O recuo da terra lavrada** (`FIELD_INSET_M`) 0,38 m (era 0,22), com a onda de 0,36 m de antes: a faixa de capim entre dois campos
  vizinhos fica de 0,76 a 1,48 m (era de 0,44 a 1,16 m).
- **As plantas dentro da terra**: a margem delas (`MARGIN_M`) 0,8 m (era 0,65) e a cabeceira das pontas (`HEADLAND_M`) 1,1 m (era 0,95),
  as duas além do recuo máximo do contorno. A leira tem 3,8 m num campo de 6 m (era 4,1).

## Medida

Só posições: sem custo de quadro.

## Como testar

- `tests/world/test_phase341_headland.gd`: a faixa de capim mais larga e as plantas dentro da terra.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase340\depois\`, depois em
  `F:\ferramentas\capturas\fase341\depois\`.
