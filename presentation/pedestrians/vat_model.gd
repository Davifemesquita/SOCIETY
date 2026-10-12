class_name VatModel
extends Resource
## Personagem pronto para a multidão (seção 14): malha reduzida e as animações gravadas em
## textura (VAT). Cada linha da textura é um quadro; cada coluna, um vértice. O shader
## shaders/pedestrian_vat.gdshader lê a posição e a normal do quadro e anda o boneco.
## Gerado por tools/bake_pedestrians.gd; gravado em .res (o float da posição passa exato).

## Regiões do corpo, guardadas no UV.x de cada vértice: o shader pinta cada uma (pele, cabelo,
## roupa de cima, calça ou saia, sapato) com as cores da classe.
enum Region { SKIN, HAIR, COAT, TROUSERS, SHOES }

## Malha na pose de repouso, virada para −Z. UV.x = região, UV2.x = índice do vértice.
@export var mesh: ArrayMesh
## Posição de cada vértice em cada quadro (RGBAH, metros).
@export var positions: Texture2D
## Normal de cada vértice em cada quadro (RGBA8, n * 0,5 + 0,5).
@export var normals: Texture2D
@export var clip_names: PackedStringArray = PackedStringArray()
@export var clip_start_rows: PackedInt32Array = PackedInt32Array()
@export var clip_frame_counts: PackedInt32Array = PackedInt32Array()
## Quadros por segundo das animações paradas.
@export var fps: float = 24.0
## Distância andada num ciclo de cada animação (0 nas paradas): o passo acompanha o chão.
@export var clip_strides_m: PackedFloat32Array = PackedFloat32Array()
@export var vertex_count: int = 0
@export var triangle_count: int = 0


func clip_index(clip_name: String) -> int:
	return clip_names.find(clip_name)


## Dados de cada animação para o shader: início, quadros, quadros por segundo e passo.
func clip_uniforms() -> PackedVector4Array:
	var result := PackedVector4Array()
	for i: int in clip_names.size():
		result.append(Vector4(clip_start_rows[i], clip_frame_counts[i], fps, clip_strides_m[i]))
	return result
