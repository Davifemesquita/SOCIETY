extends GdUnitTestSuite
## Feitoria do comerciante (Fase 15): plataforma de tábuas sobre estacas que entram na água, galpão com
## telhado, guindaste, carga, dois barcos e a bandeira.


func test_the_trading_post_is_a_planked_platform_on_piles() -> void:
	var post: Node3D = auto_free(TraderPostModel.build())
	var deck := post.get_node(^"Deck") as MultiMeshInstance3D
	assert_int(deck.multimesh.instance_count).is_equal(int(TraderPostModel.DECK_SIZE.x / TraderPostModel.BOARD_WIDTH_M))
	var piles := post.get_node(^"Piles") as MultiMeshInstance3D
	assert_int(piles.multimesh.instance_count).is_greater_equal(9)
	var pile := piles.multimesh.mesh as CylinderMesh
	var bottom := piles.multimesh.get_instance_transform(0).origin.y - pile.height * 0.5
	assert_float(bottom).is_less(-1.0)
	var top := piles.multimesh.get_instance_transform(0).origin.y + pile.height * 0.5
	assert_float(top).is_less_equal(TraderPostModel.DECK_HEIGHT_M)


func test_it_has_a_shed_a_crane_cargo_two_boats_and_the_flag() -> void:
	var post: Node3D = auto_free(TraderPostModel.build())
	for node_name: String in ["Shed", "Roof", "Door", "Pole", "Flag", "Boat0", "Boat1"]:
		assert_object(post.get_node_or_null(NodePath(node_name))).override_failure_message(node_name).is_not_null()
	var boat := post.get_node(^"Boat0") as Node3D
	assert_float(boat.position.y).is_less(0.0)
	var cargo := 0
	for child: Node in post.get_children():
		if child.name.begins_with("Cargo"):
			cargo += 1
	assert_int(cargo).is_greater_equal(6)
	# o guindaste: vigas além do galpão, para o lado do mar (+X)
	var reach := -INF
	for child: Node in post.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			reach = maxf(reach, (child as Node3D).position.x)
	assert_float(reach).is_greater(TraderPostModel.CRANE_AT.x)
