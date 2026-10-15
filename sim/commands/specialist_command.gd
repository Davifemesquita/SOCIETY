class_name SpecialistCommand
extends Command
## Gesto do jogador com os especialistas (Fase 11): contratar da oferta da volta (paga hire_cost,
## até max_specialists), designar a um prédio de produção do grupo dele (um por prédio; já posto
## muda de prédio), retirar do posto e dispensar (sem devolução). A recusa diz o motivo.

enum Action { HIRE, ASSIGN, UNASSIGN, DISMISS }

const NO_OFFER := &"REASON_NO_SPECIALIST_OFFER"
const NO_SPECIALIST := &"REASON_NO_SPECIALIST"
const LIMIT := &"REASON_SPECIALIST_LIMIT"
const WRONG_BUILDING := &"REASON_SPECIALIST_WRONG_BUILDING"
const SLOT_TAKEN := &"REASON_SPECIALIST_SLOT_TAKEN"

var action: Action
## HIRE: a definição da oferta; os outros: o id do contratado.
var def_id: StringName
var specialist_id: int
var building_id: int


static func hire(def: StringName) -> SpecialistCommand:
	var command := SpecialistCommand.new()
	command.action = Action.HIRE
	command.def_id = def
	return command


static func assign(id: int, building: int) -> SpecialistCommand:
	var command := SpecialistCommand.new()
	command.action = Action.ASSIGN
	command.specialist_id = id
	command.building_id = building
	return command


static func unassign(id: int) -> SpecialistCommand:
	var command := SpecialistCommand.new()
	command.action = Action.UNASSIGN
	command.specialist_id = id
	return command


static func dismiss(id: int) -> SpecialistCommand:
	var command := SpecialistCommand.new()
	command.action = Action.DISMISS
	command.specialist_id = id
	return command


func execute(context: CommandContext) -> CommandResult:
	var reason := check(context.world, context.data, context.config, self, context.free_build)
	if reason != &"":
		return CommandResult.refused(reason)
	var world := context.world
	var state := world.specialists_state
	var result := CommandResult.new()
	result.specialists_changed = true
	var item := state.specialist(specialist_id)
	match action:
		Action.HIRE:
			var def := context.data.specialist(def_id)
			if not context.free_build:
				world.money -= def.hire_cost
			state.offers.erase(def_id)
			item = Specialist.new()
			item.id = state.next_id
			item.def_id = def_id
			item.def = def
			state.next_id += 1
			state.specialists.append(item)
			result.created_id = item.id
		Action.ASSIGN:
			if item.building_id != 0:
				result.changed.append(item.building_id)
			item.building_id = building_id
			item.cycles = 0
			result.changed.append(building_id)
		Action.UNASSIGN:
			result.changed.append(item.building_id)
			item.building_id = 0
			item.cycles = 0
		Action.DISMISS:
			if item.building_id != 0:
				result.changed.append(item.building_id)
			state.specialists.erase(item)
	return result


## Motivo da recusa do gesto, ou &"" (a janela desliga o botão por aqui).
static func check(world: WorldState, data: GameData, config: GameConfig, command: SpecialistCommand, free: bool = false) -> StringName:
	var state := world.specialists_state
	if command.action == Action.HIRE:
		if not state.offers.has(command.def_id) or data.specialist(command.def_id) == null:
			return NO_OFFER
		if state.specialists.size() >= config.max_specialists:
			return LIMIT
		if not free and world.money - data.specialist(command.def_id).hire_cost < config.min_balance_for(world.difficulty):
			return PlacementRules.NO_MONEY
		return &""
	var item := state.specialist(command.specialist_id)
	if item == null:
		return NO_SPECIALIST
	match command.action:
		Action.ASSIGN:
			var record := world.building(command.building_id)
			if record == null or not item.def.covers(data.building(record.def_id)):
				return WRONG_BUILDING
			var holder := state.at(command.building_id)
			if holder != null and holder != item:
				return SLOT_TAKEN
		Action.UNASSIGN:
			if item.building_id == 0:
				return NO_SPECIALIST
	return &""
