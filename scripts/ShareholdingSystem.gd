extends Node

signal agm_called(profitable: bool, nw: float, prev_nw: float)
signal share_purchased(new_owned: int)
signal share_sold(new_owned: int)

const TOTAL_UNITS   := 100           # 100 units = 100% ownership
const UNIT_VALUE    := 10_000_000.0  # 1 unit = 1% of $1B company = $10M
const INITIAL_OWNED := 30            # player starts with 30%

var owned_units:     int   = INITIAL_OWNED
var _next_agm_day:   int   = 365
var _year_start_nw:  float = 0.0
var _initialized:    bool  = false

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)
	call_deferred("_init_nw")

func _init_nw() -> void:
	if not _initialized:
		_year_start_nw = GameState.get_net_worth()
		_initialized   = true

func _on_day(_d: String) -> void:
	if GameState.total_days_passed >= _next_agm_day:
		_fire_agm()

func _fire_agm() -> void:
	if owned_units >= TOTAL_UNITS:
		_next_agm_day = 9_999_999
		return
	var nw         := GameState.get_net_worth()
	var profitable := nw > _year_start_nw
	var prev        := _year_start_nw
	_year_start_nw  = nw
	_next_agm_day  += 1825 if owned_units > 51 else 365
	emit_signal("agm_called", profitable, nw, prev)

func buy_units(n: int) -> bool:
	if n <= 0 or owned_units + n > TOTAL_UNITS: return false
	var cost := float(n) * UNIT_VALUE
	if GameState.cash < cost: return false
	GameState.add_cash(-cost)
	owned_units += n
	emit_signal("share_purchased", owned_units)
	return true

func sell_units(n: int) -> bool:
	if n <= 0 or owned_units - n < 1: return false   # must keep at least 1 unit
	var proceeds := float(n) * UNIT_VALUE
	GameState.add_cash(proceeds)
	owned_units -= n
	emit_signal("share_sold", owned_units)
	return true

func get_ownership_pct() -> float:
	return float(owned_units) / float(TOTAL_UNITS) * 100.0

func get_total_value() -> float:
	return float(owned_units) * UNIT_VALUE

func days_to_next_agm() -> int:
	if owned_units >= TOTAL_UNITS: return -1
	return maxi(0, _next_agm_day - GameState.total_days_passed)

func agm_interval_years() -> int:
	return 5 if owned_units > 51 else 1
