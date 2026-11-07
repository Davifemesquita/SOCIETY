# Roteiro das Fases 150 a 154 — Coluna, placa e velocípede

**31/10/2026.** Oitavo ciclo do pedido do dono ("pode continuar, faça mais 4 ciclos"), o último deste pedido: abrir o Anno,
idealizar e fazer. As ideias saem de capturas novas do centro da cidade do Anno 1800 dele
(`F:\ferramentas\capturas\anno\c8_*.png`, fora do repositório): a coluna redonda de cartazes na esquina, as placas das lojas
penduradas em braços de ferro sobre a calçada, as balizas com correntes na beira do largo da igreja, os vasos de flores nas
sacadas e o velocípede encostado na parede (`c8_01`, `c8_02`). Como sempre, **só a ideia**: nenhum modelo, textura, arquivo
ou medida do jogo; tudo gerado no código, e nenhum texto escrito nas placas e nos cartazes (só cores e figuras).

## As fases

| Fase | O quê |
|---|---|
| 150 — Coluna de anúncios | colunas redondas de cartazes coloridos com o chapéu de ferro numa esquina calçada a cada tanto |
| 151 — Placas das lojas | a placa pendurada num braço de ferro sobre a porta das lojas da rua, com a figura do ofício pintada |
| 152 — Balizas com corrente | balizas de ferro com correntes caindo em curva na beira do largo calçado dos serviços, de frente para a rua |
| 153 — Flores nas sacadas | floreiras com flores vermelhas e rosas ao longo das sacadas dos engenheiros e investidores |
| 154 — Velocípede encostado | o velocípede de roda grande encostado na parede de uma casa a cada tanto, dos artesãos para cima |

Cada fase segue a regra de sempre: plano curto em `docs/plano_faseNN.md`, testes, captura e benchmark, commit e push.

## Estado

**Concluído em 31/10/2026**: as cinco fases feitas, cada uma com o plano dela (`docs/plano_fase150.md` a
`docs/plano_fase154.md`), testes, captura e benchmark. Diferenças do roteiro: a coluna (150) fica uma a cada duas esquinas
(as árvores da alameda tomavam quase todas as de três) e a busca anda só pelas células calçadas; as placas (151) também
foram para o ourives, o relojoeiro, o óptico, a torrefação e a charutaria; as balizas (152) pulam o lado do poste de gás; as
floreiras (153) são caixas próprias, não a peça da sebe; o velocípede (154) ficou só nos artesãos (os engenheiros têm o
gradil na frente e os investidores a sebe).
