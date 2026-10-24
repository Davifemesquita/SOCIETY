class_name MoneyFxView
extends Node3D
## Dinheiro visível no mundo (Fase 30): quando o comerciante paga na visita a uma ilha (EventBus.trader_visited com
## earned > 0), COINS moedas saltam em arco sobre o entreposto dela e um "+1.240" sobe e some. Nunca no imposto de
## cada tick. No máximo MAX_EFFECTS ao mesmo tempo, com os nós reaproveitados; um ganho a mais com o teto cheio não
## aparece. Só lê a simulação; a animação é de interface e segue andando com o jogo pausado.

const MAX_EFFECTS := 4
const COINS := 6
const DURATION_S := 1.6
## De onde o texto sai acima das moedas e quanto ele sobe, a altura do salto das moedas e até onde elas caem do
## centro (m).
const TEXT_START_M := 2.5
const RISE_M := 6.0
const HOP_M := 4.0
const SPREAD_M := 3.0
## Acima do alto das paredes do entreposto (BuildingDef.height_m), de onde sai o efeito, livre do telhado (m).
const LIFT_M := 4.0
const COIN_COLOR := Color(0.95, 0.75, 0.25)
const TEXT_COLOR := Color(1.0, 0.86, 0.4)
const OUTLINE_COLOR := Color(0.25, 0.16, 0.05)

var _simulation: Simulation
var _effects: Array[Node3D] = []
var _coin_mesh: CylinderMesh


func setup(simulation: Simulation) -> void:
	_simulation = simulation
	_coin_mesh = CylinderMesh.new()
	_coin_mesh.top_radius = 0.5
	_coin_mesh.bottom_radius = 0.5
	_coin_mesh.height = 0.1
	_coin_mesh.radial_segments = 12
	_coin_mesh.rings = 1
	var gold := StandardMaterial3D.new()
	gold.albedo_color = COIN_COLOR
	gold.metallic = 0.8
	gold.roughness = 0.3
	_coin_mesh.material = gold
	EventBus.trader_visited.connect(_on_trader_visited)


## Efeitos acontecendo agora (testes).
func active_count() -> int:
	return _effects.filter(func(effect: Node3D) -> bool: return effect.visible).size()


func _on_trader_visited(island_id: int, earned: float, _spent: float) -> void:
	if earned <= 0.0:
		return
	var post := trading_post_point(island_id)
	if post.is_finite():
		play(post, earned)


## O ponto acima do entreposto da ilha, ou um vetor infinito se ela não tem.
func trading_post_point(island_id: int) -> Vector3:
	var world := _simulation.world
	for building_id: int in world.building_ids():
		var record := world.building(building_id)
		var def := _simulation.def_of(record)
		if record.island_id == island_id and def.is_trading_post:
			return world.island(island_id).rect_world(Footprint.rect(record.origin, def.size, record.rotation)) \
					+ Vector3.UP * (def.height_m + LIFT_M)
	return Vector3.INF


## Mostra o ganho em "at"; devolve false se o teto de efeitos está cheio.
func play(at: Vector3, amount: float) -> bool:
	var effect := _free_effect()
	if effect == null:
		return false
	effect.position = at
	effect.visible = true
	var label := effect.get_node(^"Amount") as Label3D
	label.text = "+" + Fmt.integer(amount)
	label.position = Vector3.UP * TEXT_START_M
	label.modulate.a = 1.0
	var coins: Array[Node3D] = []
	for child: Node in effect.get_children():
		if child is MeshInstance3D:
			coins.append(child as Node3D)
	var tween := effect.create_tween()
	tween.tween_property(label, ^"position:y", TEXT_START_M + RISE_M, DURATION_S).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(label, ^"modulate:a", 0.0, DURATION_S).set_ease(Tween.EASE_IN)
	tween.parallel().tween_method(func(t: float) -> void: _place_coins(coins, t), 0.0, 1.0, DURATION_S * 0.7)
	tween.tween_callback(func() -> void: effect.visible = false)
	return true


## As moedas em arco no instante t (0..1): cada uma vai para fora numa direção própria, sobe HOP_M e cai, girando.
static func _place_coins(coins: Array[Node3D], t: float) -> void:
	for index: int in coins.size():
		var angle := TAU * index / coins.size()
		var out := Vector3(cos(angle), 0.0, sin(angle)) * SPREAD_M * t
		coins[index].position = out + Vector3.UP * HOP_M * 4.0 * t * (1.0 - t)
		coins[index].rotation = Vector3(t * TAU * 2.0, angle, 0.0)
		coins[index].visible = t < 1.0


## Um efeito parado para reaproveitar, ou um novo até o teto; null com o teto cheio.
func _free_effect() -> Node3D:
	for effect: Node3D in _effects:
		if not effect.visible:
			return effect
	if _effects.size() >= MAX_EFFECTS:
		return null
	var effect := Node3D.new()
	effect.name = "Gain%d" % _effects.size()
	var label := Label3D.new()
	label.name = "Amount"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 96
	label.pixel_size = 0.02
	label.outline_size = 24
	label.modulate = TEXT_COLOR
	label.outline_modulate = OUTLINE_COLOR
	label.no_depth_test = true
	effect.add_child(label)
	for index: int in COINS:
		var coin := MeshInstance3D.new()
		coin.mesh = _coin_mesh
		coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		effect.add_child(coin)
	add_child(effect)
	_effects.append(effect)
	return effect
