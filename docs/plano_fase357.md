# Plano da Fase 357 — Esteira em V

**Estado: feita em 07/11/2026**, a terceira do roteiro `docs/plano_fases_355_359.md` (mar aberto). O navio do Anno deixa uma esteira
branca comprida em V; o nosso rastro (Fase 9) era uma fila de espuma parada atrás da popa que sumia em 6 s.

## O que entrou

- **O rastro em V** (`ShipView._build_wake`): a espuma sai da popa com velocidade (`WAKE_SPEED_M_S`, 0,35 a 0,8 m/s) para trás e para os
  lados, num leque de `WAKE_SPREAD_DEG` (65°) para cada lado no plano da água (`flatness` 1), freando devagar; vive `WAKE_LIFETIME_S`
  (10 s, eram 6) e são `WAKE_PARTICLES` (64, eram 40), vezes a proporção do nível gráfico.

## Medida

24 partículas a mais por navio navegando: sem custo à parte.

## Como testar

- `tests/presentation/test_phase357_wake.gd`: a direção para trás, o leque no plano, a velocidade, a vida e o número.
- Captura: `tools/capture_phase6.tscn` (`03_navegando.png`, em `F:\ferramentas\capturas\fase357\depois\`). **Inconclusiva**: o navio acabou
  de sair e o brilho do sol (com o sol na frente desde a Fase 330) domina o mar atrás dele; a esteira se confere com o navio já em
  viagem.
