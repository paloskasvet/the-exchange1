extends Node

signal day_advanced(date_str: String)
signal cash_changed(new_cash: float)
signal influence_changed(level: int)

var game_day:   int   = 24
var game_month: int   = 10
var game_year:  int   = 1929
var paused:     bool  = false
var total_days_passed: int = 0

var player_name:      String = "The Investor"
var company_name:     String = "The Exchange"
var cash:             float = 1_000_000_000.0
var starting_capital: float = 1_000_000_000.0
var influence_level:  int   = 0

const MONTHS := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

var _auto_timer: float = 0.0
const AUTO_INTERVAL := 1.0

func _process(delta: float) -> void:
	if paused: return
	_auto_timer += delta
	if _auto_timer >= AUTO_INTERVAL:
		_auto_timer = 0.0
		_tick()

func _tick() -> void:
	game_day += 1
	total_days_passed += 1
	if game_day > _dim(game_month, game_year):
		game_day = 1
		game_month += 1
		if game_month > 12:
			game_month = 1
			game_year += 1
	MarketEngine.simulate_days(1)
	emit_signal("day_advanced", get_date_string())
	_update_influence()

func advance_days(n: int) -> void:
	for _i in range(n):
		_tick()

func _dim(m: int, y: int) -> int:
	if m in [4,6,9,11]: return 30
	if m == 2: return 29 if (y % 4 == 0) else 28
	return 31

func get_date_string() -> String:
	return "%s %d, %d" % [MONTHS[game_month - 1], game_day, game_year]

func add_cash(amount: float) -> void:
	cash += amount
	emit_signal("cash_changed", cash)

func get_net_worth() -> float:
	return cash + Portfolio.get_total_value()

func toggle_pause() -> void:
	paused = !paused

func _update_influence() -> void:
	var nw := get_net_worth()
	var prev := influence_level
	if   nw >= 50_000_000: influence_level = 5
	elif nw >= 10_000_000: influence_level = 4
	elif nw >=  1_000_000: influence_level = 3
	elif nw >=    500_000: influence_level = 2
	elif nw >=    200_000: influence_level = 1
	else:                  influence_level = 0
	if influence_level != prev:
		emit_signal("influence_changed", influence_level)
