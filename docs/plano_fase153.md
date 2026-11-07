# Plano da Fase 153 — Flores nas sacadas

**Estado: feita em 31/10/2026**, quarta do roteiro `docs/plano_fases_150_154.md` (coluna, placa e velocípede, olhando o
Anno do dono: só a ideia). Só apresentação: nada muda na simulação nem no save.

## O que entrou

- **Quem** (`BuildingKit.Spec.balcony_flowers`, na chave da forma): as casas de `TierDef.HouseTrim.BALCONIES` (engenheiros)
  e `PORTICO` (investidores), as que têm sacadas.
- **A floreira** (`_balcony_box`): uma por célula de cada sacada, pendurada por fora do guarda-corpo
  (`BALCONY_FLOWERS_OUT_M` além da frente da sacada, `BALCONY_FLOWERS_UP_M` acima do piso dela, logo abaixo do corrimão): a
  caixa de madeira escura, a folhagem por cima e em três tufos, e os ramos pendendo por fora, tudo na célula (3, 3) da
  paleta (`UV_FOLIAGE`), que o shader do kit já pinta de folha com flores vermelhas, rosas, amarelas e brancas.

## No caminho

- A primeira versão usava a peça da sebe do kit, que ficava quase toda dentro do guarda-corpo e pequena demais; a floreira
  passou a ser feita de caixas.
- O teste da cerca de estacas (Fase 143) comparava duas casas diferentes (cada id tem a sua variação de telhado e ala) e
  só passava por sorte; ele e o desta fase comparam agora as duas formas da mesma casa.

## Como testar

- `tests/presentation/test_phase153_balcony_flowers.gd`: só engenheiros e investidores têm as floreiras; elas mudam a chave
  da forma e somam triângulos na mesma casa; a floreira fica por fora e abaixo do corrimão.
- Captura: as ruas dos engenheiros e investidores do `tools/capture_phase95.tscn` (`sacadas_floridas.png` e
  `sacadas_floridas_b.png`).
