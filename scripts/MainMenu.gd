extends Control

var _t := 0.0
var _title_alpha := 0.0
var _btn_alpha   := 0.0
var _title_y     := 40.0
var _cols: Array  = []
var _btns: Array[Button] = []
var _settings_panel: PanelContainer = null
var _setup_panel: PanelContainer = null

const TICKERS := ["APRI +2.3%","OMNI -0.8%","XAU +0.4%","WTI -1.2%","GIDX +0.9%",
	"SMTC +3.1%","XAG +1.7%","ELVT -4.2%","CHPX +5.6%","CNBN -0.3%",
	"ATLS +0.7%","BLKP +1.1%","PRMZ -0.5%","SFTC +1.8%","NTG -2.1%"]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	randomize()
	for i in range(1280 / 68):
		_cols.append({"x":float(i)*68.0+randf_range(0,20),"y":randf_range(-720.0,0.0),
			"spd":randf_range(28.0,90.0),"tick":TICKERS[randi()%TICKERS.size()],"up":true,"a":randf_range(0.04,0.18)})
	LocaleSystem.language_changed.connect(_on_language_changed)
	_build_btns()
	_build_settings_panel()
	_build_setup_panel()
	set_process(true)

func _build_btns() -> void:
	for b in _btns: if is_instance_valid(b): b.queue_free()
	_btns.clear()

	var cx := 640; var base_y := 440
	var defs := [
		[LocaleSystem.get_tr("NEW_GAME"),      true],
		[LocaleSystem.get_tr("LOAD_GAME"),     false],
		[LocaleSystem.get_tr("MENU_SETTINGS"), false],
		[LocaleSystem.get_tr("QUIT"),          false],
	]
	var cbs := [
		func(): _show_setup(),
		func(): _load(),
		func(): _toggle_settings(),
		func(): get_tree().quit(),
	]
	for i in defs.size():
		var b := Button.new(); b.text = defs[i][0]; b.add_theme_font_size_override("font_size", 15)
		b.custom_minimum_size = Vector2(240, 44); b.set_position(Vector2(cx - 120, base_y + i * 56))
		if defs[i][1]:
			b.add_theme_color_override("font_color", Color(0.06, 0.06, 0.08))
			var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.22, 0.88, 0.52)
			sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
			sb.corner_radius_bottom_left = 4; sb.corner_radius_bottom_right = 4
			b.add_theme_stylebox_override("normal", sb)
		else:
			b.add_theme_color_override("font_color", Color(0.70, 0.72, 0.78))
		b.modulate.a = 0.0; b.pressed.connect(cbs[i]); add_child(b); _btns.append(b)

func _build_settings_panel() -> void:
	if _settings_panel and is_instance_valid(_settings_panel):
		_settings_panel.queue_free()

	_settings_panel = PanelContainer.new()
	_settings_panel.set_anchor_and_offset(SIDE_LEFT,   0.30, 0)
	_settings_panel.set_anchor_and_offset(SIDE_RIGHT,  0.70, 0)
	_settings_panel.set_anchor_and_offset(SIDE_TOP,    0.22, 0)
	_settings_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.78, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.04, 0.05, 0.09, 0.97)
	sb.border_color = Color(0.36, 0.52, 0.96)
	for side in [0, 1, 2, 3]: sb.set("border_width_" + ["left","right","top","bottom"][side], 1)
	_settings_panel.add_theme_stylebox_override("panel", sb)
	_settings_panel.visible = false
	add_child(_settings_panel)

	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 24)
	_settings_panel.add_child(mg)

	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 18); mg.add_child(v)

	# Header
	var hrow := HBoxContainer.new(); hrow.add_theme_constant_override("separation", 8); v.add_child(hrow)
	var title_lbl := Label.new()
	title_lbl.text = LocaleSystem.get_tr("SETTINGS_TITLE")
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(title_lbl)
	var close_btn := Button.new(); close_btn.text = "✕"; close_btn.flat = false
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func(): _settings_panel.visible = false)
	hrow.add_child(close_btn)

	var div := ColorRect.new(); div.color = Color(0.36, 0.52, 0.96, 0.35)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)

	# Language section
	var lang_lbl := Label.new(); lang_lbl.text = LocaleSystem.get_tr("LANGUAGE_LBL")
	lang_lbl.add_theme_font_size_override("font_size", 11)
	lang_lbl.add_theme_color_override("font_color", Color(0.42, 0.46, 0.56))
	v.add_child(lang_lbl)

	var lang_row := HBoxContainer.new(); lang_row.add_theme_constant_override("separation", 12); v.add_child(lang_row)

	var en_btn := Button.new(); en_btn.text = "🇬🇧  English"; en_btn.flat = false
	en_btn.add_theme_font_size_override("font_size", 14)
	en_btn.custom_minimum_size = Vector2(150, 44)
	if LocaleSystem.current_language == "en":
		var esb := StyleBoxFlat.new(); esb.bg_color = Color(0.18, 0.38, 0.72)
		esb.border_color = Color(0.36, 0.62, 1.0); esb.border_width_top = 1
		esb.border_width_bottom = 1; esb.border_width_left = 1; esb.border_width_right = 1
		en_btn.add_theme_stylebox_override("normal", esb)
		en_btn.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	else:
		en_btn.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	en_btn.pressed.connect(func(): LocaleSystem.set_language("en"))
	lang_row.add_child(en_btn)

	var tr_btn := Button.new(); tr_btn.text = "🇹🇷  Türkçe"; tr_btn.flat = false
	tr_btn.add_theme_font_size_override("font_size", 14)
	tr_btn.custom_minimum_size = Vector2(150, 44)
	if LocaleSystem.current_language == "tr":
		var tsb := StyleBoxFlat.new(); tsb.bg_color = Color(0.55, 0.10, 0.10)
		tsb.border_color = Color(0.90, 0.22, 0.22); tsb.border_width_top = 1
		tsb.border_width_bottom = 1; tsb.border_width_left = 1; tsb.border_width_right = 1
		tr_btn.add_theme_stylebox_override("normal", tsb)
		tr_btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.90))
	else:
		tr_btn.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	tr_btn.pressed.connect(func(): LocaleSystem.set_language("tr"))
	lang_row.add_child(tr_btn)

	# Resolution section
	var res_lbl := Label.new(); res_lbl.text = LocaleSystem.get_tr("RESOLUTION")
	res_lbl.add_theme_font_size_override("font_size", 11)
	res_lbl.add_theme_color_override("font_color", Color(0.42, 0.46, 0.56))
	v.add_child(res_lbl)

	var res_row := HBoxContainer.new(); res_row.add_theme_constant_override("separation", 8); v.add_child(res_row)
	for res in [[1280,720,"1280×720"],[1440,900,"1440×900"],[1920,1080,"1920×1080"]]:
		var rb := Button.new(); rb.text = res[2]; rb.flat = false
		rb.add_theme_font_size_override("font_size", 12)
		rb.add_theme_color_override("font_color", Color(0.70, 0.72, 0.78))
		var rr = res; rb.pressed.connect(func(): DisplayServer.window_set_size(Vector2i(rr[0], rr[1])))
		res_row.add_child(rb)

func _toggle_settings() -> void:
	if _settings_panel and is_instance_valid(_settings_panel):
		_settings_panel.visible = !_settings_panel.visible

func _show_setup() -> void:
	if _setup_panel and is_instance_valid(_setup_panel):
		_setup_panel.visible = true

func _build_setup_panel() -> void:
	if _setup_panel and is_instance_valid(_setup_panel):
		_setup_panel.queue_free()

	_setup_panel = PanelContainer.new()
	_setup_panel.set_anchor_and_offset(SIDE_LEFT,   0.28, 0)
	_setup_panel.set_anchor_and_offset(SIDE_RIGHT,  0.72, 0)
	_setup_panel.set_anchor_and_offset(SIDE_TOP,    0.20, 0)
	_setup_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.82, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.04, 0.05, 0.09, 0.97)
	sb.border_color = Color(0.22, 0.88, 0.52)
	for side in [0, 1, 2, 3]: sb.set("border_width_" + ["left","right","top","bottom"][side], 1)
	_setup_panel.add_theme_stylebox_override("panel", sb)
	_setup_panel.visible = false
	add_child(_setup_panel)

	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 32)
	_setup_panel.add_child(mg)

	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 20); mg.add_child(v)

	# Title
	var title := Label.new()
	title.text = LocaleSystem.get_tr("SETUP_TITLE")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.22, 0.88, 0.52))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var div := ColorRect.new(); div.color = Color(0.22, 0.88, 0.52, 0.30)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)

	# Player name
	var pn_lbl := Label.new(); pn_lbl.text = LocaleSystem.get_tr("SETUP_PLAYER_LBL")
	pn_lbl.add_theme_font_size_override("font_size", 11)
	pn_lbl.add_theme_color_override("font_color", Color(0.42, 0.46, 0.56))
	v.add_child(pn_lbl)

	var pn_edit := LineEdit.new()
	pn_edit.placeholder_text = LocaleSystem.get_tr("SETUP_PLAYER_HINT")
	pn_edit.text = "" if GameState.player_name == "The Investor" else GameState.player_name
	pn_edit.custom_minimum_size = Vector2(0, 44)
	pn_edit.add_theme_font_size_override("font_size", 15)
	v.add_child(pn_edit)

	# Company name
	var cn_lbl := Label.new(); cn_lbl.text = LocaleSystem.get_tr("SETUP_COMPANY_LBL")
	cn_lbl.add_theme_font_size_override("font_size", 11)
	cn_lbl.add_theme_color_override("font_color", Color(0.42, 0.46, 0.56))
	v.add_child(cn_lbl)

	var cn_edit := LineEdit.new()
	cn_edit.placeholder_text = LocaleSystem.get_tr("SETUP_COMPANY_HINT")
	cn_edit.text = "" if GameState.company_name == "The Exchange" else GameState.company_name
	cn_edit.custom_minimum_size = Vector2(0, 44)
	cn_edit.add_theme_font_size_override("font_size", 15)
	v.add_child(cn_edit)

	var spacer := Control.new(); spacer.custom_minimum_size = Vector2(0, 8); v.add_child(spacer)

	# Start button
	var start_btn := Button.new()
	start_btn.text = LocaleSystem.get_tr("SETUP_START")
	start_btn.custom_minimum_size = Vector2(0, 52)
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.add_theme_color_override("font_color", Color(0.06, 0.06, 0.08))
	var bsb := StyleBoxFlat.new(); bsb.bg_color = Color(0.22, 0.88, 0.52)
	bsb.corner_radius_top_left = 4; bsb.corner_radius_top_right = 4
	bsb.corner_radius_bottom_left = 4; bsb.corner_radius_bottom_right = 4
	start_btn.add_theme_stylebox_override("normal", bsb)
	start_btn.pressed.connect(func():
		var pname := pn_edit.text.strip_edges()
		var cname := cn_edit.text.strip_edges()
		GameState.player_name  = pname if pname != "" else "The Investor"
		GameState.company_name = cname if cname != "" else "The Exchange"
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	)
	v.add_child(start_btn)

	# Cancel link
	var cancel_btn := Button.new(); cancel_btn.text = "✕  " + LocaleSystem.get_tr("SETUP_CANCEL"); cancel_btn.flat = true
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.add_theme_color_override("font_color", Color(0.42, 0.46, 0.56))
	cancel_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cancel_btn.pressed.connect(func(): _setup_panel.visible = false)
	v.add_child(cancel_btn)

func _on_language_changed() -> void:
	_btn_alpha = 0.0; _t = 0.0; _title_alpha = 0.0; _title_y = 40.0
	_build_btns()
	_build_settings_panel()
	_build_setup_panel()
	if _settings_panel and is_instance_valid(_settings_panel):
		_settings_panel.visible = true

func _process(delta: float) -> void:
	_t += delta; _title_alpha = minf(_title_alpha + delta * 0.6, 1.0); _title_y = maxf(_title_y - delta * 60.0, 0.0)
	if _t > 1.2: _btn_alpha = minf(_btn_alpha + delta * 1.2, 1.0)
	for b in _btns: if is_instance_valid(b): b.modulate.a = _btn_alpha
	for col in _cols:
		col["y"] += col["spd"] * delta
		if col["y"] > 720 + 40: col["y"] = -60.0; col["tick"] = TICKERS[randi() % TICKERS.size()]; col["up"] = col["tick"].find("+") != -1
	queue_redraw()

func _draw() -> void:
	var W := size.x; var H := size.y
	draw_rect(Rect2(0, 0, W, H), Color(0.030, 0.035, 0.050))
	for r in [320, 240, 160, 80]:
		draw_circle(Vector2(W * 0.5, H * 0.38), r, Color(0.20, 0.40, 0.80, 0.012 * (1.0 - float(r) / 320.0)))
	var font := ThemeDB.fallback_font
	for col in _cols:
		var c := Color(0.22, 0.85, 0.45, col["a"]) if col["up"] else Color(0.90, 0.30, 0.30, col["a"])
		draw_string(font, Vector2(col["x"], col["y"]), col["tick"], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c)
	var ty := H * 0.30 + _title_y
	draw_string(font, Vector2(W * 0.5 - 188, ty + 3), "THE EXCHANGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 62, Color(0, 0, 0, _title_alpha * 0.6))
	draw_string(font, Vector2(W * 0.5 - 188, ty), "THE EXCHANGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 62, Color(0.90, 0.92, 0.98, _title_alpha))
	draw_string(font, Vector2(W * 0.5 - 195, ty + 70), "GLOBAL MARKETS MANIPULATION SIMULATOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.44, 0.55, 0.75, _title_alpha * 0.8))
	var y := 0.0
	while y < H: draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.025), 1.0); y += 3.0
	draw_string(font, Vector2(W - 95, H - 10), "v0.7.0 ALPHA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.25, 0.28, 0.36, 0.5))

func _load() -> void:
	SaveSystem.load_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
