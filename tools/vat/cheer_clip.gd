class_name CheerClip
extends RefCounted
## Fase 84: a animação de ver os fogos, gerada no código a partir da parada (os pacotes da Quaternius não trazem palmas):
## o pescoço e a cabeça erguidos para o céu e as mãos batendo palmas diante do peito, CLAPS vezes por volta. Os braços
## seguem por IK de dois ossos (ombro, cotovelo, pulso), com o cotovelo para baixo e para fora; o resto do corpo é o da
## parada, no mesmo ritmo dela (a volta fecha sem salto).

## Quanto o pescoço e a cabeça sobem (rad).
const NECK_PITCH := 0.3
const HEAD_PITCH := 0.4
## Palmas por volta da animação parada.
const CLAPS := 6
## As mãos diante do peito: à frente e abaixo do meio dos ombros, em frações do comprimento do braço.
const HANDS_AHEAD := 0.6
const HANDS_BELOW := 0.3
## Meia distância entre as mãos: aberta e na palma (frações do braço).
const HANDS_OPEN := 0.16
const HANDS_SHUT := 0.025
const FPS := 24.0
const BONES := ["neck_01", "Head", "upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "hand_r"]


## A animação, com as trilhas da parada (idle) e as dos ossos de BONES trocadas.
static func make(source: VatBaker.Source, idle: Animation) -> Animation:
	var animation := idle.duplicate(true) as Animation
	animation.loop_mode = Animation.LOOP_LINEAR
	var tracks: Dictionary[String, int] = {}
	for bone_name: String in BONES:
		var track := animation.find_track(NodePath("Armature/Skeleton3D:" + bone_name), Animation.TYPE_ROTATION_3D)
		if track < 0:
			track = animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("Armature/Skeleton3D:" + bone_name))
		while animation.track_get_key_count(track) > 0:
			animation.track_remove_key(track, 0)
		tracks[bone_name] = track
	var frames := maxi(2, roundi(idle.length * FPS))
	for frame: int in frames + 1:
		var time := idle.length * frame / frames
		var locals := pose_at(source, idle, time)
		for bone_name: String in BONES:
			animation.rotation_track_insert_key(tracks[bone_name], time, locals[bone_name])
	return animation


## Rotação local de cada osso de BONES no instante time.
static func pose_at(source: VatBaker.Source, idle: Animation, time: float) -> Dictionary[String, Quaternion]:
	var globals := VatBaker.pose(source, idle, time)
	var frame := body_frame(source, globals)
	var forward: Vector3 = frame[0]
	var up: Vector3 = frame[1]
	var side := forward.cross(up).normalized()
	# erguer: girar em volta de side leva a frente para cima
	_turn(source, globals, "neck_01", Basis(side, NECK_PITCH))
	_turn(source, globals, "Head", Basis(side, HEAD_PITCH))
	var shoulder_l := globals[source.bone_index("upperarm_l")].origin
	var shoulder_r := globals[source.bone_index("upperarm_r")].origin
	var reach := _arm_length(source, globals, "l")
	var middle := (shoulder_l + shoulder_r) * 0.5 + forward * reach * HANDS_AHEAD - up * reach * HANDS_BELOW
	var across := (shoulder_l - shoulder_r).normalized()
	var gap := hands_gap(time / idle.length) * reach
	_reach(source, globals, "l", middle + across * gap, up, forward)
	_reach(source, globals, "r", middle - across * gap, up, forward)
	var result: Dictionary[String, Quaternion] = {}
	for bone_name: String in BONES:
		var bone := source.bone_index(bone_name)
		var parent := source.bone_parents[bone]
		var parent_basis := globals[parent].basis if parent >= 0 else Basis.IDENTITY
		result[bone_name] = (parent_basis.inverse() * globals[bone].basis).get_rotation_quaternion()
	return result


## Meia distância entre as mãos (fração do braço) na fração phase da volta: fecha de repente na palma e abre devagar.
static func hands_gap(phase: float) -> float:
	var beat := fposmod(phase * CLAPS, 1.0)
	var open := 1.0 - pow(1.0 - beat, 3.0) if beat < 0.85 else (1.0 - beat) / 0.15
	return lerpf(HANDS_SHUT, HANDS_OPEN, clampf(open, 0.0, 1.0))


## Frente e cima do corpo no espaço do esqueleto: a frente vai do tornozelo para a ponta do pé.
static func body_frame(source: VatBaker.Source, globals: Array[Transform3D]) -> Array[Vector3]:
	var head := globals[source.bone_index("Head")].origin
	var pelvis := globals[source.bone_index("pelvis")].origin
	var up := (head - pelvis).normalized()
	var toes := Vector3.ZERO
	for foot: String in ["l", "r"]:
		toes += globals[source.bone_index("ball_" + foot)].origin - globals[source.bone_index("foot_" + foot)].origin
	var forward := (toes - up * toes.dot(up)).normalized()
	return [forward, up]


static func _arm_length(source: VatBaker.Source, globals: Array[Transform3D], side: String) -> float:
	var shoulder := globals[source.bone_index("upperarm_" + side)].origin
	var elbow := globals[source.bone_index("lowerarm_" + side)].origin
	var wrist := globals[source.bone_index("hand_" + side)].origin
	return shoulder.distance_to(elbow) + elbow.distance_to(wrist)


## Gira o osso (em volta da origem dele, no espaço do esqueleto) e leva os filhos junto.
static func _turn(source: VatBaker.Source, globals: Array[Transform3D], bone_name: String, turn: Basis) -> void:
	var bone := source.bone_index(bone_name)
	var pivot := globals[bone].origin
	var moved := Transform3D(turn, pivot - turn * pivot)
	for other: int in globals.size():
		if other == bone or _descends(source, other, bone):
			globals[other] = moved * globals[other]


static func _descends(source: VatBaker.Source, bone: int, ancestor: int) -> bool:
	var parent := source.bone_parents[bone]
	while parent >= 0:
		if parent == ancestor:
			return true
		parent = source.bone_parents[parent]
	return false


## IK de dois ossos: leva o pulso até target, com o cotovelo para baixo, para fora e um pouco para trás.
static func _reach(source: VatBaker.Source, globals: Array[Transform3D], side: String, target: Vector3, up: Vector3,
		forward: Vector3) -> void:
	var upper := source.bone_index("upperarm_" + side)
	var lower := source.bone_index("lowerarm_" + side)
	var hand := source.bone_index("hand_" + side)
	var shoulder := globals[upper].origin
	var elbow := globals[lower].origin
	var wrist := globals[hand].origin
	var a := shoulder.distance_to(elbow)
	var b := elbow.distance_to(wrist)
	var to_target := target - shoulder
	var reach := clampf(to_target.length(), absf(a - b) + 0.001, a + b - 0.001)
	var aim := to_target.normalized()
	var outward := shoulder - (globals[source.bone_index("upperarm_l")].origin + globals[source.bone_index("upperarm_r")].origin) * 0.5
	var pole := -up + outward.normalized() * 0.6 - forward * 0.3
	var bend := (pole - aim * pole.dot(aim)).normalized()
	var cos_a := clampf((a * a + reach * reach - b * b) / (2.0 * a * reach), -1.0, 1.0)
	var new_elbow := shoulder + aim * a * cos_a + bend * a * sqrt(1.0 - cos_a * cos_a)
	_turn(source, globals, "upperarm_" + side, Basis(Quaternion((elbow - shoulder).normalized(),
			(new_elbow - shoulder).normalized())))
	var moved_wrist := globals[hand].origin
	var new_wrist := shoulder + aim * reach
	_turn(source, globals, "lowerarm_" + side, Basis(Quaternion((moved_wrist - new_elbow).normalized(),
			(new_wrist - new_elbow).normalized())))
