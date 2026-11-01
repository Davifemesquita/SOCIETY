# Plano da Fase 198 — Bancos no cais

**Estado: feita em 01/11/2026**, a quarta do roteiro `docs/plano_fases_195_199.md` (cemitério, pato e rede, a partir das
capturas do Anno do dono já guardadas: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Onde** (`QuayBenchView.benches`): nos lanços do cais de pedra dos entrepostos (Fase 106) do resto `BENCH_REST` de
  `BENCH_EVERY` (entre os cabeços), fora da frente do entreposto, `BENCH_IN_M` para dentro da beira, no alto da plataforma. Fica
  de fora o banco que cairia a menos de `CLEAR_M` de um lampião (Fase 146), de uma cisterna (Fase 127), de um mastro (Fase 147)
  ou do alto de uma escada (Fase 194), e o que a terra de trás cobriria (`BURIED_M`).
- **O banco** (`bench_mesh`): o banco de praça da decoração (`DecorationView._bench`, pés de ferro, assento e encosto de
  tábuas), de costas para a cidade e virado para o mar. Um MultiMesh.

## Como testar

- `tests/world/test_phase198_quay_benches.gd`: os bancos ficam no alto do cais, para dentro da beira, virados para o mar e fora
  da frente do entreposto; longe dos lampiões, das cisternas, dos mastros e das escadas; nada na ilha plana.
- Captura: `tools/capture_phase198.tscn` (o entreposto da ilha principal da semente 1840, o banco do mar, de trás e o cais
  inteiro).
