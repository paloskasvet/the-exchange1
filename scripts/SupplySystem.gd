extends Node

signal supply_offer_received(offer: Dictionary)

# Market float for each asset (in billions USD - total market size)
# These are simplified but realistic relative values
const MARKET_FLOAT := {
	"APRI":  2800.0,   # big tech
	"OMNI":  1900.0,
	"PRMZ":  1600.0,
	"SFTC":   380.0,
	"ELVT":   800.0,
	"MVRS":   420.0,
	"CHPX":  1100.0,
	"SMTC":   120.0,   # finance
	"CNBN":    90.0,
	"BLKP":   100.0,
	"MSTL":    60.0,
	"ATLS":    55.0,   # energy
	"CRWN":    48.0,
	"PCOL":    32.0,
	"XAU":   12000.0,  # gold market total (oz * price)
	"XAG":    500.0,   # silver
	"WTI":   3000.0,   # oil futures market
	"NTG":    800.0,
	"GIDX":  5500.0,
	"TIDX":  4200.0,
}

var _offer_cooldowns: Dictionary = {}  # ticker -> days until next offer

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	# Decay cooldowns
	for k in _offer_cooldowns.keys():
		_offer_cooldowns[k] -= 1
		if _offer_cooldowns[k] <= 0: _offer_cooldowns.erase(k)
	# Check if any asset is above 50%
	for ticker in MARKET_FLOAT:
		if _offer_cooldowns.has(ticker): continue
		var pct := get_ownership_pct(ticker)
		if pct >= 50.0 and Portfolio.holdings.has(ticker):
			# Random chance each day to trigger an offer
			if randf() < 0.08:
				_trigger_offer(ticker, pct)

func get_ownership_pct(ticker: String) -> float:
	if not Portfolio.holdings.has(ticker): return 0.0
	var h = Portfolio.holdings[ticker]
	var market_float = MARKET_FLOAT.get(ticker, 1000.0)
	var cur_price    = MarketEngine.get_price(ticker)
	if cur_price <= 0 or market_float <= 0: return 0.0
	# Player value in billions
	var player_val_b = (h["qty"] * cur_price) / 1_000_000_000.0
	return clampf(player_val_b / market_float * 100.0, 0.0, 100.0)

func get_ownership_pct_str(ticker: String) -> String:
	var pct := get_ownership_pct(ticker)
	if pct < 0.01: return ""
	if pct >= 50.0: return "⚠ %.1f%% of float" % pct
	if pct >= 10.0: return "%.1f%% of float" % pct
	if pct >= 1.0:  return "%.2f%% of float" % pct
	return "%.3f%% of float" % pct

# Countries that might want to buy your assets
const COUNTRY_BUYERS := [
	{"name":"Norway","title":"Norwegian Sovereign Wealth Fund","portrait":"🏔"},
	{"name":"Saudi Arabia","title":"Saudi PIF","portrait":"🛢"},
	{"name":"China","title":"Chinese State Investment","portrait":"🏛"},
	{"name":"Japan","title":"Bank of Japan","portrait":"🗾"},
	{"name":"UAE","title":"Abu Dhabi Investment Authority","portrait":"🌴"},
	{"name":"Singapore","title":"GIC Private Limited","portrait":"🏙"},
	{"name":"Kuwait","title":"Kuwait Investment Authority","portrait":"⛽"},
	{"name":"Qatar","title":"Qatar Investment Authority","portrait":"🏗"},
]

func _trigger_offer(ticker: String, pct: float) -> void:
	_offer_cooldowns[ticker] = 15 + randi() % 20  # cooldown 15-35 days
	var buyer = COUNTRY_BUYERS[randi() % COUNTRY_BUYERS.size()]
	var h     = Portfolio.holdings[ticker]
	var price = MarketEngine.get_price(ticker)
	# Offer a premium: 5-20% above market
	var premium = 1.05 + randf() * 0.15
	var qty_offer = h["qty"] * (0.20 + randf() * 0.35)  # buy 20-55% of position
	var offer_price_per = price * premium
	var total_offer = qty_offer * offer_price_per
	
	var offer := {
		"type":        "country_buy",
		"buyer_name":  buyer["name"],
		"buyer_title": buyer["title"],
		"buyer_portrait": buyer["portrait"],
		"ticker":      ticker,
		"qty":         round(qty_offer),
		"price_per":   offer_price_per,
		"total":       total_offer,
		"premium_pct": (premium - 1.0) * 100.0,
		"pct_owned":   pct,
		"id":          randi(),
	}
	emit_signal("supply_offer_received", offer)

func accept_offer(offer: Dictionary) -> bool:
	var ticker = offer["ticker"]
	if not Portfolio.holdings.has(ticker): return false
	var h = Portfolio.holdings[ticker]
	var qty := minf(float(offer["qty"]), h["qty"])
	if qty <= 0: return false
	# Sell at offer price (bypass normal sell to use custom price)
	var proceeds := qty * float(offer["price_per"])
	GameState.add_cash(proceeds)
	h["qty"]       -= qty
	h["total_cost"] = h["avg_cost"] * h["qty"]
	if h["qty"] < 0.0001: Portfolio.holdings.erase(ticker)
	return true
