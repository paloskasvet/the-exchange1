## BuildingSystem.gd
## Autoload olarak ekle:
##   Project → Project Settings → Autoload
##   Path: res://icons/buildings/BuildingSystem.gd
##   Name: BuildingSystem

extends Node

const BUILDINGS := [
	{
		"id":      "nyse",
		"name":    "Wall Street Borsa Binası",
		"loc":     "New York, ABD",
		"lon":     -74.0,
		"lat":     40.7,
		"dw":      80.0,
		"dh":      55.0,
		"phase":   0.0,
		"price":   420_000_000,
		"effect":  "Finance sektörü volatilitesi +15%",
		"country": "usa",
	},
	{
		"id":      "shard",
		"name":    "The Shard",
		"loc":     "Londra, İngiltere",
		"lon":     -0.09,
		"lat":     51.5,
		"dw":      36.0,
		"dh":      107.0,
		"phase":   1.1,
		"price":   380_000_000,
		"effect":  "Finance sektörü bilgi akışı +8%",
		"country": "gbr",
	},
	{
		"id":      "hamburg",
		"name":    "Hamburg Limanı",
		"loc":     "Hamburg, Almanya",
		"lon":     10.0,
		"lat":     53.55,
		"dw":      66.0,
		"dh":      82.0,
		"phase":   0.5,
		"price":   290_000_000,
		"effect":  "Global ticaret akışı +10%",
		"country": "deu",
	},
	{
		"id":      "suez",
		"name":    "Giza Piramitleri",
		"loc":     "Mısır",
		"lon":     32.3,
		"lat":     30.5,
		"dw":      66.0,
		"dh":      66.0,
		"phase":   1.7,
		"price":   650_000_000,
		"effect":  "WTI +12% | Kuzey Afrika kontrolü",
		"country": "egy",
	},
	{
		"id":      "tokyo",
		"name":    "Tokyo Skytree",
		"loc":     "Tokyo, Japonya",
		"lon":     139.8,
		"lat":     35.7,
		"dw":      44.0,
		"dh":      112.0,
		"phase":   2.2,
		"price":   340_000_000,
		"effect":  "Tech sektörü +6% | Piyasa gecikmesi −20%",
		"country": "jpn",
	},
	{
		"id":      "panama",
		"name":    "Panama Konteyner Filosu",
		"loc":     "Panama",
		"lon":     -79.9,
		"lat":     9.1,
		"dw":      84.0,
		"dh":      55.0,
		"phase":   0.8,
		"price":   480_000_000,
		"effect":  "WTI +8% | Global navlun hızı +10%",
		"country": "pan",
	},
]

# Satın alınan yapılar
var owned: Array[String] = []

var _cache: Dictionary = {}

func _ready() -> void:
	_preload_textures()

func _preload_textures() -> void:
	for b in BUILDINGS:
		var path = "res://icons/buildings/%s.svg" % b["id"]
		if ResourceLoader.exists(path):
			_cache[b["id"]] = load(path)
		else:
			push_warning("BuildingSystem: %s bulunamadı → %s" % [b["id"], path])

func get_texture(id: String) -> Texture2D:
	return _cache.get(id, null)

func is_owned(id: String) -> bool:
	return id in owned

func buy(id: String) -> bool:
	var b := get_building(id)
	if b.is_empty(): return false
	if is_owned(id):  return false
	var cost: float = float(b["price"])
	if GameState.cash < cost:
		return false
	GameState.add_cash(-cost)
	owned.append(id)
	_apply_effect(b)
	return true

func get_building(id: String) -> Dictionary:
	for b in BUILDINGS:
		if b["id"] == id: return b
	return {}

func _apply_effect(b: Dictionary) -> void:
	match b["id"]:
		"nyse":    MarketEngine.apply_sector_impact("Finance", 0.15)
		"shard":   MarketEngine.apply_sector_impact("Finance", 0.08)
		"hamburg": MarketEngine.apply_global_impact(0.10)
		"suez":    MarketEngine.apply_event_impact("WTI", 0.12)
		"tokyo":   MarketEngine.apply_sector_impact("Tech", 0.06)
		"panama":  MarketEngine.apply_event_impact("WTI", 0.08)
