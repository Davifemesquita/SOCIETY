# Plano da Fase 64 — Baleias e golfinhos

**Estado: feita em 27/10/2026, a pedido do dono** ("pode fazer toda e seguir para a próxima", sobre a leva de
propostas depois da Fase 62). Só apresentação: a simulação, o terreno e as assinaturas não mudam; nada vai no save.

A proposta "fábricas com o estado visível de longe" ficou sem fase: já está feita (a fumaça só sai produzindo, Fase 9;
as janelas só acendem trabalhando; os ícones de estado agregados de longe, Fase 33).

## O que entrou

- **`MarineLifeView`** (`presentation/marine_life_view.gd`, montada pela `GameScreen` junto da água): quatro baleias no
  mar aberto e três bandos de quatro golfinhos em águas médias, em dois MultiMesh, com malhas geradas no código (corpo
  de anéis que afina para a cauda, barriga clara, aletas da cauda; o golfinho com nadadeira dorsal).
- **Lugares** pelo campo de distância da costa (`CoastField`, Fase 35) e pela semente do mundo: baleia onde a costa
  fica a 60 m ou mais, golfinho entre 14 e 45 m, dentro das ilhas mais 260 m de margem, longe um do outro.
- **Movimento** no tempo de jogo (para na pausa), por funções puras (`whale_pose`, `dolphin_pose`): a baleia dá a volta
  num círculo de 120 m a 2 m/s e, a cada 40 s, fica 8 s à tona com o dorso de fora, sopra o esguicho (partículas de
  névoa) e mergulha em 3 s inclinando o nariz e erguendo a cauda; o resto do ciclo, some no fundo. O bando de golfinhos
  dá a volta num círculo de 60 m a 6 m/s e cada um salta em arco de 1,5 m, um depois do outro, apontando para onde vai.

## Números

- Benchmark (alto, RTX 5060): +8 draw calls, GPU no nível das fases anteriores medidas com a máquina no mesmo estado
  lento (22,5 ms; ver `docs/benchmark.md`).

## Como testar

- `tests/presentation/test_phase64_marine_life.gd`: as malhas no tamanho, os lugares pela distância da costa (e iguais
  pela semente), a baleia à tona nivelada, mergulhando com a cauda acima da cabeça e sumida no fundo, o golfinho no arco
  com o nariz para cima na subida e para baixo na descida, e a vista com o esguicho ao subir.
- Capturas: `tools/capture_phase64.tscn -- <pasta>` (a baleia à tona e mergulhando, um golfinho saltando; em
  `F:\ferramentas\capturas\fase64`).

## Fica de fora (proposta à espera do dono)

- Baleias que fogem dos navios, cardumes visíveis nos pesqueiros e gaivotas sobre os golfinhos.
