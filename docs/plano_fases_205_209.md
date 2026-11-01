# Roteiro das Fases 205 a 209 — Estandarte, bebedouro e lanterna

**01/11/2026.** Terceiro ciclo do quinto pedido "pode continuar" do dono. O Anno **não foi aberto** (o dono estava usando o
PC). As ideias saem das capturas guardadas (`F:\ferramentas\capturas\anno\`, fora do repositório): o prédio público com os
estandartes e a encosta de pedra com os pinheiros esparsos (`f115_15`), os lotes entre as ruas com o mato e as miudezas das
oficinas (`c5_09`). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo ou medida do jogo; tudo gerado no código.

## As fases

| Fase | O quê |
|---|---|
| 205 — Estandartes na fachada | os mastros curtos inclinados para fora da fachada, um de cada lado da porta da prefeitura, do teatro, da universidade, do museu e da escola, com a bandeira comprida balançando ao vento |
| 206 — Bebedouro de cavalos | o cocho de pedra com a coluna da bica numa célula livre junto da rua, ao lado das tavernas |
| 207 — Pinheiro-anão na encosta | pinheiros baixos e tortos crescendo no cascalho das encostas de pedra das ilhas temperadas |
| 208 — Rama de tecido | as ramas de madeira com os panos tingidos esticados secando ao lado das tecelagens |
| 209 — Lanterna nas carroças | a lanterna pendurada na frente de cada carroça, acesa à noite |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 01/11/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase205.md` a
`docs/plano_fase209.md`), testes, captura e benchmark; as três pastas da suíte passaram no fim (world 434, presentation 359, ui
167; o teste dos juncos da Fase 179 exigia que eles fossem a última peça do recheio e passou a conferir só a ordem). Diferenças
do roteiro: o bebedouro fica encostado na parede do lado da taverna, não junto da rua (as mesas pegam as células da frente, e
dar a vez a ele fazia as buscas chamarem umas às outras); a lanterna vai na malha da própria carroça (em camadas próprias custava
~0,7 FPS); nas Fases 208 e 209 a máquina estava no estado lento, e os A/B mostraram as duas neutras.
