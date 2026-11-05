# Plano da Fase 319 — Correnteza

**Estado: feita em 04/11/2026**, a última do roteiro `docs/plano_fases_315_319.md` (garganta do rio). No Anno, a água do rio corre:
riscos claros andam ao longo do canal. No Society, o rio é um braço de mar parado (Fase 5), escuro e calmo desde a Fase 283.

## O plano

- **Arquivos**: `shaders/water.gdshader` e o teste novo.
- **Risco**: o rio não tem rumo na simulação nem na apresentação, e não dá para saber para que lado ele corre. O rumo sai do mapa da
  costa: ao longo da margem, de través da distância até a terra. O sentido é escolhido sempre para o mesmo lado, para as duas
  margens (onde o gradiente aponta ao contrário) andarem juntas.
- **Como testar**: o teste do shader, a captura dos matacões da Fase 122 e o benchmark.

## O que entrou

- **`shaders/water.gdshader`**, no bloco do mapa da costa, depois da espuma da costa, só no canal (`channel`):
  - o gradiente do mapa da costa por quatro leituras a `river_flow_probe_m` (1,5 m);
  - o rumo de través dele, virado para o lado de (0,83; 0,56);
  - um ruído de duas oitavas esticado ao longo do rumo (`river_flow_length_m` 7 m por `river_flow_width_m` 0,35 m), andando a
    `river_flow_speed` (0,6 m/s) e quebrado pela textura da espuma;
  - na cor da espuma, na força `river_flow` (0,4).
- Onde o rio faz curva, os riscos entortam um pouco: o desenho é no mundo, pelo rumo de cada ponto.

## Medida

72,3 FPS (318: 71,8), GPU 12,9 ms (318: 13,0). Objetos, draw calls e primitivas iguais. Neutra.

## Como testar

- `tests/world/test_phase319_river_flow.gd`: os riscos ao longo do canal, de través do gradiente, num sentido só, andando com o tempo,
  só no canal, mais compridos que largos, devagar e fracos; o shader compilando com os uniformes novos (com tela).
- Captura: `tools/capture_phase122.tscn -- <pasta>` (`rio_de_perto.png`); antes e depois em
  `F:\ferramentas\capturas\fase318\rio_depois\` e `F:\ferramentas\capturas\fase319\rio_depois\`.
