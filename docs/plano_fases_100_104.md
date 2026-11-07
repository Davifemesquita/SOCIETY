# Roteiro das Fases 100 a 104 — A rua habitada

**29/10/2026.** Depois das formas mais redondas (Fases 95 a 99), o dono pediu para seguir para a próxima. As ideias saem das
mesmas capturas do Anno 1800 dele tiradas para o roteiro anterior (`F:\ferramentas\capturas\anno\f95_*.png`, fora do
repositório; a `f95_09.png`, uma rua de casas de perto, é a que mais mostra). Como sempre, **só a ideia**: nenhum modelo,
textura, arquivo ou medida do jogo; tudo gerado no código.

## O que o Anno mostra e o Society não tem

Na rua do Anno, as casas parecem habitadas: sai fumaça de quase toda chaminé, as lojas do térreo têm toldo listrado, o
andar de cima das casas mais simples é de enxaimel e avança sobre a rua, os galpões e as fábricas têm claraboias de vidro
no telhado, e há lampião preso na parede junto das portas e grade de ferro com portão em volta dos pátios. No Society a
chaminé da casa é um bloco cinza parado, a fachada é uma parede só do chão ao beiral, e o telhado das fábricas é inteiro de
telha.

## As fases

| Fase | O quê |
|---|---|
| 100 — Fumaça das casas | baforadas saindo das chaminés das casas com morador, mais de manhã e à noite, deitando com o vento, num MultiMesh só animado no shader |
| 101 — Toldos listrados | toldo de lona listrada sobre a porta e as janelas do térreo das lojas (padaria, açougue, taverna, mercado) e de parte das casas dos artesãos para cima |
| 102 — Enxaimel saliente | o andar de cima das casas dos operários e dos artesãos avança um palmo sobre a rua, com o madeiramento à mostra (enxaimel) e as mãos-francesas por baixo |
| 103 — Claraboias | faixas de vidro nas águas e nas abóbadas das fábricas de nave comprida, com caixilho de ferro, que acendem à noite com a fábrica trabalhando |
| 104 — Lampião de parede e grade | lampião de ferro junto da porta dos serviços e das casas dos artesãos para cima (aceso à noite) e grade de ferro com portão em volta do pátio dos serviços de pedra; a chaminé das casas troca o bloco do kit por uma de tijolo com o capitel |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura (`tools/capture_phase95.tscn`,
que já tem as ruas de cada classe e os prédios grandes) e benchmark, commit e push.

## Estado

**Concluído em 29/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase100.md` a
`docs/plano_fase104.md`), testes, captura em `tools/capture_phase95.tscn` e benchmark. Diferenças do roteiro: o toldo das
casas tem uma cor por classe (três cores triplicavam as formas de casa); as claraboias ficaram nas fábricas sem silhueta
própria; a grade de ferro foi para o pátio do museu, o único serviço de pedra com pátio.
