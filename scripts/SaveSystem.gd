extends Node

const SAVE_PATH := "user://exchange_save.json"

signal game_saved()
signal game_loaded()
signal save_failed(reason: String)

func save() -> bool:
	var data := {
		"version":1,
		"date":[GameState.game_day,GameState.game_month,GameState.game_year],
		"total_days":GameState.total_days_passed,
		"cash":GameState.cash,
		"starting_capital":GameState.starting_capital,
		"office_level":OfficeSystem.current_level,
		"holdings":{},
		"triggered_events":NewsSystem._triggered_ids,
		"news_pool_idx":NewsSystem._pool_idx,
		"contacts_unlocked":ContactsSystem.unlocked,
		"countries_owned":CountrySystem.owned,
		"luxury_owned":LuxurySystem.owned,
		"shares_owned":ShareholdingSystem.owned_units,
		"shares_next_agm":ShareholdingSystem._next_agm_day,
		"shares_year_nw":ShareholdingSystem._year_start_nw,
		"tech_owned":TechSystem.owned,
		"achievements":AchievementSystem.unlocked,
		"mega_projects":MegaProjectSystem.states,
		"player_name":GameState.player_name,
		"company_name":GameState.company_name,
		"save_date":Time.get_date_string_from_system(),
	}
	for t in Portfolio.holdings:
		var h = Portfolio.holdings[t]
		data["holdings"][t] = {"qty":h["qty"],"avg_cost":h["avg_cost"],"total_cost":h["total_cost"]}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f: emit_signal("save_failed","Cannot write file."); return false
	f.store_string(JSON.stringify(data,"\t")); f.close()
	emit_signal("game_saved"); return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		emit_signal("save_failed","No save file found."); return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: emit_signal("save_failed","Cannot read file."); return false
	var parsed = JSON.parse_string(f.get_as_text()); f.close()
	if not parsed: emit_signal("save_failed","Save corrupted."); return false
	var d: Dictionary = parsed
	var dt: Array = d.get("date",[1,1,1990])
	GameState.game_day   = dt[0]; GameState.game_month = dt[1]; GameState.game_year  = dt[2]
	GameState.total_days_passed = d.get("total_days",0)
	GameState.cash              = d.get("cash",1_000_000.0)
	GameState.starting_capital  = d.get("starting_capital",1_000_000.0)
	OfficeSystem.current_level  = d.get("office_level",0)
	NewsSystem._triggered_ids   = d.get("triggered_events",[])
	NewsSystem._pool_idx        = d.get("news_pool_idx",0)
	ContactsSystem.unlocked     = d.get("contacts_unlocked",["fin_analyst"])
	CountrySystem.owned         = d.get("countries_owned",[])
	LuxurySystem.owned             = d.get("luxury_owned",[])
	ShareholdingSystem.owned_units    = d.get("shares_owned", 30)
	ShareholdingSystem._next_agm_day  = d.get("shares_next_agm", 365)
	ShareholdingSystem._year_start_nw = d.get("shares_year_nw", 0.0)
	ShareholdingSystem._initialized   = true
	TechSystem.owned = d.get("tech_owned", [])
	TechSystem._recalc_income()
	AchievementSystem.unlocked = d.get("achievements", [])
	MegaProjectSystem.states   = d.get("mega_projects", {})
	GameState.player_name  = d.get("player_name",  "The Investor")
	GameState.company_name = d.get("company_name", "The Exchange")
	Portfolio.holdings.clear()
	for t in d.get("holdings",{}):
		var h = d["holdings"][t]
		Portfolio.holdings[t] = {"qty":float(h["qty"]),"avg_cost":float(h["avg_cost"]),"total_cost":float(h["total_cost"])}
	emit_signal("game_loaded"); return true

func has_save() -> bool: return FileAccess.file_exists(SAVE_PATH)

func get_save_meta() -> Dictionary:
	if not has_save(): return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return {}
	var parsed = JSON.parse_string(f.get_as_text()); f.close()
	if not parsed: return {}
	return {"date":parsed.get("save_date","?"),"cash":parsed.get("cash",0.0),"year":parsed.get("date",[0,0,0])[2]}
