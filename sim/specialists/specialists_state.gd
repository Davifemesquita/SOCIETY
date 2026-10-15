class_name SpecialistsState
extends RefCounted
## Especialistas da partida (Fase 11), no save: os contratados e a oferta da volta atual do
## comerciante. A oferta é sorteada pela semente e pelo número da volta (SpecialistSystem) e guardada
## como lista de definições: contratar tira da lista, e a volta seguinte traz outra.

var specialists: Array[Specialist] = []
var next_id: int = 1
## Volta do comerciante a que a oferta pertence (-1 = nenhuma ainda).
var offer_tour: int = -1
var offers: Array[StringName] = []


func specialist(specialist_id: int) -> Specialist:
	for item: Specialist in specialists:
		if item.id == specialist_id:
			return item
	return null


## O especialista posto no prédio, ou null.
func at(building_id: int) -> Specialist:
	if building_id == 0:
		return null
	for item: Specialist in specialists:
		if item.building_id == building_id:
			return item
	return null


## Contratados sem posto que servem ao prédio, em ordem de id.
func free_for(def: BuildingDef) -> Array[Specialist]:
	var list: Array[Specialist] = []
	for item: Specialist in specialists:
		if item.building_id == 0 and item.def.covers(def):
			list.append(item)
	return list


func unassigned_count() -> int:
	var count := 0
	for item: Specialist in specialists:
		if item.building_id == 0:
			count += 1
	return count


## Salários de todos os contratados, em moedas por minuto.
func salaries_per_min() -> float:
	var total := 0.0
	for item: Specialist in specialists:
		total += item.def.salary_per_min
	return total


## Tira do posto quem estava no prédio (demolido); devolve se havia alguém.
func release(building_id: int) -> bool:
	var item := at(building_id)
	if item == null:
		return false
	item.building_id = 0
	item.cycles = 0
	return true


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for item: Specialist in specialists:
		list.append(item.to_dict())
	return {"specialists": list, "next_id": next_id, "offer_tour": offer_tour, "offers": offers.duplicate()}


static func from_dict(data: Dictionary, game_data: GameData) -> SpecialistsState:
	var raw_list: Variant = data.get("specialists")
	var raw_next: Variant = data.get("next_id")
	var raw_tour: Variant = data.get("offer_tour")
	var raw_offers: Variant = data.get("offers")
	if not (raw_list is Array and raw_next is int and raw_tour is int and raw_offers is Array):
		return null
	var state := SpecialistsState.new()
	state.next_id = raw_next
	state.offer_tour = raw_tour
	if state.next_id < 1 or state.offer_tour < -1:
		return null
	var offer_list: Array = raw_offers
	for raw: Variant in offer_list:
		if not raw is StringName:
			return null
		var def_id: StringName = raw
		if game_data.specialist(def_id) == null:
			return null
		state.offers.append(def_id)
	var list: Array = raw_list
	for raw: Variant in list:
		if not raw is Dictionary:
			return null
		var item_data: Dictionary = raw
		var item := Specialist.from_dict(item_data, game_data)
		if item == null or item.id >= state.next_id or state.specialist(item.id) != null or state.at(item.building_id) != null:
			return null
		state.specialists.append(item)
	return state
