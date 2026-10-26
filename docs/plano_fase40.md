# Plano da Fase 40 — Campos em colcha

**Estado: em andamento desde 26/10/2026**, pelo pedido do dono do produto de fazer todas as fases que faltam (`/goal`
de 26/10/2026). Nona fase do roteiro de `docs/plano_melhorias.md`. Só apresentação: a simulação continua com o campo e o
pasto de 3 × 3 células, e nada muda no save. Nada aparece na tela do dono (testes sem janela; benchmark e capturas na
área de trabalho escondida).

A escolha de sebe ou muro por região e o tratamento das ilhas tropicais são **proposta à espera do dono**.

## 1. Contorno orgânico (`presentation/crop_view.gd`)

- O campo deixa de ser a caixa marrom da `BuildingView`: a `CropView` desenha a terra lavrada como um polígono que
  segue o terreno, recuado da borda do lote com ruído. O ruído de cada lado é semeado pela **aresta compartilhada**
  (as coordenadas dela no mundo), então dois campos vizinhos têm a mesma ondulação dos dois lados da divisa, sem fresta
  e sem invasão: o contorno nunca sai do lote (recuo mínimo) nem entra na estrada.
- O pasto deixa de ser caixa verde: fica o capim do terreno, com a cerca e as touceiras no chão (antes ficavam no alto da
  caixa), e as trilhas gastas (abaixo).

## 2. Divisas: sebe e muro de pedra seca

- **Sebe** (região temperada) em MultiMesh ao longo de cada divisa de campo, uma vez por aresta (dois campos vizinhos não
  dobram a sebe), com **porteira**: a falha no meio do lado que dá para a estrada ou para a fazenda.
- **Muro de pedra seca** no campo em terreno de encosta (o lote com desnível) ou de solo pedregoso: pedras empilhadas em
  MultiMesh no lugar da sebe.
- Ilhas tropicais: sem sebe nem muro (só o contorno e as cores) — proposta.
- Sombra desligada e alcance de visibilidade nas sebes e muros (milhares de instâncias).

## 3. Fileiras e cor

- **Direção própria**: as fileiras e as leiras de cada campo correm em x ou em z, pela posição do campo na grade de 3
  células: dois campos vizinhos alinhados nunca correm na mesma direção. Uma faixa de **cabeceira** sem planta nas duas
  pontas das fileiras, com uma leira atravessada.
- **Cor por campo**: um tom próprio (terra mais clara ou mais escura, cereal mais verde ou mais dourado), determinístico
  pelo id, multiplicado na cor da instância junto com o crescimento que já existia (a cor por `INSTANCE_CUSTOM` fica de
  fora: o `use_custom_data` ligado fora de ordem chega zerado, e a cor da instância já basta).

## 4. Trilhas no pasto (máscara da Fase 38)

- O canal b da `RoadMask` (desgaste) ganha as trilhas dos bichos no pasto: da porteira ao meio e do meio a um canto, pelo
  id. O terreno já pinta o canal como chão batido.

## Fica de fora

- Campos de tamanho variável na simulação (continua 3 × 3); grama 3D densa.
- Cor e crescimento por `INSTANCE_CUSTOM` (ver acima).

## Riscos

- Borda invadindo a estrada: o recuo mínimo fica dentro do lote.
- Milhares de instâncias de sebe: uma por metro de divisa, com alcance de visibilidade e sem sombra.
- O vocabulário rural europeu nas ilhas tropicais: lá não há sebe.

## Como testar

- `tests/world/test_phase40_fields.gd` (sem tela): a divisa é idêntica vista dos dois lados; o contorno fica dentro do
  lote; a cor é determinística; vizinhos alinhados têm direções diferentes; a sebe sai uma vez por aresta e tem a
  porteira; a tropical não tem sebe; o pasto tem trilhas na máscara; a vista não mexe na simulação; o tempo de montar
  muitos campos.
- Os testes das plantações (`tests/presentation/test_crops.gd`, sem tela) e o benchmark na área de trabalho escondida
  (instâncias, draw calls e quadro).
- Capturas a 420 m e 110 m na área de trabalho escondida.

## Pronto quando

A 420 m os campos não leem como quadradinhos iguais, vizinhos têm direções diferentes e não há frestas; o dono aprova
sebe e muro por região e o tratamento das tropicais.
