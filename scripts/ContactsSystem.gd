extends Node

signal contact_unlocked(contact: Dictionary)
signal manipulation_executed(action: Dictionary)
signal action_failed(reason: String)

var unlocked:         Array      = ["fin_analyst"]
var cooldowns:        Dictionary = {}
var _pending_actions: Array      = []   # [{days_left, action}]

const CONTACTS := [
	{"id":"fin_analyst","name":"Viktor Hane","title":"Senior Analyst, Morgan Sterling",
	 "portrait":"👔","unlock_level":1,"unlock_cost":0.0,
	 "bio":"Your first contact. Former quant. Free — figure out how this works.",
	 "actions":[
		{"id":"tip_tech",   "label":"Tech sector intel",   "cost":2_000.0,  "effect":"sector","sector":"Tech",   "mag":0.018,"cd":7},
		{"id":"tip_finance","label":"Banking sector intel", "cost":2_000.0,  "effect":"sector","sector":"Finance","mag":0.014,"cd":7},
	]},
	{"id":"energy_ceo","name":"Raymond Okafor","title":"CEO, Crown Energy Ltd",
	 "portrait":"🛢","unlock_level":2,"unlock_cost":25_000.0,
	 "bio":"Controls 3% of global refining capacity. Owes you nothing — yet.",
	 "actions":[
		{"id":"supply_rumor","label":"Plant supply disruption rumor","cost":15_000.0,"effect":"ticker","ticker":"WTI","mag":0.06,"cd":14},
		{"id":"opec_hint",   "label":"Obtain OPEC advance",          "cost":20_000.0,"effect":"sector","sector":"Energy","mag":0.04,"cd":21},
	]},
	{"id":"tech_lobbyist","name":"Priya Nair","title":"D.C. Lobbyist, Silicon Valley",
	 "portrait":"💻","unlock_level":2,"unlock_cost":30_000.0,
	 "bio":"Has the ear of six senators. Regulation is her game.",
	 "actions":[
		{"id":"antitrust_kill","label":"Kill antitrust probe (APRI)","cost":20_000.0,"effect":"ticker","ticker":"APRI","mag":0.04,"cd":21},
		{"id":"antitrust_aim", "label":"Direct antitrust at sector", "cost":25_000.0,"effect":"sector","sector":"Tech","mag":-0.04,"cd":30},
	]},
	{"id":"eu_diplomat","name":"Elsa Bergström","title":"EU Trade Ambassador",
	 "portrait":"🌍","unlock_level":3,"unlock_cost":100_000.0,
	 "bio":"Controls tariff decisions affecting $800B in annual trade.",
	 "actions":[
		{"id":"trade_deal","label":"Leak favorable trade deal",        "cost":40_000.0,"effect":"global","mag":0.02,"cd":21},
		{"id":"eu_fine",   "label":"Direct data fine at APRI",         "cost":50_000.0,"effect":"ticker","ticker":"APRI","mag":-0.06,"cd":30},
	]},
	{"id":"central_banker","name":"Dr. Kwame Asante","title":"Deputy Governor, Global Reserve Bank",
	 "portrait":"🏦","unlock_level":4,"unlock_cost":500_000.0,
	 "bio":"Moves $12 trillion with a sentence.",
	 "actions":[
		{"id":"rate_hint", "label":"Obtain rate decision advance","cost":200_000.0,"effect":"global","mag":0.03,"cd":30},
		{"id":"qe_signal", "label":"Signal quantitative easing",  "cost":300_000.0,"effect":"global","mag":0.04,"cd":45},
		{"id":"gold_policy","label":"Influence gold reserve policy","cost":250_000.0,"effect":"ticker","ticker":"XAU","mag":0.07,"cd":45},
	]},
	{"id":"shadow_broker","name":"[ REDACTED ]","title":"Dark Pool Operator",
	 "portrait":"👁","unlock_level":5,"unlock_cost":2_000_000.0,
	 "bio":"Identity unverifiable. Two currency collapses, one government. You did not find this contact.",
	 "actions":[
		{"id":"short_squeeze","label":"Engineer short squeeze (APRI)","cost":500_000.0,  "effect":"ticker","ticker":"APRI","mag":0.14,"cd":45},
		{"id":"global_crash", "label":"Coordinate global sell-off",   "cost":1_000_000.0,"effect":"global","mag":-0.08,"cd":90},
		{"id":"silver_corner","label":"Corner the silver market",     "cost":600_000.0,  "effect":"ticker","ticker":"XAG","mag":0.18,"cd":60},
	]},
]

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	for k in cooldowns.keys():
		cooldowns[k] -= 1
		if cooldowns[k] <= 0: cooldowns.erase(k)
	var still: Array = []
	for p in _pending_actions:
		p["days_left"] -= 1
		if p["days_left"] <= 0:
			_apply_action(p["action"])
		else:
			still.append(p)
	_pending_actions = still

func unlock_contact(contact_id: String) -> bool:
	var c := _find(contact_id)
	if not c or contact_id in unlocked: return false
	if GameState.influence_level < c["unlock_level"]:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_INF_LVL") % c["unlock_level"]); return false
	if GameState.cash < c["unlock_cost"]:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_FUNDS")); return false
	GameState.add_cash(-c["unlock_cost"]); unlocked.append(contact_id)
	emit_signal("contact_unlocked", c); return true

func execute_action(contact_id: String, action_id: String) -> bool:
	if contact_id not in unlocked:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_NOT_UNLOCKED")); return false
	var c := _find(contact_id)
	if not c: return false
	var action: Dictionary
	for a in c["actions"]: if a["id"] == action_id: action = a
	if action.is_empty(): return false
	if action_id in cooldowns:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_COOLDOWN") % cooldowns[action_id]); return false
	var actual_cost := _apply_cost_bonus(action["cost"])
	if GameState.cash < actual_cost:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_FUNDS")); return false
	GameState.add_cash(-actual_cost)
	cooldowns[action_id] = action["cd"]
	var boosted := _apply_effect_bonus(action)
	_queue_action(boosted)
	emit_signal("manipulation_executed", boosted); return true

func execute_country_action(action: Dictionary, cooldown_key: String) -> bool:
	if cooldowns.get(cooldown_key, 0) > 0:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_ON_COOLDOWN")); return false
	var actual_cost := _apply_cost_bonus(action["cost"])
	if GameState.cash < actual_cost:
		emit_signal("action_failed", LocaleSystem.get_tr("ERR_FUNDS")); return false
	GameState.add_cash(-actual_cost)
	cooldowns[cooldown_key] = action["cd"]
	var boosted := _apply_effect_bonus(action)
	_queue_action(boosted)
	emit_signal("manipulation_executed", boosted); return true

func _apply_cost_bonus(base_cost: float) -> float:
	if OfficeSystem.current_level >= 1:
		return base_cost * 0.5
	return base_cost

func _apply_effect_bonus(action: Dictionary) -> Dictionary:
	var out := action.duplicate()
	if OfficeSystem.current_level >= 2:
		out["mag"] = out["mag"] * 1.5
	return out

func _queue_action(action: Dictionary) -> void:
	var delay := randi_range(10, 21)
	_pending_actions.append({"days_left": delay, "action": action})

func _apply_action(action: Dictionary) -> void:
	match action.get("effect",""):
		"ticker": MarketEngine.apply_manipulation(action["ticker"], action["mag"])
		"sector": MarketEngine.apply_sector_impact(action["sector"], action["mag"])
		"global": MarketEngine.apply_global_impact(action["mag"])

func get_available_contacts() -> Array:
	var out := []
	for c in CONTACTS:
		if GameState.influence_level >= c["unlock_level"]: out.append(c)
	return out

func is_unlocked(cid: String) -> bool: return cid in unlocked
func get_cooldown(aid: String) -> int:  return cooldowns.get(aid, 0)
func _find(cid: String) -> Dictionary:
	for c in CONTACTS: if c["id"] == cid: return c
	return {}
