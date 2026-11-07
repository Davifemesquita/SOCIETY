# Plano da Fase 337 — Rua larga na vila

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_335_339.md` (estrada no jeito do Anno). No Anno a rua da vila é
larga e a estrada do campo estreita; a nossa tinha uma largura só.

## O plano

- **Arquivos**: `shaders/terrain.gdshader` (a largura da estrada de terra), o teste novo, `AGENTS.md` e o roteiro.
- **Risco**: a rua invadir a frente dos prédios; precisar de um canal novo na máscara das estradas (os quatro já estão usados).
- **Como testar**: o teste novo e a vila de perto e de cima antes e depois.

## O que entrou

- **Sem canal novo**: o canal b da máscara (Fases 38, 111, 165 e 301) já marca o chão de vila — as portas, o quintal das casas (o lote
  mais 2,2 m nas temperadas, 1,6 m nas tropicais) e o pátio das fábricas —, e a estrada encostada numa casa passa dentro dele (o meio
  da estrada fica a 1 m da parede).
- **A largura**: no campo a meia largura cai para `road_half_width_m` 0,72 m (era 0,8); onde o canal b passa de 0,25, ela cresce até
  `road_town_widen_m` (0,33 m) a mais, 1,05 m: a rua quase enche a célula entre as casas. A sombra dos prédios esconde a junção com o
  pé deles.

## Medida

Um `smoothstep` por pixel de estrada: sem custo à parte (medido no fim do roteiro).

## Como testar

- `tests/world/test_phase337_town_street.gd`: mais estreita no campo, perto de encher a célula na vila, a largura lida depois da
  máscara, e o quintal das casas chegando ao meio da estrada.
- Captura: `tools/capture_phase330.tscn -- <pasta>`; antes em `F:\ferramentas\capturas\fase336\depois\`, depois em
  `F:\ferramentas\capturas\fase337\depois\`.
