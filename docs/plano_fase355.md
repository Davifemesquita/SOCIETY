# Plano da Fase 355 — Marinho

**Estado: feita em 07/11/2026**, a primeira do roteiro `docs/plano_fases_355_359.md` (mar aberto). O mar aberto do Anno visto de cima é
azul-petróleo escuro, ~(35, 55, 66) na tela (`c10_03`); o nosso ficava em (46, 74, 97), uns 40% mais claro e mais azul.

## O laboratório

`CAPTURA_AGUA` no `tools/capture_phase330.tscn` (agora com cores de quatro números e o horizonte), na vila de longe e no horizonte:

| variante | mar de cima | horizonte |
|---|---|---|
| como estava | 46, 74, 97 | 93, 153, 199 |
| `cold_deep` (0,03; 0,13; 0,2) | 47, 69, 84 | 92, 153, 198 |
| e `far_sea_dark` 0,32 | 47, 68, 83 | 92, 152, 198 |
| e `specular` 0,35 | 49, 69, 84 | 98, 155, 199 |

O que pesa é a cor do fundo; o escurecido de longe e o reflexo quase não mudam. O horizonte é o reflexo do céu no ângulo raso e fica.

## O que entrou

- **`cold_deep`** (o fundo do mar das temperadas, Fase 280) em (0,03; 0,12; 0,18), era (0,04; 0,18; 0,29): mais escuro e menos azul, ainda
  com o azul acima do verde. As tropicais seguem turquesa.

## Medida

Só cor: sem custo de quadro.

## Como testar

- `tests/world/test_phase355_navy_sea.gd`: o fundo mais escuro que o de antes, azul-petróleo. O da Fase 280 (com tela).
- Captura: o laboratório em `F:\ferramentas\capturas\fase355\lab\`; as do fim do roteiro (`docs/plano_fase359.md`).
