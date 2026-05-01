extends Node

signal project_purchased(project: Dictionary)
signal project_completed(project: Dictionary)

# income_type:
#   "daily"          — daily_income added to cash every game day
#   "mariana"        — daily cash + monthly XAU/XAG portfolio grants
#   "annual_limited" — returns price once per year for 5 years, then stops
#   "atlantis"       — daily_income (tax revenue from citizens)

const PROJECTS := [
	{
		"id":          "gibraltar_bridge",
		"icon":        "🌉",
		"lat":          35.9, "lon": -5.5,
		"name":        "Gibraltar Strait Bridge",
		"name_tr":     "Cebelitarık Boğazı Köprüsü",
		"desc":        "A 14-kilometre dual-deck suspension bridge linking Spain and Morocco. The only fixed crossing between Europe and Africa. Toll revenue from vehicles, freight and high-speed rail.",
		"desc_tr":     "İspanya ile Fas'ı birbirine bağlayan 14 kilometrelik çift katlı asma köprü. Avrupa ile Afrika arasındaki tek sabit geçiş. Araç, yük ve hızlı tren geçiş ücretlerinden gelir.",
		"price":       50_000_000_000,
		"build_days":  730,
		"income_type": "daily",
		"daily_income":200_000_000,
	},
	{
		"id":          "bering_bridge",
		"icon":        "🏗",
		"lat":          65.5, "lon": -168.0,
		"name":        "Bering Strait Continental Bridge",
		"name_tr":     "Bering Boğazı Kıtalararası Köprüsü",
		"desc":        "An 88-kilometre combined road, rail and tunnel system connecting Russia and Alaska across the Bering Strait — joining Asia and North America by land for the first time in history. Transit fees from freight, passengers and energy pipelines.",
		"desc_tr":     "Rusya ile Alaska'yı Bering Boğazı üzerinden birleştiren 88 kilometre uzunluğunda kombinasyonlu kara, demir yolu ve tünel sistemi. Asya ile Kuzey Amerika'yı tarihte ilk kez karadan birleştiriyor. Yük, yolcu ve enerji boru hatlarından geçiş ücreti geliri.",
		"price":       300_000_000_000,
		"build_days":  1825,
		"income_type": "daily",
		"daily_income":1_000_000_000,
	},
	{
		"id":          "mariana_mining",
		"icon":        "⛏",
		"lat":          11.0, "lon": 142.5,
		"name":        "Mariana Trench Deep-Sea Mining Station",
		"name_tr":     "Mariana Çukuru Derin Deniz Maden İstasyonu",
		"desc":        "Autonomous robotic platforms operating at 11,000 metres depth, extracting polymetallic nodules from the ocean floor. Output is pure gold and silver — independent of any surface supply chain, indefinitely.",
		"desc_tr":     "11.000 metre derinlikte çalışan otonom robotik platformlar, okyanus tabanından polimetalik yumrular çıkarıyor. Çıktı yalnızca altın ve gümüş — yüzeydeki herhangi bir tedarik zincirinden bağımsız, süresiz olarak.",
		"price":       150_000_000_000,
		"build_days":  1095,
		"income_type": "mariana",
		"daily_xau":   12,
		"daily_xag":   60,
	},
	{
		"id":          "transatlantic_hyperloop",
		"icon":        "🚄",
		"lat":          40.0, "lon": -35.0,
		"name":        "Trans-Atlantic Hyperloop Tunnel",
		"name_tr":     "Trans-Atlantik Hyperloop Tüneli",
		"desc":        "A vacuum-tube hyperloop system embedded in the Atlantic seabed between London and New York. Travel time: 54 minutes. Carries passengers, freight containers and autonomous vehicles at 1,200 km/h. The most expensive engineering project in human history.",
		"desc_tr":     "Londra ile New York arasında Atlantik deniz tabanına gömülü vakum tüplü hyperloop sistemi. Seyahat süresi: 54 dakika. Yolcuları, yük konteynerlerini ve otonom araçları saatte 1.200 km hızda taşıyor. İnsanlık tarihinin en pahalı mühendislik projesi.",
		"price":       500_000_000_000,
		"build_days":  2920,
		"income_type": "daily",
		"daily_income":1_500_000_000,
	},
	{
		"id":          "australia_inland_sea",
		"icon":        "🌊",
		"lat":          -25.0, "lon": 135.0,
		"name":        "Australia Inland Sea Project",
		"name_tr":     "Avustralya İç Denizi Projesi",
		"desc":        "A network of canals and controlled flooding redirecting ocean water into the geological Eromanga Basin in central Australia — creating a 500,000 km² inland sea. Transforms the continent's agriculture, rainfall and biodiversity. Returns the invested capital once per year for five years.",
		"desc_tr":     "Okyanus suyunu Orta Avustralya'daki jeolojik Eromanga Havzası'na yönlendiren kanal ve kontrollü su baskını ağı. 500.000 km² iç deniz oluşturuyor. Kıtanın tarımını, yağış düzenini ve biyoçeşitliliğini dönüştürüyor. Beş yıl boyunca yılda bir kez yatırılan sermayeyi geri öder.",
		"price":       200_000_000_000,
		"build_days":  2190,
		"income_type": "annual_limited",
		"annual_years": 5,
	},
	{
		"id":          "atlantis",
		"icon":        "🏝",
		"lat":          28.0, "lon": -38.0,
		"name":        "New Atlantis — Artificial Continent",
		"name_tr":     "Yeni Atlantis — Yapay Kıta",
		"desc":        "A 780,000 km² artificial landmass constructed in the mid-Atlantic. Named after %s. Recognised as a sovereign territory — you are automatically its head of state. Population growth generates perpetual tax revenue. The first private nation in history.",
		"desc_tr":     "Orta Atlantik'te inşa edilen 780.000 km² yapay kara kütlesi. %s adını taşıyor. Egemen toprak olarak tanınıyor — otomatik olarak devlet başkanısınız. Nüfus artışı sürekli vergi geliri sağlıyor. Tarihin ilk özel ülkesi.",
		"price":       1_000_000_000_000,
		"build_days":  3650,
		"income_type": "atlantis",
		"daily_income":3_000_000_000,
	},
]

# states[id] = {
#   "building": bool, "days_remaining": int,
#   "complete": bool, "completion_day": int,
#   "years_paid": int   (annual_limited only)
# }
var states: Dictionary = {}

func _ready() -> void:
	GameState.day_advanced.connect(_on_day)

func _on_day(_d: String) -> void:
	for pid in states:
		var s: Dictionary = states[pid]
		if s.get("complete", false):
			_apply_income(pid, s)
		elif s.get("building", false):
			s["days_remaining"] -= 1
			if s["days_remaining"] <= 0:
				s["building"] = false
				s["complete"] = true
				s["completion_day"] = GameState.total_days_passed
				s["years_paid"] = 0
				emit_signal("project_completed", _find(pid))

func _apply_income(pid: String, s: Dictionary) -> void:
	var p := _find(pid)
	if p.is_empty(): return
	match p["income_type"]:
		"daily", "atlantis":
			GameState.add_cash(float(p["daily_income"]))
		"mariana":
			Portfolio.grant("XAU", float(p.get("daily_xau", 12)))
			Portfolio.grant("XAG", float(p.get("daily_xag", 60)))
		"annual_limited":
			var yp: int = s.get("years_paid", 0)
			if yp >= p.get("annual_years", 5): return
			var days_since = GameState.total_days_passed - s.get("completion_day", 0)
			if days_since > 0 and days_since % 365 == 0:
				GameState.add_cash(float(p["price"]))
				s["years_paid"] = yp + 1

func buy(pid: String) -> bool:
	var p := _find(pid)
	if p.is_empty() or pid in states: return false
	if GameState.cash < float(p["price"]): return false
	GameState.add_cash(-float(p["price"]))
	states[pid] = {"building": true, "days_remaining": p["build_days"], "complete": false, "completion_day": 0, "years_paid": 0}
	emit_signal("project_purchased", p)
	return true

func get_state(pid: String) -> Dictionary:
	return states.get(pid, {})

func is_owned(pid: String) -> bool:
	return pid in states

func is_complete(pid: String) -> bool:
	return states.get(pid, {}).get("complete", false)

func days_remaining(pid: String) -> int:
	return states.get(pid, {}).get("days_remaining", 0)

func _find(pid: String) -> Dictionary:
	for p in PROJECTS:
		if p["id"] == pid: return p
	return {}
