class_name Cart
extends RefCounted
## A carroça de um prédio de produção. Leva a saída até o armazém e, na mesma viagem, traz a
## entrada do prédio. A carga só entra no estoque quando ela chega e descarrega na rampa.
## Anda pela rota (índices de célula da grade) com posição contínua: 2,5 = no meio entre a
## célula 2 e a 3 da rota.

enum State { HOME, OUTBOUND, QUEUED, AT_RAMP, INBOUND }

var home_id: int
var state: State = State.HOME
var warehouse_id: int = 0
## Rota da casa até o armazém; a volta percorre a mesma rota ao contrário.
var path: PackedInt32Array = PackedInt32Array()
var position: float = 0.0
## Carga atual (bem → toneladas): a saída na ida, a entrada na volta.
var cargo: Dictionary[StringName, float] = {}
## O que buscar no armazém nesta viagem (bem → toneladas desejadas).
var wanted: Dictionary[StringName, float] = {}
## Segundos que faltam na rampa.
var timer: float = 0.0
## Tick em que entrou na fila da rampa (a fila anda nessa ordem).
var queued_at: int = 0
## Parada porque a estrada da rota foi cortada.
var blocked: bool = false

# runtime: posição no tick anterior, para a apresentação interpolar
var previous_position: float = 0.0


func _init(home: int) -> void:
	home_id = home


func tons() -> float:
	var total := 0.0
	for good: StringName in cargo:
		total += cargo[good]
	return total


func is_away() -> bool:
	return state != State.HOME


func to_dict() -> Dictionary:
	return {"home": home_id, "state": state, "warehouse": warehouse_id, "path": path, "position": position,
			"cargo": cargo.duplicate(), "wanted": wanted.duplicate(), "timer": timer, "queued_at": queued_at, "blocked": blocked}


static func from_dict(data: Dictionary) -> Cart:
	var raw_home: Variant = data.get("home")
	var raw_state: Variant = data.get("state")
	var raw_warehouse: Variant = data.get("warehouse")
	var raw_path: Variant = data.get("path")
	var raw_position: Variant = data.get("position")
	var raw_cargo: Variant = data.get("cargo")
	var raw_wanted: Variant = data.get("wanted")
	var raw_timer: Variant = data.get("timer")
	var raw_queued: Variant = data.get("queued_at")
	var raw_blocked: Variant = data.get("blocked")
	if not (raw_home is int and raw_state is int and raw_warehouse is int and raw_path is PackedInt32Array \
			and raw_position is float and raw_cargo is Dictionary and raw_wanted is Dictionary and raw_timer is float \
			and raw_queued is int and raw_blocked is bool):
		return null
	var state_value: int = raw_state
	if state_value < State.HOME or state_value > State.INBOUND:
		return null
	var home: int = raw_home
	var cart := Cart.new(home)
	cart.state = state_value as State
	cart.warehouse_id = raw_warehouse
	cart.path = raw_path
	cart.position = raw_position
	cart.previous_position = cart.position
	cart.timer = raw_timer
	cart.queued_at = raw_queued
	cart.blocked = raw_blocked
	if not (_read_tons(raw_cargo, cart.cargo) and _read_tons(raw_wanted, cart.wanted)):
		return null
	return cart


static func _read_tons(raw: Variant, into: Dictionary[StringName, float]) -> bool:
	var source: Dictionary = raw
	for good: Variant in source:
		var tons: Variant = source[good]
		if not (good is StringName and tons is float):
			return false
		into[good] = tons
	return true
