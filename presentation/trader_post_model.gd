class_name TraderPostModel
extends RefCounted
## Feitoria do comerciante (Fase 15): plataforma de tábuas sobre estacas no mar, com um galpão de telhado de
## duas águas, um guindaste de vigas com um caixote pendurado, carga no convés (as peças do CargoKit), dois
## barcos a remo amarrados (HarborView.boat_mesh) e o mastro com a bandeira do comércio. Tudo gerado aqui; a
## ShipView só põe o nó no ponto do posto (Harbors.trader_post). O nível da água é y = 0.
## Fase 20: a madeira ganha o veio e o tom de cada tábua (`shaders/plank.gdshader`), o galpão vira parede de
## tábuas em pé com fresta, e o cordame (`Rigging`, os cabos do HarborView): os estais do guindaste, a adriça e
## os estais do mastro da bandeira e as amarras dos dois barcos.

## Plataforma: tamanho (x, z), altura do convés e espessura das tábuas.
const DECK_SIZE := Vector2(16.0, 12.0)
const DECK_HEIGHT_M := 1.6
const BOARD_WIDTH_M := 0.4
const BOARD_THICKNESS_M := 0.12
## Estacas: espaço entre elas e quanto descem abaixo da água.
const PILE_STEP_M := 4.0
const PILE_RADIUS_M := 0.3
const PILE_DEPTH_M := 4.0
## Galpão: tamanho (x, altura da parede, z), onde fica no convés e quanto o telhado sobe.
const SHED_SIZE := Vector3(7.0, 3.2, 6.0)
const SHED_CENTER := Vector2(-3.5, -1.0)
const ROOF_RISE_M := 2.0
## Guindaste: onde fica, altura do mastro e alcance do braço (para o mar, +X).
const CRANE_AT := Vector2(5.0, -3.5)
const CRANE_HEIGHT_M := 6.5
const CRANE_REACH_M := 4.5
const FLAG_AT := Vector2(6.5, 4.5)
const WOOD := Color(0.42, 0.32, 0.22)
const BOARD := Color(0.5, 0.38, 0.26)
const WALL := Color(0.62, 0.5, 0.36)
const ROOF := Color(0.32, 0.22, 0.17)
const ROPE := Color(0.7, 0.62, 0.45)
const FLAG := Color(0.75, 0.2, 0.15)
## Tábuas da parede do galpão e da porta (largura de cada uma).
const WALL_BOARD_M := 0.3
const DOOR_BOARD_M := 0.2
const FLAG_POLE_M := 8.0


static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "TraderPost"
	_deck(root)
	_shed(root)
	_crane(root)
	_cargo(root)
	_boats(root)
	_flag(root)
	_rigging(root)
	return root


## Tábuas de través em x, com fresta, e as estacas em grade.
static func _deck(root: Node3D) -> void:
	var boards := MultiMeshInstance3D.new()
	boards.name = "Deck"
	var board := BoxMesh.new()
	board.size = Vector3(BOARD_WIDTH_M - 0.05, BOARD_THICKNESS_M, DECK_SIZE.y)
	board.material = plank_material(BOARD, 0.0, true)
	boards.multimesh = MultiMesh.new()
	boards.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	boards.multimesh.mesh = board
	var count := int(DECK_SIZE.x / BOARD_WIDTH_M)
	boards.multimesh.instance_count = count
	for i: int in count:
		var x := -DECK_SIZE.x * 0.5 + (i + 0.5) * BOARD_WIDTH_M
		# uma tábua ou outra um pouco mais alta ou mais baixa, gasta
		var y := DECK_HEIGHT_M - BOARD_THICKNESS_M * 0.5 + (fposmod(i * 0.618, 1.0) - 0.5) * 0.02
		boards.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x, y, 0.0)))
	root.add_child(boards)
	var pile := CylinderMesh.new()
	pile.top_radius = PILE_RADIUS_M
	pile.bottom_radius = PILE_RADIUS_M
	pile.height = DECK_HEIGHT_M + PILE_DEPTH_M
	pile.radial_segments = 10
	pile.material = plank_material(WOOD.darkened(0.3), 0.0, false)
	var piles := MultiMeshInstance3D.new()
	piles.name = "Piles"
	piles.multimesh = MultiMesh.new()
	piles.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	piles.multimesh.mesh = pile
	var spots: Array[Vector3] = []
	var columns := int(DECK_SIZE.x / PILE_STEP_M)
	var rows := int(DECK_SIZE.y / PILE_STEP_M)
	for i: int in columns + 1:
		for k: int in rows + 1:
			var x := -DECK_SIZE.x * 0.5 + 0.4 + i * (DECK_SIZE.x - 0.8) / columns
			var z := -DECK_SIZE.y * 0.5 + 0.4 + k * (DECK_SIZE.y - 0.8) / rows
			spots.append(Vector3(x, (DECK_HEIGHT_M - PILE_DEPTH_M) * 0.5 - BOARD_THICKNESS_M, z))
	piles.multimesh.instance_count = spots.size()
	for i: int in spots.size():
		piles.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, spots[i]))
	root.add_child(piles)


## Galpão de tábuas com porta larga para o guindaste e telhado de duas águas.
static func _shed(root: Node3D) -> void:
	var floor_y := DECK_HEIGHT_M
	var walls := BoxMesh.new()
	walls.size = SHED_SIZE
	walls.material = plank_material(WALL, WALL_BOARD_M, false)
	_add(root, "Shed", walls, Vector3(SHED_CENTER.x, floor_y + SHED_SIZE.y * 0.5, SHED_CENTER.y))
	var roof := PrismMesh.new()
	roof.size = Vector3(SHED_SIZE.x + 0.8, ROOF_RISE_M, SHED_SIZE.z + 0.6)
	roof.material = _material(ROOF)
	# a cumeeira corre em z (o PrismMesh sobe em y, com a ponta no meio de x)
	_add(root, "Roof", roof, Vector3(SHED_CENTER.x, floor_y + SHED_SIZE.y + ROOF_RISE_M * 0.5, SHED_CENTER.y))
	var door := BoxMesh.new()
	door.size = Vector3(0.1, 2.4, 2.6)
	door.material = plank_material(WOOD.darkened(0.5), DOOR_BOARD_M, false)
	_add(root, "Door", door, Vector3(SHED_CENTER.x + SHED_SIZE.x * 0.5 + 0.05, floor_y + 1.2, SHED_CENTER.y))


## Mastro, braço para o mar com a escora, a corda e o caixote pendurado.
static func _crane(root: Node3D) -> void:
	var base := Vector3(CRANE_AT.x, DECK_HEIGHT_M, CRANE_AT.y)
	var top := base + Vector3(0.0, CRANE_HEIGHT_M, 0.0)
	var tip := top + Vector3(CRANE_REACH_M, -0.4, 0.0)
	var wood := _material(WOOD)
	root.add_child(_beam(base, top, 0.3, wood))
	root.add_child(_beam(top, tip, 0.22, wood))
	root.add_child(_beam(base + Vector3(0.0, CRANE_HEIGHT_M * 0.55, 0.0), top + Vector3(CRANE_REACH_M * 0.55, -0.25, 0.0),
			0.16, wood))
	var load_y := DECK_HEIGHT_M + 2.2
	root.add_child(_beam(tip, Vector3(tip.x, load_y + CargoKit.ITEM_M, tip.z), 0.04, _material(ROPE)))
	var crate := CargoKit.mesh(GoodDef.Pile.CRATE)
	if crate != null:
		_add(root, "HangingCrate", crate, Vector3(tip.x, load_y, tip.z))


## Barris, caixotes e sacos junto do galpão.
static func _cargo(root: Node3D) -> void:
	var places: Array = [
		[GoodDef.Pile.BARREL, Vector2(1.2, 2.0)], [GoodDef.Pile.BARREL, Vector2(2.1, 2.0)],
		[GoodDef.Pile.BARREL, Vector2(1.6, 2.9)], [GoodDef.Pile.CRATE, Vector2(3.2, -1.0)],
		[GoodDef.Pile.CRATE, Vector2(3.2, 0.0)], [GoodDef.Pile.SACK, Vector2(-0.6, 3.6)],
		[GoodDef.Pile.SACK, Vector2(-1.5, 3.6)], [GoodDef.Pile.SACK, Vector2(-1.05, 3.6)],
	]
	var index := 0
	for place: Array in places:
		var pile_kind: int = place[0]
		var spot: Vector2 = place[1]
		var piece := CargoKit.mesh(pile_kind)
		if piece == null:
			continue
		var node := _add(root, "Cargo%d" % index, piece, Vector3(spot.x, DECK_HEIGHT_M, spot.y))
		node.rotation.y = index * 0.7
		if CargoKit.tinted(pile_kind):
			node.material_override = _material(CargoKit.SACK_COLOR)
		# o terceiro saco vai por cima dos outros dois
		if index == places.size() - 1:
			node.position.y += CargoKit.STACK_M
		index += 1


## Dois barcos a remo amarrados de comprido no lado de −Z.
static func _boats(root: Node3D) -> void:
	var hull := HarborView.boat_mesh()
	var material := _material(HarborView.BOAT_COLOR)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	hull.surface_set_material(0, material)
	for i: int in 2:
		var boat := MeshInstance3D.new()
		boat.name = "Boat%d" % i
		boat.mesh = hull
		boat.position = Vector3(-3.0 + i * 5.0, -HarborView.BOAT_DRAFT_M, -DECK_SIZE.y * 0.5 - HarborView.BOAT_BEAM_M)
		boat.rotation.y = PI * 0.5 + i * 0.12
		root.add_child(boat)


static func _flag(root: Node3D) -> void:
	var pole := CylinderMesh.new()
	pole.top_radius = 0.08
	pole.bottom_radius = 0.11
	pole.height = FLAG_POLE_M
	pole.material = _material(WOOD.darkened(0.4))
	_add(root, "Pole", pole, Vector3(FLAG_AT.x, DECK_HEIGHT_M + FLAG_POLE_M * 0.5, FLAG_AT.y))
	root.add_child(WindFlag.make(Vector3(2.4, 1.5, 0.06), _material(FLAG), Vector3(FLAG_AT.x + 0.05, DECK_HEIGHT_M + 7.1, FLAG_AT.y)))


## Os cabos: dois estais do alto do mastro do guindaste ao convés (do lado de terra), a adriça da bandeira e
## dois estais do mastro dela, e a proa e a popa de cada barco até a beira do convés.
static func _rigging(root: Node3D) -> void:
	var spans: Array[PackedVector3Array] = []
	var crane_top := Vector3(CRANE_AT.x, DECK_HEIGHT_M + CRANE_HEIGHT_M, CRANE_AT.y)
	for side: float in [-1.0, 1.0]:
		spans.append(HarborView.rope_span(crane_top, Vector3(CRANE_AT.x - 2.5, DECK_HEIGHT_M, CRANE_AT.y + side * 2.2), 0.01))
	var pole_top := Vector3(FLAG_AT.x, DECK_HEIGHT_M + FLAG_POLE_M - 0.2, FLAG_AT.y)
	spans.append(HarborView.rope_span(pole_top + Vector3(0.12, 0.0, 0.0), Vector3(FLAG_AT.x + 0.12, DECK_HEIGHT_M + 1.0, FLAG_AT.y), 0.0))
	for side: float in [-1.0, 1.0]:
		spans.append(HarborView.rope_span(pole_top, Vector3(FLAG_AT.x - 1.8, DECK_HEIGHT_M, FLAG_AT.y + side * 1.8), 0.015))
	var edge_z := -DECK_SIZE.y * 0.5
	for child: Node in root.get_children():
		if not child.name.begins_with("Boat"):
			continue
		var boat := (child as Node3D).transform
		for end: Vector3 in [Vector3(0.0, HarborView.BOAT_DEPTH_M * 1.2, -HarborView.BOAT_LENGTH_M * 0.5 + 0.15),
				Vector3(0.0, HarborView.BOAT_DEPTH_M, HarborView.BOAT_LENGTH_M * 0.5 - 0.15)]:
			var on_boat := boat * end
			var cleat := Vector3(on_boat.x + signf(on_boat.x - boat.origin.x) * 0.6, DECK_HEIGHT_M, edge_z + 0.2)
			spans.append(HarborView.rope_span(cleat, on_boat, HarborView.ROPE_SAG))
	var material := _material(ROPE)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rigging := MeshInstance3D.new()
	rigging.name = "Rigging"
	rigging.mesh = HarborView.rope_mesh(spans, material, HarborView.ROPE_RADIUS_M * 1.2)
	rigging.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rigging)


## Madeira com o veio e o tom de cada tábua; board_m acima de zero desenha as tábuas em pé de uma parede.
static func plank_material(color: Color, board_m: float, top_along_z: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/plank.gdshader") as Shader
	material.set_shader_parameter(&"albedo", color)
	material.set_shader_parameter(&"board_m", board_m)
	material.set_shader_parameter(&"top_along_z", top_along_z)
	return material


static func _add(root: Node3D, node_name: String, mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = at
	root.add_child(node)
	return node


## Viga quadrada de from a to.
static func _beam(from: Vector3, to: Vector3, width: float, material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = Vector3(width, from.distance_to(to), width)
	box.material = material
	var node := MeshInstance3D.new()
	node.mesh = box
	var up := (to - from).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	node.transform = Transform3D(Basis(side, up, side.cross(up)), (from + to) * 0.5)
	return node


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
