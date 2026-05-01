extends Control

var _t := 0.0
var _title_alpha := 0.0
var _btn_alpha   := 0.0
var _title_y     := 40.0
var _cols: Array  = []
var _btns: Array[Button] = []

const TICKERS := ["APRI +2.3%","OMNI -0.8%","XAU +0.4%","WTI -1.2%","GIDX +0.9%",
	"SMTC +3.1%","XAG +1.7%","ELVT -4.2%","CHPX +5.6%","CNBN -0.3%",
	"ATLS +0.7%","BLKP +1.1%","PRMZ -0.5%","SFTC +1.8%","NTG -2.1%"]

func _ready() -> void:
	# Ensure root Control fills the viewport
	set_anchors_preset(Control.PRESET_FULL_RECT)
	randomize()
	for i in range(1280 / 68):
		_cols.append({"x":float(i)*68.0+randf_range(0,20),"y":randf_range(-720.0,0.0),
			"spd":randf_range(28.0,90.0),"tick":TICKERS[randi()%TICKERS.size()],"up":true,"a":randf_range(0.04,0.18)})
	_build_btns()
	# Rebuild buttons whenever the language changes
	LocaleSystem.language_changed.connect(_on_language_changed)
	set_process(true)

func _build_btns() -> void:
	# Clear any previously built buttons
	for b in _btns: if is_instance_valid(b): b.queue_free()
	_btns.clear()

	var cx := 640; var base_y := 440
	var defs := [
		[LocaleSystem.tr("NEW_GAME"),      true ],
		[LocaleSystem.tr("LOAD_GAME"),     false],
		[LocaleSystem.tr("MENU_SETTINGS"), false],
		[LocaleSystem.tr("QUIT"),          false],
	]
	var cbs  := [
		func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"),
		func(): _load(),
		func(): _settings(),
		func(): get_tree().quit()
	]
	for i in defs.size():
		var b := Button.new(); b.text = defs[i][0]; b.add_theme_font_size_override("font_size",15)
		b.custom_minimum_size = Vector2(240, 44); b.set_position(Vector2(cx-120, base_y + i*56))
		if defs[i][1]:
			b.add_theme_color_override("font_color", Color(0.06,0.06,0.08))
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.22, 0.88, 0.52)
			sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
			sb.corner_radius_bottom_left = 4; sb.corner_radius_bottom_right = 4
			b.add_theme_stylebox_override("normal",sb)
		else:
			b.add_theme_color_override("font_color", Color(0.70,0.72,0.78))
		b.modulate.a = 0.0; b.pressed.connect(cbs[i]); add_child(b); _btns.append(b)

	# Language toggle button (top-right corner)
	var lang_b := Button.new()
	lang_b.text = "TR" if LocaleSystem.current_language == "en" else "EN"
	lang_b.add_theme_font_size_override("font_size", 13)
	lang_b.custom_minimum_size = Vector2(60, 32)
	lang_b.set_position(Vector2(1280 - 80, 16))
	lang_b.add_theme_color_override("font_color", Color(0.70,0.80,0.96))
	lang_b.pressed.connect(_toggle_language)
	add_child(lang_b); _btns.append(lang_b)

func _toggle_language() -> void:
	var next := "tr" if LocaleSystem.current_language == "en" else "en"
	LocaleSystem.set_language(next)

func _on_language_changed() -> void:
	# Reset animation state so buttons fade in nicely after rebuild
	_btn_alpha = 0.0
	_t = 0.0
	_title_alpha = 0.0
	_title_y = 40.0
	_build_btns()

func _process(delta: float) -> void:
	_t += delta; _title_alpha = minf(_title_alpha + delta*0.6,1.0); _title_y = maxf(_title_y - delta*60.0,0.0)
	if _t > 1.2: _btn_alpha = minf(_btn_alpha + delta*1.2,1.0)
	for b in _btns: if is_instance_valid(b): b.modulate.a = _btn_alpha
	for col in _cols:
		col["y"] += col["spd"]*delta
		if col["y"] > 720+40: col["y"]=-60.0; col["tick"]=TICKERS[randi()%TICKERS.size()]; col["up"]=col["tick"].find("+")!=-1
	queue_redraw()

func _draw() -> void:
	var W := size.x; var H := size.y
	draw_rect(Rect2(0,0,W,H), Color(0.030,0.035,0.050))
	for r in [320,240,160,80]:
		draw_circle(Vector2(W*0.5,H*0.38),r, Color(0.20,0.40,0.80,0.012*(1.0-float(r)/320.0)))
	var font := ThemeDB.fallback_font
	for col in _cols:
		var c := Color(0.22,0.85,0.45,col["a"]) if col["up"] else Color(0.90,0.30,0.30,col["a"])
		draw_string(font, Vector2(col["x"],col["y"]), col["tick"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c)
	var ty := H*0.30 + _title_y
	draw_string(font, Vector2(W*0.5-188,ty+3), "THE EXCHANGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 62, Color(0,0,0,_title_alpha*0.6))
	draw_string(font, Vector2(W*0.5-188,ty), "THE EXCHANGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 62, Color(0.90,0.92,0.98,_title_alpha))
	draw_string(font, Vector2(W*0.5-195,ty+70), "GLOBAL MARKETS MANIPULATION SIMULATOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.44,0.55,0.75,_title_alpha*0.8))
	var y := 0.0
	while y<H: draw_line(Vector2(0,y),Vector2(W,y), Color(0,0,0,0.025),1.0); y+=3.0
	draw_string(font, Vector2(W-95,H-10), "v0.7.0 ALPHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.25,0.28,0.36,0.5))

func _load() -> void:
	SaveSystem.load_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _settings() -> void: pass
