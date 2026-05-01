extends Node

signal office_upgraded(new_level: int)

var current_level: int = 0

const LEVELS := [
	{"id":0,"name":"Basement","desc":"Damp walls. A secondhand laptop. This is where it begins.","cost":0.0,"unlock":0.0,"screens":1},
	{"id":1,"name":"Small Office","desc":"Street-level. Two monitors. The city starts to make sense.","cost":50_000.0,"unlock":200_000.0,"screens":2},
	{"id":2,"name":"Trading Floor","desc":"Four screens. City view. People are calling you now.","cost":500_000.0,"unlock":1_000_000.0,"screens":4},
	{"id":3,"name":"Penthouse","desc":"Floor-to-ceiling glass. The whole city below you. Six screens.","cost":5_000_000.0,"unlock":10_000_000.0,"screens":6},
]

func can_upgrade() -> bool:
	if current_level >= LEVELS.size() - 1: return false
	return GameState.get_net_worth() >= LEVELS[current_level + 1]["unlock"]

func get_upgrade_cost() -> float:
	if current_level >= LEVELS.size() - 1: return 0.0
	return LEVELS[current_level + 1]["cost"]

func upgrade() -> bool:
	if not can_upgrade(): return false
	var cost := get_upgrade_cost()
	if GameState.cash < cost: return false
	GameState.add_cash(-cost)
	current_level += 1
	emit_signal("office_upgraded", current_level)
	return true

func get_current() -> Dictionary: return LEVELS[current_level]
func get_next() -> Dictionary:
	if current_level >= LEVELS.size() - 1: return {}
	return LEVELS[current_level + 1]
