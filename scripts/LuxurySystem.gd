extends Node

signal item_purchased(item: Dictionary)

const ITEMS := [
	{
		"id": "trex",      "icon": "🦕",
		"price": 28_000_000.0,
		"name_key": "LNAME_TREX", "desc_key": "LDESC_TREX",
	},
	{
		"id": "yali",      "icon": "🏯",
		"price": 85_000_000.0,
		"name_key": "LNAME_YALI", "desc_key": "LDESC_YALI",
	},
	{
		"id": "f16",       "icon": "✈",
		"price": 180_000_000.0,
		"name_key": "LNAME_F16",  "desc_key": "LDESC_F16",
	},
	{
		"id": "monalisa",  "icon": "🖼",
		"price": 750_000_000.0,
		"name_key": "LNAME_MONA", "desc_key": "LDESC_MONA",
	},
	{
		"id": "livercool", "icon": "⚽",
		"price": 1_800_000_000.0,
		"name_key": "LNAME_LFC",  "desc_key": "LDESC_LFC",
	},
	{
		"id": "moon",      "icon": "🌕",
		"price": 45_000_000_000.0,
		"name_key": "LNAME_MOON", "desc_key": "LDESC_MOON",
	},
	{
		"id": "mars",      "icon": "🔴",
		"price": 380_000_000_000.0,
		"name_key": "LNAME_MARS", "desc_key": "LDESC_MARS",
	},
]

var owned: Array = []

func buy(item_id: String) -> bool:
	var item := _find(item_id)
	if item.is_empty() or item_id in owned: return false
	if GameState.cash < item["price"]: return false
	GameState.add_cash(-item["price"])
	owned.append(item_id)
	emit_signal("item_purchased", item)
	return true

func is_owned(iid: String) -> bool: return iid in owned

func _find(iid: String) -> Dictionary:
	for item in ITEMS:
		if item["id"] == iid: return item
	return {}
