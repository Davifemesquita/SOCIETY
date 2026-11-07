# Roteiro das Fases 115 a 119 — Fazenda, taverna e estaleiro

**30/10/2026.** O dono pediu para abrir o Anno de novo e idealizar as próximas fases. As ideias saem de capturas novas do
Anno 1800 dele (`F:\ferramentas\capturas\anno\f115_*.png`, fora do repositório): o porto com o estaleiro (`f115_06`), a
vila de criação de ovelhas (`f115_14`), o pasto e o rio (`f115_13`), a praça da taverna de dia e de noite (`f115_17`,
`f115_18`) e a serra (`f115_10`, `f115_11`). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida do
jogo; tudo gerado no código.

## O que o Anno mostra e o Society não tem

O estaleiro tem a carreira de madeira descendo para a água, com o casco em obra; a praça da taverna tem mesas e guarda-sóis
coloridos com gente sentada; os galpões das fazendas de criação têm silos e caixas d'água redondos ao lado; o pasto tem o
chão gasto em manchas onde os bichos pisam, e um cocho; à noite, cada poste deixa uma poça de luz quente na rua, e não só a
lanterna acesa.

## As fases

| Fase | O quê |
|---|---|
| 115 — Carreira do estaleiro | carreira de madeira do estaleiro até a água; com uma encomenda, o casco aparece nela e cresce com o progresso (quilha, cavername, costado), e some quando o navio sai pronto |
| 116 — Mesas da taverna | mesas, bancos e guarda-sóis listrados nas células livres em volta da taverna (como o largo calçado da Fase 109), recolhidos à noite |
| 117 — Silos das fazendas | silo redondo de tábuas com teto cônico ou caixa d'água sobre pés ao lado das fazendas de trigo, batata, lúpulo, ovelha e porco, pela variação do prédio |
| 118 — Chão gasto no pasto | manchas de terra batida no pasto com dono (mais perto da porteira e do cocho) e um cocho de madeira por pasto, pela máscara das estradas e o recheio |
| 119 — Poças de luz à noite | um disco de luz quente no chão sob cada poste e na porta das casas acesas, aditivo, só à noite; barato (sem luz de verdade) |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Ficaram de fora (para outro roteiro)

- Rio com correnteza e corredeiras: os rios do Society são braços de mar no nível do mar, sem direção de fluxo; pede outra
  base na água.
- Cascalho de tálus no pé da serra: parecido demais com as pedras soltas das Fases 36 e 57.
- Píer de passeio com coretos entrando no mar: prédio novo (simulação e menu), não só apresentação.

## Estado

**Concluído em 30/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase115.md` a
`docs/plano_fase119.md`), testes, captura e benchmark. Diferenças do roteiro: as mesas da taverna (116) ficam até seis por
taverna, as mais perto da porta; os silos (117) alternam com a caixa d'água pelo resto do id da fazenda; o cocho (118)
fica em todo pasto, com ou sem bicho, como as trilhas da Fase 40.
