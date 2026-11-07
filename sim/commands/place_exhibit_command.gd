class_name PlaceExhibitCommand
extends Command
## Peça de coleção (Fase 67) num zoológico ou museu: compra a peça (price moedas) e põe no prédio dado; a já comprada e
## guardada (o prédio dela foi demolido) vai de graça. Recusa prédio que não expõe ou de outro tipo, prédio cheio, peça
## já posta, bloqueada pelo marco e sem dinheiro.

const NOT_A_HALL := &"REASON_NOT_EXHIBIT_HALL"
const HALL_FULL := &"REASON_EXHIBIT_HALL_FULL"
const ALREADY_SHOWN := &"REASON_EXHIBIT_SHOWN"
const LOCKED := &"REASON_EXHIBIT_LOCKED"

var exhibit_id: StringName
var building_id: int


func _init(exhibit: StringName, building: int) -> void:
	exhibit_id = exhibit
	building_id = building


func execute(context: CommandContext) -> CommandResult:
	var reason := check(context.world, context.data, exhibit_id, building_id, context.free_build)
	if reason != &"":
		return CommandResult.refused(reason)
	var state := context.world.exhibits_state
	if not state.owns(exhibit_id) and not context.free_build:
		context.world.money -= context.data.exhibit(exhibit_id).price
	state.placed[exhibit_id] = building_id
	var result := CommandResult.new()
	result.island_id = context.world.building(building_id).island_id
	result.changed.append(building_id)
	return result


## O motivo da recusa (vazio se dá): o painel desliga o botão com ele.
static func check(world: WorldState, data: GameData, exhibit: StringName, building: int, free_build: bool = false) -> StringName:
	var record := world.building(building)
	var def := data.exhibit(exhibit)
	if record == null or def == null or not data.building(record.def_id).is_exhibit_hall():
		return NOT_A_HALL
	var hall := data.building(record.def_id)
	if hall.exhibit_kind != def.kind:
		return NOT_A_HALL
	var state := world.exhibits_state
	if state.placed.get(exhibit, 0) != 0:
		return ALREADY_SHOWN
	if state.in_building(building, data).size() >= hall.exhibit_slots:
		return HALL_FULL
	if state.owns(exhibit) or free_build:
		return &""
	if def.after_milestone > world.milestones_reached:
		return LOCKED
	if world.money < def.price:
		return PlacementRules.NO_MONEY
	return &""
