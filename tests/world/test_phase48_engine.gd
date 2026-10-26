extends GdUnitTestSuite
## Godot 4.8 (Fase 48, ramo godot-4.8): o motor é o 4.8, as sombras de contato e o AO de vários quiques estão ligados no
## projeto, e só o alto e o ultra pedem as sombras de contato do sol.


func test_the_engine_is_four_point_eight() -> void:
	var info := Engine.get_version_info()
	assert_int(info["major"]).is_equal(4)
	assert_int(info["minor"]).is_greater_equal(8)


func test_contact_shadows_and_multi_bounce_are_on_in_the_project() -> void:
	assert_bool(ProjectSettings.get_setting("rendering/lights_and_shadows/contact_shadow/enabled")).is_true()
	assert_bool(ProjectSettings.get_setting("rendering/lights_and_shadows/multi_bounce_occlusion/enabled")).is_true()


func test_only_high_and_ultra_ask_for_sun_contact_shadows() -> void:
	var wanted := {&"low": false, &"medium": false, &"high": true, &"ultra": true}
	for preset: GraphicsPresetDef in GameConfig.get_default().graphics_presets:
		assert_bool(preset.contact_shadows).override_failure_message(str(preset.id)).is_equal(wanted[preset.id])
	var sun: DirectionalLight3D = auto_free(DirectionalLight3D.new())
	sun.shadow_contact_shadows_allow = GameConfig.get_default().graphics_presets[2].contact_shadows
	assert_bool(sun.shadow_contact_shadows_allow).is_true()
