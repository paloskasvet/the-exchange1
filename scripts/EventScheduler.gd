extends Node

const COOLDOWN := 15

var _current_day:    int = 0
var _last_event_day: int = -COOLDOWN  # allow first events to fire immediately

func _ready() -> void:
	GameState.day_advanced.connect(func(_d): _current_day += 1)

func can_fire() -> bool:
	return (_current_day - _last_event_day) >= COOLDOWN

func mark_fired() -> void:
	_last_event_day = _current_day
