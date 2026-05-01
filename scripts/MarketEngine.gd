extends Node

signal prices_updated()

var assets:        Dictionary = {}
var price_history: Dictionary = {}
const HISTORY_LEN := 180

const ASSET_DEFS := [
	{"ticker":"APRI","name":"Apricot Technologies",  "sector":"Tech",     "base":148.0,"vol":0.022,"supply":15_200_000_000},
	{"ticker":"OMNI","name":"OmniSearch Corp",        "sector":"Tech",     "base":112.0,"vol":0.019,"supply":12_480_000_000},
	{"ticker":"PRMZ","name":"Primezon Inc",           "sector":"Tech",     "base": 88.0,"vol":0.021,"supply":10_250_000_000},
	{"ticker":"SFTC","name":"SoftCore Systems",       "sector":"Tech",     "base": 44.0,"vol":0.017,"supply": 7_430_000_000},
	{"ticker":"ELVT","name":"Electrovolt Motors",     "sector":"Tech",     "base": 72.0,"vol":0.038,"supply": 3_180_000_000},
	{"ticker":"MVRS","name":"Metaverse Corp",         "sector":"Tech",     "base": 52.0,"vol":0.030,"supply": 2_560_000_000},
	{"ticker":"CHPX","name":"Chipex Semiconductor",   "sector":"Tech",     "base": 90.0,"vol":0.028,"supply":24_400_000_000},
	{"ticker":"SMTC","name":"Summit Capital Group",   "sector":"Finance",  "base":224.0,"vol":0.014,"supply":   340_000_000},
	{"ticker":"CNBN","name":"Continental Banking",    "sector":"Finance",  "base":138.0,"vol":0.013,"supply": 2_020_000_000},
	{"ticker":"BLKP","name":"BlackPeak Investments",  "sector":"Finance",  "base":498.0,"vol":0.012,"supply":     1_450_000},
	{"ticker":"MSTL","name":"Morgan Sterling",        "sector":"Finance",  "base": 84.0,"vol":0.015,"supply": 1_560_000_000},
	{"ticker":"ATLS","name":"Atlas Petroleum Corp",   "sector":"Energy",   "base": 58.0,"vol":0.018,"supply": 4_070_000_000},
	{"ticker":"CRWN","name":"Crown Energy Ltd",       "sector":"Energy",   "base": 53.0,"vol":0.017,"supply": 2_010_000_000},
	{"ticker":"PCOL","name":"Pacific Oil Corp",       "sector":"Energy",   "base": 34.0,"vol":0.020,"supply": 1_490_000_000},
	{"ticker":"XAU", "name":"Gold (oz)",              "sector":"Commodity","base":385.0,"vol":0.010,"supply": 6_400_000_000},
	{"ticker":"XAG", "name":"Silver (oz)",            "sector":"Commodity","base":  6.8,"vol":0.015,"supply":55_000_000_000},
	{"ticker":"WTI", "name":"Crude Oil (bbl)",        "sector":"Commodity","base": 26.0,"vol":0.022,"supply":36_500_000_000},
	{"ticker":"NTG", "name":"Natural Gas (mmBtu)",    "sector":"Commodity","base":  2.4,"vol":0.028,"supply": 4_000_000_000_000},
	{"ticker":"GIDX","name":"Global Index 500",       "sector":"Index",    "base":448.0,"vol":0.011,"supply": 1_000_000_000_000},
	{"ticker":"TIDX","name":"Tech Index 100",         "sector":"Index",    "base":1180.0,"vol":0.016,"supply":   500_000_000_000},
]

var _event_impacts:       Dictionary = {}
var _manipulation_boosts: Dictionary = {}

func _ready() -> void:
	randomize()
	for def in ASSET_DEFS:
		var t = def["ticker"]
		assets[t] = def.duplicate()
		assets[t]["price"]      = def["base"] * randf_range(0.92, 1.08)
		assets[t]["prev_price"] = assets[t]["price"]
		price_history[t] = []
		var p = assets[t]["price"]
		for _i in HISTORY_LEN:
			p = maxf(p * (1.0 + randf_range(-def["vol"], def["vol"])), 0.01)
			price_history[t].append(p)
		assets[t]["price"]      = price_history[t][-1]
		assets[t]["prev_price"] = price_history[t][-2]

func simulate_days(n: int) -> void:
	for _i in range(n):
		_sim_one()
	emit_signal("prices_updated")

func _sim_one() -> void:
	for ticker in assets:
		var a = assets[ticker]
		a["prev_price"] = a["price"]
		var shock      = randf_range(-a["vol"], a["vol"])
		var reversion  = (a["base"] - a["price"]) * 0.003
		var ev         = _event_impacts.get(ticker, 0.0)
		var manip      = _manipulation_boosts.get(ticker, 0.0)
		a["price"] = maxf(a["price"] * (1.0 + 0.00008 + shock + reversion + ev + manip), 0.01)
		price_history[ticker].append(a["price"])
		if price_history[ticker].size() > HISTORY_LEN:
			price_history[ticker].pop_front()
	for t in _event_impacts.keys():
		_event_impacts[t] *= 0.90
		if absf(_event_impacts[t]) < 0.00005: _event_impacts.erase(t)
	for t in _manipulation_boosts.keys():
		_manipulation_boosts[t] *= 0.80
		if absf(_manipulation_boosts[t]) < 0.00005: _manipulation_boosts.erase(t)

func get_price(ticker: String) -> float:
	return assets.get(ticker, {}).get("price", 0.0)

func get_supply(ticker: String) -> int:
	return assets.get(ticker, {}).get("supply", 0)

func get_change_pct(ticker: String) -> float:
	var a = assets.get(ticker, {})
	if a.is_empty() or a.get("prev_price", 0.0) == 0.0: return 0.0
	return (a["price"] - a["prev_price"]) / a["prev_price"] * 100.0

func apply_event_impact(ticker: String, impact: float) -> void:
	_event_impacts[ticker] = _event_impacts.get(ticker, 0.0) + impact

func apply_sector_impact(sector: String, impact: float) -> void:
	for t in assets:
		if assets[t]["sector"] == sector: apply_event_impact(t, impact)

func apply_global_impact(impact: float) -> void:
	for t in assets: apply_event_impact(t, impact)

func apply_manipulation(ticker: String, boost: float) -> void:
	_manipulation_boosts[ticker] = _manipulation_boosts.get(ticker, 0.0) + boost

func get_all_tickers() -> Array: return assets.keys()
func get_asset_info(ticker: String) -> Dictionary: return assets.get(ticker, {})
