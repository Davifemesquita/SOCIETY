# Plano da Fase 342 — Cor de cultura

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_340_344.md` (campos em faixa). De longe, o trigo dourado, a
batata verde-escura e o lúpulo alto se confundiam: as coberturas das leiras (Fase 262) eram seis verdes quase iguais.

## O que entrou

- **`CropView.CROP_COVER`** espalhado pelo brilho e pelo matiz, sempre verde (o verde acima do vermelho e do dobro do azul, a regra da
  Fase 262): a batata (0,2; 0,4; 0,14) verde-escuro fundo, o lúpulo (0,48; 0,62; 0,2) verde-amarelado vivo, a uva (0,36; 0,44; 0,2) oliva
  fosca, a cana (0,52; 0,72; 0,26) lima clara, o café (0,13; 0,29; 0,13) verde-escuro e o tabaco (0,64; 0,67; 0,3) verde-palha.
- O par mais parecido (com o dourado do trigo) fica a mais de 0,08 (era 0,05), e o mais claro tem mais que o dobro do brilho do mais
  escuro.

## Medida

Só cor: sem custo de quadro.

## Como testar

- `tests/world/test_phase342_crop_colours.gd`: as coberturas distintas entre si e do trigo, com o brilho espalhado; o teste da Fase 262
  (com tela) confere que todas seguem verdes.
- Captura: as do fim do roteiro (`docs/plano_fase344.md`).
