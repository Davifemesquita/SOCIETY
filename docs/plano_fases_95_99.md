# Roteiro das Fases 95 a 99 — Formas mais redondas

**29/10/2026.** O dono pediu para abrir o Anno 1800 de novo e trazer melhorias, com a ideia de "um formato mais
arredondado das coisas: casas, fábricas etc.". O Anno foi aberto no PC dele, no save dele (Ditchwater, ~7 mil
moradores), e só olhado: capturas em `F:\ferramentas\capturas\anno\f95_*.png`, fora do repositório. Como nas Fases 51 a
53, **só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código, como o resto do
`BuildingKit`.

## O que o Anno mostra e o Society não tem

| | Anno 1800 (o que se vê de perto) | Society hoje |
|---|---|---|
| Telhado | a maior parte do que se vê de cima: telhas em fileiras, cumeeira marcada, beiral com espessura | duas ou quatro águas lisas, com a textura PBR (Fase 9) |
| Volume da casa | quase sempre dois ou três volumes: corpo, ala mais baixa, anexo; telhados que se cruzam em L | um volume por lote (a Fase 39 varia o telhado, não a planta) |
| Curvas | cúpulas de cobre verde, torreões redondos de canto, fachada em arco (a rotunda), coretos redondos | nada curvo nos prédios (o coreto da Fase 16 é octogonal) |
| Fábricas e galpões | telhado de abóbada, tanques redondos no pátio, chaminé cilíndrica de tijolo | caixa com telhado de casa e a chaminé de caixa |
| Aberturas | arcos nas portas, janelas e no mercado coberto | o arco só na porta do armazém e dos serviços de pedra (peça do kit) |

## As fases

| Fase | O quê |
|---|---|
| 95 — Telhado de telhas | as águas do telhado ganham fileiras de telha (relevo no shader, sem triângulo a mais), a cumeeira ganha a peça de cumeeira e o beiral ganha espessura com a borda arredondada |
| 96 — Casa em mais de um volume | dos artesãos para cima, a casa ganha uma ala mais baixa num dos lados e, nas maiores, o telhado em L com a cumeeira cruzada; o lote e a porta não mudam |
| 97 — Cúpulas e torreões | cúpula de cobre verde (com lanternim) nos serviços grandes (teatro, universidade, prefeitura, museu) e torreão redondo de telhado cônico no canto das casas dos investidores |
| 98 — Abóbadas e tanques | telhado de abóbada nos galpões, no mercado e nas fábricas de nave longa; tanques cilíndricos no pátio das que trabalham com líquido (cervejaria, destilaria, adega); chaminé cilíndrica de tijolo no lugar da de caixa |
| 99 — Arcos | janelas e portas em arco nos serviços e nas casas dos investidores; arcada na frente do mercado |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura (`tools/capture_phaseNN.tscn`) e
benchmark, commit e push. As malhas novas ficam no cache do `BuildingKit` por forma; o benchmark confere objetos, draw
calls e a GPU a cada fase (um torreão ou uma cúpula a mais por prédio pode pesar com a cidade cheia).
