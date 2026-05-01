## IconLoader.gd
## Autoload olarak ekle: Project > Project Settings > Autoload
## Name: IconLoader
##
## Kullanım:
##   var tex = IconLoader.get_icon("XAU")   # Texture2D döner
##   var tr  = IconLoader.make_rect("XAU", 24)  # TextureRect döner (24x24)

extends Node

const ICON_SIZE := 80  # SVG'lerin orijinal boyutu

var _cache: Dictionary = {}

const TICKERS := [
	"XAU","XAG","WTI","NTG",
	"APRI","OMNI","PRMZ","SFTC","ELVT","MVRS","CHPX",
	"SMTC","CNBN","BLKP","MSTL",
	"ATLS","CRWN","PCOL",
	"GIDX","TIDX"
]

func _ready() -> void:
	_preload_all()

func _preload_all() -> void:
	for ticker in TICKERS:
		var path = "res://icons/%s.svg" % ticker
		if ResourceLoader.exists(path):
			_cache[ticker] = load(path)
		else:
			push_warning("IconLoader: %s bulunamadı → %s" % [ticker, path])

## Texture2D döner; yoksa null
func get_icon(ticker: String) -> Texture2D:
	return _cache.get(ticker, null)

## Hazır TextureRect döner — doğrudan add_child() ile kullanılabilir
func make_rect(ticker: String, size_px: int = 28) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = get_icon(ticker)
	tr.custom_minimum_size = Vector2(size_px, size_px)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return tr
