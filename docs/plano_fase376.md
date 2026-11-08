# Plano da Fase 376 — Madeiramento do pacote

**Estado: feita em 08/11/2026**, a primeira do roteiro `docs/plano_fases_376_380.md` (peças do MegaKit III).

## O problema

Com as paredes do MegaKit, o madeiramento gerado no código (a viga entre os andares da Fase 365, o enxaimel saliente da Fase 102,
a varanda, a plataforma do armazém, o guindaste) saía na célula `UV_TIMBER` da paleta do Kenney: uma cor lisa ao lado da madeira
com veio do pacote. A viga entre os andares chegava a sair cinza-clara de cima.

## O que entrou

- **`BuildingKit._mega_wood_box`**: a caixa na madeira do pacote (camada 1, UV2.x = 2), em cada face o veio ao longo do lado mais
  comprido, numa tábua da faixa escura da textura (`MEGAKIT_WOOD_V`, `MEGAKIT_WOOD_U_PER_M`, `MEGAKIT_WOOD_MAX_V`) sorteada pelo
  lugar.
- **`_box` e `_box_at`** (e, por ele, o `_bar`) mandam a caixa `UV_TIMBER` para ela quando o MegaKit está ligado e a SurfaceTool é
  uma das do referencial do prédio (`_frame_tools`: a principal e a extra). As que se juntam com outra transformação (o telhado da
  ala, as janelas giradas) seguem na paleta, para nada sair no lugar errado.
- Sem o MegaKit nada muda.

## Como testar

- `tests/presentation/test_phase376_pack_timber.gd`: com o MegaKit, o enxaimel saliente põe vértices na madeira do pacote e nenhum
  a mais na célula da paleta; com o Kenney, o contrário.
- Os testes das Fases 102, 365 e 373 passaram a contar a madeira do pacote (a 102 confere o Kenney).
- Captura: `rua_artisans_a.png` no `tools/capture_phase95.tscn` (`F:\ferramentas\capturas\fase376\dia`): a viga entre os andares
  passou de cinza-clara a madeira escura.
