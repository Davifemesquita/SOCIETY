extends Node
## Roteiro de verificação visual da Fase 44: o menu principal com a carta gravada no fundo (esperando a thread dela) e o
## jogo novo com a prévia de duas sementes. Precisa de GPU; no PC do dono roda na área de trabalho escondida:
##   godot --path . --resolution 1920x1080 --quit-after 20000 res://tools/capture_phase44.tscn -- <pasta>

const WAIT_FRAMES := 900

var _out_dir: String


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_out_dir = args[0] if not args.is_empty() else OS.get_user_data_dir().path_join("capturas")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_run.call_deferred()


func _run() -> void:
	var boot: Control = (load("res://ui/screens/boot_screen.tscn") as PackedScene).instantiate()
	add_child(boot)
	var background := boot.find_children("*", "MenuBackground", true, false)[0] as MenuBackground
	for frame: int in WAIT_FRAMES:
		if background.has_chart():
			break
		await get_tree().process_frame
	await _save("01_menu_principal.png")
	var dialog: NewGameDialog = boot.call(&"open_new_game")
	for seed_text: String in ["1840", "52731"]:
		dialog.seed_edit.text = seed_text
		dialog.start_preview()
		for frame: int in WAIT_FRAMES:
			if dialog.preview.texture != null:
				break
			await get_tree().process_frame
		await _save("02_jogo_novo_%s.png" % seed_text)
	get_tree().quit()


func _save(file_name: String) -> void:
	for frame: int in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out_dir.path_join(file_name))
	print("capturado ", file_name)
