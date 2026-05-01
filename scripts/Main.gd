extends Control

# ── UI refs ──────────────────────────────────────────────────────────────────
var _date_lbl:   Label; var _cash_lbl:  Label; var _nw_lbl:   Label
var _inf_lbl:    Label; var _msg_lbl:   Label; var _rank_lbl: Label
var _off_lbl:    Label; var _pause_btn: Button

var _ticker_list:    VBoxContainer; var _port_list:     VBoxContainer
var _news_container: VBoxContainer; var _contacts_list: VBoxContainer

var _chart:    ChartControl; var _sel_lbl:  Label
var _tick_sel: OptionButton; var _qty_in:   SpinBox

var _contacts_panel: PanelContainer; var _port_panel:     PanelContainer
var _port_detail:    RichTextLabel;  var _lb_panel:       PanelContainer
var _lb_lbl:         RichTextLabel;  var _settings_panel: PanelContainer
var _spec_panel:     PanelContainer; var _map_panel:      PanelContainer
var _country_popup:  PanelContainer; var _council_panel:  PanelContainer
var _building_popup: PanelContainer
var _luxury_panel:   PanelContainer
var _luxury_list:    VBoxContainer
var _tech_panel:     PanelContainer
var _tech_list:      VBoxContainer
var _tech_income_lbl: Label
var _ach_panel:      PanelContainer
var _ach_list:       VBoxContainer
var _mega_popup:     PanelContainer
var _toast_queue:    Array = []
var _toast_active:   bool  = false
var _flash_color:    Color = Color(1, 0.4, 0.1, 0.0)   # current full-screen flash (alpha driven by tween)
var _transition_alpha: float = 0.0                       # 0=transparent 1=black (office transition)
var _company_card_ctrl: Control
var _co_own_lbl:     Label
var _co_val_lbl:     Label
var _co_agm_lbl:     Label
var _action_result_panel: PanelContainer
var _trade_popup:    PanelContainer
var _newspaper_popup: PanelContainer
var _phone_popup:     PanelContainer
var _pre_news_paused: bool = false

# ── KEY: store content columns so we can hide them ───────────────────────────
var _content_columns:   HBoxContainer
var _office_card_ctrl:  Control

var _sel_ticker      := "GIDX"
var _current_offer:  Dictionary = {}
var _office_view:    bool = false
var _hovered_country := ""

# ── Background animation data ─────────────────────────────────────────────────
var _t      := 0.0
var _lights := []
var _stars  := []
var _rain   := []
var _country_polys: Dictionary = {}
var _country_bbox:  Dictionary = {}
var _map_bounds:    Dictionary = {}   # ml, mt, mw, mh — set each draw frame

# ── Colours ───────────────────────────────────────────────────────────────────
const CP = Color(0.04, 0.05, 0.09, 0.38)   # panels – semi-transparent so office bg shows through
const CB = Color(0.16, 0.21, 0.34)
const CT = Color(0.88, 0.91, 0.96);  const CM = Color(0.42, 0.46, 0.56)
const CG = Color(0.22, 0.88, 0.52);  const CR = Color(0.92, 0.28, 0.28)
const CO = Color(1.00, 0.80, 0.28);  const CA = Color(0.36, 0.52, 0.96)

const TICON = {
	"APRI":"◆","OMNI":"◆","PRMZ":"◆","SFTC":"◆","ELVT":"◆","MVRS":"◆","CHPX":"◆",
	"SMTC":"▲","CNBN":"▲","BLKP":"▲","MSTL":"▲","ATLS":"●","CRWN":"●","PCOL":"●",
	"XAU":"★","XAG":"★","WTI":"●","NTG":"●","GIDX":"≡","TIDX":"≡"
}
const TCOL = {
	"APRI":"#7F77DD","OMNI":"#7F77DD","PRMZ":"#7F77DD","SFTC":"#7F77DD",
	"ELVT":"#7F77DD","MVRS":"#7F77DD","CHPX":"#7F77DD",
	"SMTC":"#378ADD","CNBN":"#378ADD","BLKP":"#378ADD","MSTL":"#378ADD",
	"ATLS":"#EF9F27","CRWN":"#EF9F27","PCOL":"#EF9F27",
	"XAU":"#FAC775","XAG":"#B4B2A9","WTI":"#EF9F27","NTG":"#EF9F27",
	"GIDX":"#888780","TIDX":"#888780"
}

# ── Shorthand for LocaleSystem translations ───────────────────────────────────
func _txt(key: String) -> String:
	return LocaleSystem.get_tr(key)

# ═══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	# ── BACKGROUND FIX: ensure this Control fills the full viewport ──────────
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Clear any default Panel stylebox that would paint over _draw() output
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	_bake()
	_build_ui()
	_connect_all()
	_pop_dropdown()
	_refresh_all()
	set_process(true)

	# Rebuild UI when the player switches language)

# Rebuild the entire UI in-place while preserving all game-state (autoloads).
func _on_language_changed() -> void:
	# Free every child node (UI panels, bars, etc.)
	for ch in get_children():
		ch.queue_free()
	# Reset all UI refs so _build_ui() starts clean
	_date_lbl = null; _cash_lbl = null; _nw_lbl = null
	_inf_lbl  = null; _msg_lbl  = null; _rank_lbl = null
	_off_lbl  = null; _pause_btn = null
	_ticker_list = null; _port_list = null
	_news_container = null; _contacts_list = null
	_chart = null; _sel_lbl = null
	_tick_sel = null; _qty_in = null
	_contacts_panel = null; _port_panel = null
	_port_detail = null; _lb_panel = null
	_lb_lbl = null; _settings_panel = null
	_spec_panel = null; _map_panel = null
	_country_popup = null; _council_panel = null; _building_popup = null; _trade_popup = null; _newspaper_popup = null; _content_columns = null
	_luxury_panel = null; _luxury_list = null
	_tech_panel = null; _tech_list = null; _tech_income_lbl = null
	_ach_panel = null; _ach_list = null
	_mega_popup = null
	_toast_queue = []; _toast_active = false
	# Rebuild
	_build_ui()
	_connect_all()
	_pop_dropdown()
	_refresh_all()

func _bake() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 31415
	for i in 220:
		_lights.append({"x":r.randf(),"y":r.randf_range(0.52,0.91),
			"w":r.randf_range(0.003,0.016),"h":r.randf_range(0.008,0.028),
			"r":r.randf_range(0.4,1.0),"g":r.randf_range(0.4,1.0),"b":r.randf_range(0.4,1.0),
			"blink":i%6==0,"ph":r.randf()*TAU,"sp":r.randf_range(0.5,2.5)})
	r.seed = 27182
	for _i in 100:
		_stars.append({"x":r.randf(),"y":r.randf_range(0.01,0.46),
			"r":r.randf_range(0.5,1.8),"ph":r.randf()*TAU,"sp":r.randf_range(0.3,1.5)})
	r.seed = 65358
	for _i in 40:
		_rain.append({"x":r.randf(),"oy":r.randf()*720.0*1.5,
			"spd":r.randf_range(55.0,145.0),"len":r.randf_range(14.0,38.0)})
	var _sh = load("res://scripts/CountryShapes.gd").new().get_shapes()
	for uid in _sh:
		var lid = uid.to_lower()
		var rings = _sh[uid]["r"]
		var polys := []
		var bx0:=1.0; var by0:=1.0; var bx1:=0.0; var by1:=0.0
		for ring in rings:
			var pts := PackedVector2Array()
			for pt in ring:
				var nx := (float(pt[0]) + 180.0) / 360.0
				var ny := (90.0 - float(pt[1])) / 180.0
				pts.append(Vector2(nx, ny))
				bx0=minf(bx0,nx); by0=minf(by0,ny)
				bx1=maxf(bx1,nx); by1=maxf(by1,ny)
			polys.append(pts)
		_country_polys[lid] = polys
		_country_bbox[lid]  = {"x0":bx0,"y0":by0,"x1":bx1,"y1":by1}

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════════
# _draw() — runs every frame on root Control, always visible
# ═══════════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 10 or H < 10: return
	# World map view replaces office background entirely
	if _map_panel and _map_panel.visible:
		_draw_map(W, H)
		return
	# Office background based on level
	match OfficeSystem.current_level:
		0: _bg_basement(W, H)
		1: _bg_small_office(W, H)
		2: _bg_trading_floor(W, H)
		3: _bg_penthouse(W, H)
		_: _bg_basement(W, H)
	# Office transition fade-to-black overlay
	if _transition_alpha > 0.001:
		draw_rect(Rect2(0, 0, W, H), Color(0.0, 0.0, 0.0, _transition_alpha))
	# Crisis flash overlay
	if _flash_color.a > 0.001:
		draw_rect(Rect2(0, 0, W, H), _flash_color)

# ── BASEMENT ──────────────────────────────────────────────────────────────────
func _bg_basement(W: float, H: float) -> void:
	# Zemin — koyu beton, soğuk yeşil-gri
	for i in 12:
		var t_ := float(i) / 11.0
		draw_rect(Rect2(0, H * t_ / 12.0, W, H / 12.0 + 1), Color(lerp(0.050,0.065,t_), lerp(0.055,0.070,t_), lerp(0.044,0.052,t_)))
	draw_rect(Rect2(0, 0, W, H * 0.13), Color(0.075, 0.080, 0.065))
	var rng := RandomNumberGenerator.new(); rng.seed = 9901
	for i in 7:
		draw_rect(Rect2(0, H * (0.04 + float(i) * 0.013), W, 2.0 + rng.randf() * 2), Color(0.040, 0.044, 0.034, 0.8))
	# Dikey boru
	draw_rect(Rect2(W * 0.09, 0, 14, H * 0.75), Color(0.100, 0.105, 0.085))
	draw_rect(Rect2(W * 0.09, 0, 3.0, H * 0.75), Color(0.160, 0.165, 0.130))
	for yj in [H * 0.18, H * 0.42, H * 0.62]:
		draw_rect(Rect2(W * 0.085, yj, 24, 8), Color(0.120, 0.125, 0.100))
		draw_rect(Rect2(W * 0.085, yj, 24, 2), Color(0.180, 0.185, 0.145))
	# Yatay tavan borusu
	draw_rect(Rect2(0, H * 0.092, W * 0.58, 14), Color(0.095, 0.100, 0.080))
	draw_rect(Rect2(0, H * 0.092, W * 0.58, 3.5), Color(0.145, 0.150, 0.115))
	for bx2 in [W * 0.12, W * 0.28, W * 0.45]:
		draw_circle(Vector2(bx2, H * 0.099), 7.5, Color(0.115, 0.120, 0.095))
	# Sol duvar kitaplığı
	draw_rect(Rect2(W * 0.005, H * 0.15, W * 0.075, H * 0.55), Color(0.100, 0.095, 0.075))
	draw_rect(Rect2(W * 0.005, H * 0.15, W * 0.075, 2.5), Color(0.150, 0.140, 0.110))
	for si in 3:
		draw_rect(Rect2(W * 0.005, H * (0.28 + float(si) * 0.14), W * 0.075, 2.5), Color(0.130, 0.120, 0.095))
	var book_cols := [Color(0.22,0.08,0.05),Color(0.05,0.10,0.20),Color(0.08,0.18,0.06),Color(0.18,0.16,0.04),Color(0.12,0.05,0.18),Color(0.16,0.12,0.05)]
	rng.seed = 3210
	for bi in 14:
		var bw2 := rng.randf_range(8, 13); var bh2 := rng.randf_range(20, 34)
		var row2 := bi / 5; var col2 := bi % 5
		var bx3 := W * 0.008 + float(col2) * 13
		var rowy = [H * 0.275, H * 0.415, H * 0.555][mini(row2, 2)]
		draw_rect(Rect2(bx3, rowy - bh2, bw2, bh2), book_cols[bi % book_cols.size()])
	# Küçük kirli pencere
	var wx := W * 0.66; var wy := H * 0.12; var ww := W * 0.19; var wh := H * 0.145
	draw_rect(Rect2(wx, wy, ww, wh), Color(0.016, 0.020, 0.030))
	for s in _stars:
		var br := 0.2 + 0.5 * absf(sin(_t * s["sp"] + s["ph"]))
		draw_circle(Vector2(wx + s["x"] * ww, wy + s["y"] * wh * 0.65), s["r"] * 0.7, Color(0.82, 0.86, 0.90, br * 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(wx,wy+wh),Vector2(wx+ww,wy+wh),Vector2(wx+ww,wy+wh*0.72),Vector2(wx,wy+wh*0.72)]), Color(0.28,0.42,0.22,0.18))
	for gi in 5: draw_rect(Rect2(wx + float(gi) * (ww / 5.0), wy, 3.0, wh), Color(0.040, 0.045, 0.036, 0.92))
	draw_rect(Rect2(wx, wy + wh * 0.50, ww, 3.0), Color(0.040, 0.045, 0.036, 0.92))
	for side in [[wx-8,wy-8,ww+16,8],[wx-8,wy+wh,ww+16,8],[wx-8,wy-8,8,wh+16],[wx+ww,wy-8,8,wh+16]]:
		draw_rect(Rect2(side[0],side[1],side[2],side[3]), Color(0.075,0.070,0.058))
	for r in _rain:
		var ry2 := fmod(r["oy"] + _t * r["spd"], wh * 1.2) + wy - wh * 0.1
		if ry2 >= wy and ry2 <= wy + wh:
			draw_line(Vector2(wx + r["x"] * ww, ry2), Vector2(wx + r["x"] * ww + 1.5, ry2 + r["len"] * 0.7), Color(0.45, 0.62, 0.80, 0.12), 1.0)
	# Zemin
	draw_rect(Rect2(0, H * 0.73, W, H - H * 0.73), Color(0.048, 0.050, 0.040))
	draw_rect(Rect2(0, H * 0.73, W, 3.0), Color(0.100, 0.105, 0.082))
	# Eski ahşap masa
	draw_rect(Rect2(W * 0.20, H * 0.60, W * 0.58, H * 0.135), Color(0.115, 0.090, 0.058))
	draw_rect(Rect2(W * 0.20, H * 0.60, W * 0.58, 3.0), Color(0.175, 0.140, 0.090))
	for lx2 in [W * 0.22, W * 0.74]: draw_rect(Rect2(lx2, H * 0.73, 10, H * 0.065), Color(0.080, 0.062, 0.040))
	# CRT monitör
	_draw_crt(W * 0.38, H * 0.26, W * 0.18, H * 0.28)
	# Çıplak ampul
	draw_line(Vector2(W * 0.30, 0), Vector2(W * 0.30, H * 0.04), Color(0.10, 0.10, 0.08), 2.0)
	var flicker := 0.82 + 0.18 * absf(sin(_t * 2.2 + sin(_t * 8.7) * 0.4))
	draw_circle(Vector2(W * 0.30, H * 0.04), 9.0, Color(0.88, 0.82, 0.58, flicker * 0.85))
	draw_circle(Vector2(W * 0.30, H * 0.04), 6.0, Color(1.0, 0.97, 0.78, flicker))
	draw_colored_polygon(PackedVector2Array([Vector2(W*0.30-10,H*0.04+10),Vector2(W*0.30+10,H*0.04+10),Vector2(W*0.30+160,H*0.73),Vector2(W*0.30-160,H*0.73)]), Color(0.92, 0.85, 0.58, flicker * 0.032))
	# Damlayan su
	rng.seed = 8833
	for _di in 3:
		var dx := rng.randf_range(W * 0.35, W * 0.70)
		var dphase := rng.randf() * TAU
		var dy := H * 0.13 + fmod(_t * 32.0 + dphase * 20.0, H * 0.56)
		draw_circle(Vector2(dx, dy), 2.2, Color(0.28, 0.40, 0.28, absf(sin(_t * 0.9 + dphase)) * 0.55))
	# Masa üstü
	_draw_papers(W * 0.23, H * 0.715); _draw_mug(W * 0.60, H * 0.715); _draw_phone(W * 0.70, H * 0.715)
	_draw_npc_hunched(W * 0.46, H * 0.717)
	_draw_scan(W, H, 0.04)

# ── SMALL OFFICE ──────────────────────────────────────────────────────────────
func _bg_small_office(W: float, H: float) -> void:
	# Sıcak amber, ahşap panel
	for i in 12:
		var t_ := float(i) / 11.0
		draw_rect(Rect2(0, H * t_ / 12.0, W, H / 12.0 + 1), Color(lerp(0.110,0.076,t_), lerp(0.092,0.060,t_), lerp(0.058,0.035,t_)))
	# Ahşap lambri alt yarı
	draw_rect(Rect2(0, H * 0.64, W, H * 0.36), Color(0.095, 0.072, 0.040))
	draw_rect(Rect2(0, H * 0.64, W, 3.5), Color(0.175, 0.135, 0.080))
	var rng := RandomNumberGenerator.new(); rng.seed = 4561
	for wi in 14:
		draw_rect(Rect2(0, H * 0.645 + float(wi) * 13, W, 1.2), Color(0.072, 0.055, 0.030, 0.4 + rng.randf() * 0.3))
	# Büyük pencere — gece manzarası
	_draw_window(W * 0.44, H * 0.06, W * 0.34, H * 0.59, 1)
	for side2 in [[W*0.44-8,H*0.06-8,W*0.34+16,8],[W*0.44-8,H*0.06+H*0.59,W*0.34+16,8],[W*0.44-8,H*0.06-8,8,H*0.59+16],[W*0.44+W*0.34,H*0.06-8,8,H*0.59+16]]:
		draw_rect(Rect2(side2[0],side2[1],side2[2],side2[3]), Color(0.090, 0.068, 0.038))
	draw_rect(Rect2(W*0.44 + W*0.34*0.5 - 4, H*0.06, 8, H*0.59), Color(0.080, 0.060, 0.032))
	draw_rect(Rect2(W*0.44, H*0.06 + H*0.59*0.48 - 4, W*0.34, 8), Color(0.080, 0.060, 0.032))
	# Sol duvar dekorasyonlar
	_draw_wall_photo(W * 0.07, H * 0.13, 130, 95)
	_draw_wall_certificate(W * 0.07, H * 0.38, 130, 88)
	# Sağ kitaplık
	draw_rect(Rect2(W * 0.845, H * 0.08, W * 0.148, H * 0.53), Color(0.100, 0.075, 0.040))
	draw_rect(Rect2(W * 0.845, H * 0.08, W * 0.148, 2.5), Color(0.155, 0.115, 0.065))
	for rsi in 3:
		draw_rect(Rect2(W * 0.845, H * (0.21 + float(rsi) * 0.14), W * 0.148, 3.0), Color(0.130, 0.098, 0.055))
	var bcols2 := [Color(0.50,0.08,0.08),Color(0.06,0.18,0.40),Color(0.10,0.35,0.08),Color(0.35,0.22,0.05),Color(0.20,0.08,0.35),Color(0.35,0.32,0.05)]
	rng.seed = 6541
	for bi2 in 18:
		var bw3 := rng.randf_range(9, 14); var bh3 := rng.randf_range(20, 32)
		var row3 := bi2 / 6; var col3 := bi2 % 6
		var bx4 := W * 0.848 + float(col3) * (W * 0.148 / 6.2)
		var rowy2 = [H * 0.205, H * 0.345, H * 0.485][mini(row3, 2)]
		draw_rect(Rect2(bx4, rowy2 - bh3, bw3, bh3), bcols2[bi2 % bcols2.size()])
	# Zemin ahşap
	draw_rect(Rect2(0, H * 0.73, W, H - H * 0.73), Color(0.088, 0.065, 0.038))
	draw_rect(Rect2(0, H * 0.73, W, 3.5), Color(0.155, 0.118, 0.068))
	# Ahşap masa
	draw_rect(Rect2(W * 0.04, H * 0.60, W * 0.57, H * 0.135), Color(0.175, 0.128, 0.072))
	draw_rect(Rect2(W * 0.04, H * 0.60, W * 0.57, 3.5), Color(0.260, 0.195, 0.112))
	draw_rect(Rect2(W * 0.04, H * 0.666, W * 0.57, 2.0), Color(0.135, 0.098, 0.055))
	draw_rect(Rect2(W * 0.27, H * 0.602, 2.0, H * 0.130), Color(0.135, 0.098, 0.055))
	_draw_mon(W * 0.09, H * 0.20, W * 0.22, H * 0.38, 0)
	_draw_mon(W * 0.34, H * 0.17, W * 0.20, H * 0.41, 1)
	_draw_lamp_colored(W * 0.70, H * 0.60)
	_draw_trophy(W * 0.73, H * 0.717)
	_draw_papers(W * 0.07, H * 0.715); _draw_mug(W * 0.75, H * 0.715); _draw_phone(W * 0.21, H * 0.715)
	_draw_npc_standing(W * 0.47, H * 0.717)
	_draw_scan(W, H, 0.015)

# ── TRADING FLOOR ─────────────────────────────────────────────────────────────
func _bg_trading_floor(W: float, H: float) -> void:
	# Koyu kurumsal mavi
	for i in 12:
		var t_ := float(i) / 11.0
		draw_rect(Rect2(0, H * t_ / 12.0, W, H / 12.0 + 1), Color(lerp(0.038,0.024,t_), lerp(0.042,0.028,t_), lerp(0.062,0.044,t_)))
	draw_rect(Rect2(0, 0, W, H * 0.09), Color(0.046, 0.050, 0.070))
	var rng := RandomNumberGenerator.new(); rng.seed = 1112
	for ci in 24:
		draw_rect(Rect2(float(ci) * W / 24.0, 0, 1.0, H * 0.09), Color(0.030, 0.034, 0.050, 0.5))
	# LED tavan şeritleri
	for li in 5:
		var lx2 := W * (0.10 + float(li) * 0.19)
		draw_rect(Rect2(lx2 - 44, H * 0.087, 88, 3.5), Color(0.55, 0.72, 1.0, 0.90))
		draw_colored_polygon(PackedVector2Array([Vector2(lx2-44,H*0.091),Vector2(lx2+44,H*0.091),Vector2(lx2+90,H*0.30),Vector2(lx2-90,H*0.30)]), Color(0.50, 0.68, 1.0, 0.040))
	_draw_window(W * 0.24, H * 0.04, W * 0.72, H * 0.58, 2)
	for mi in 4:
		draw_rect(Rect2(W * 0.24 + float(mi + 1) * (W * 0.72 / 5.0), H * 0.04, 4.5, H * 0.58), Color(0.040, 0.045, 0.065))
	draw_rect(Rect2(W * 0.24, H * 0.04 + H * 0.58 * 0.50, W * 0.72, 4.5), Color(0.040, 0.045, 0.065))
	# Zemin
	draw_rect(Rect2(0, H * 0.72, W, H - H * 0.72), Color(0.030, 0.034, 0.050))
	draw_rect(Rect2(0, H * 0.72, W, 3.5), Color(0.080, 0.092, 0.130))
	for fi in 10:
		draw_rect(Rect2(float(fi) * W / 10.0, H * 0.72, 1.5, H * 0.28), Color(0.050, 0.055, 0.078, 0.50))
	# Trading masası
	draw_rect(Rect2(W * 0.02, H * 0.60, W * 0.80, H * 0.12), Color(0.048, 0.054, 0.075))
	draw_rect(Rect2(W * 0.02, H * 0.60, W * 0.80, 3.5), Color(0.100, 0.120, 0.180))
	# Bloomberg board
	draw_rect(Rect2(W * 0.02, H * 0.10, W * 0.20, H * 0.09), Color(0.022, 0.026, 0.040))
	draw_rect(Rect2(W * 0.02, H * 0.10, W * 0.20, 2.5), Color(0.055, 0.068, 0.105))
	rng.seed = 5588
	for ri in 3:
		for ci2 in 4:
			var is_up := rng.randf() > 0.45
			draw_rect(Rect2(W * 0.024 + float(ci2) * (W * 0.046), H * 0.106 + float(ri) * (H * 0.026), W * 0.040, H * 0.020), Color(0.06,0.48,0.14,0.55) if is_up else Color(0.55,0.10,0.10,0.55))
	# 4 monitör
	_draw_mon(W * 0.03, H * 0.20, W * 0.19, H * 0.36, 0)
	_draw_mon(W * 0.24, H * 0.16, W * 0.19, H * 0.40, 1)
	_draw_mon(W * 0.45, H * 0.20, W * 0.18, H * 0.36, 2)
	_draw_mon(W * 0.65, H * 0.23, W * 0.15, H * 0.32, 3)
	# Klavye
	draw_rect(Rect2(W * 0.12, H * 0.680, W * 0.22, H * 0.030), Color(0.038, 0.042, 0.060))
	for ki in 18:
		draw_rect(Rect2(W * 0.124 + float(ki) * (W * 0.011), H * 0.683, W * 0.009, H * 0.021), Color(0.068, 0.075, 0.105))
	# Ticker bant
	draw_rect(Rect2(W * 0.02, H * 0.621, W * 0.45, H * 0.020), Color(0.028, 0.032, 0.050))
	rng.seed = 3399
	for ti in 8:
		var tick_x := W * 0.025 + fmod(float(ti) * 110.0 + _t * 25.0, W * 0.42)
		draw_rect(Rect2(tick_x, H * 0.624, 85, H * 0.013), Color(0.06, 0.28, 0.10, 0.40) if ti % 3 != 0 else Color(0.28, 0.06, 0.06, 0.40))
	_draw_mug(W * 0.86, H * 0.715); _draw_phone(W * 0.22, H * 0.715)
	_draw_npc_sitting(W * 0.54, H * 0.68, Color(0.06, 0.08, 0.18))
	_draw_npc_sitting(W * 0.72, H * 0.68, Color(0.04, 0.06, 0.14))
	_draw_scan(W, H, 0.012)

# ── PENTHOUSE ─────────────────────────────────────────────────────────────────
func _bg_penthouse(W: float, H: float) -> void:
	# Derin lacivert, altın aksan
	for i in 12:
		var t_ := float(i) / 11.0
		draw_rect(Rect2(0, H * t_ / 12.0, W, H / 12.0 + 1), Color(lerp(0.032,0.020,t_), lerp(0.028,0.018,t_), lerp(0.038,0.028,t_)))
	draw_rect(Rect2(0, 0, W, H * 0.08), Color(0.042, 0.038, 0.052))
	for li in 6:
		var lx2 := W * (0.07 + float(li) * 0.165)
		draw_colored_polygon(PackedVector2Array([Vector2(lx2-80,H*0.08),Vector2(lx2+80,H*0.08),Vector2(lx2+110,H*0.28),Vector2(lx2-110,H*0.28)]), Color(0.86, 0.72, 0.38, 0.045))
		draw_circle(Vector2(lx2, H * 0.076), 6.5, Color(1.0, 0.90, 0.62, 0.92))
		draw_circle(Vector2(lx2, H * 0.076), 12.0, Color(1.0, 0.90, 0.62, 0.20))
	_draw_window(W * 0.02, H * 0.08, W * 0.96, H * 0.62, 3)
	for mi in 5:
		draw_rect(Rect2(W * 0.02 + float(mi + 1) * (W * 0.96 / 6.0), H * 0.08, 3.5, H * 0.62), Color(0.038, 0.034, 0.048))
	draw_rect(Rect2(W * 0.02, H * 0.08 + H * 0.62 * 0.50, W * 0.96, 3.5), Color(0.038, 0.034, 0.048))
	draw_rect(Rect2(W * 0.02 - 2, H * 0.08, 2, H * 0.62), Color(0.70, 0.55, 0.18, 0.35))
	draw_rect(Rect2(W * 0.98, H * 0.08, 2, H * 0.62), Color(0.70, 0.55, 0.18, 0.35))
	# Mermer zemin
	draw_rect(Rect2(0, H * 0.72, W, H - H * 0.72), Color(0.060, 0.054, 0.070))
	draw_rect(Rect2(0, H * 0.72, W, 3.5), Color(0.090, 0.082, 0.110))
	var rng := RandomNumberGenerator.new(); rng.seed = 7777
	for _vi in 6:
		var vpts := PackedVector2Array()
		var vx1 := rng.randf() * W; var vx2 := vx1 + rng.randf_range(-80, 80)
		var vcp1x := rng.randf() * W; var vcp2x := rng.randf() * W
		for vi2 in 14:
			var vf := float(vi2) / 13.0
			var u := 1.0 - vf
			var vxp := u*u*u*vx1 + 3*u*u*vf*vcp1x + 3*u*vf*vf*vcp2x + vf*vf*vf*vx2
			var vyp := H * 0.72 + vf * H * 0.28
			vpts.append(Vector2(vxp, vyp))
		if vpts.size() > 1:
			draw_polyline(vpts, Color(0.75, 0.68, 0.90, 0.06 + rng.randf() * 0.05), 0.8 + rng.randf() * 1.2)
	# Kavisli executive masa
	var dp := PackedVector2Array([Vector2(W*0.07,H*0.72),Vector2(W*0.07,H*0.618),Vector2(W*0.15,H*0.600),Vector2(W*0.45,H*0.588),Vector2(W*0.72,H*0.592),Vector2(W*0.92,H*0.608),Vector2(W*0.93,H*0.72)])
	draw_colored_polygon(dp, Color(0.038, 0.034, 0.050))
	draw_polyline(PackedVector2Array([Vector2(W*0.07,H*0.618),Vector2(W*0.15,H*0.600),Vector2(W*0.45,H*0.588),Vector2(W*0.72,H*0.592),Vector2(W*0.92,H*0.608)]), Color(0.70, 0.54, 0.16, 0.45), 2.8, false)
	# Kupa dolabı sol
	draw_rect(Rect2(W * 0.005, H * 0.08, W * 0.065, H * 0.52), Color(0.040, 0.036, 0.050))
	draw_rect(Rect2(W * 0.005, H * 0.08, W * 0.065, H * 0.52), Color(0.70, 0.55, 0.18, 0.28), false, 1.0)
	for si2 in 3:
		draw_rect(Rect2(W * 0.005, H * (0.22 + float(si2) * 0.14), W * 0.065, 2.5), Color(0.060, 0.054, 0.074))
		_draw_trophy(W * 0.035, H * (0.22 + float(si2) * 0.14))
	# Duvar sanatı sağ
	_draw_wall_art(W * 0.82, H * 0.10, 150, 110)
	# 5 monitör
	var mpos := [[W*0.05,H*0.19,W*0.17,H*0.38],[W*0.23,H*0.14,W*0.17,H*0.42],[W*0.42,H*0.12,W*0.18,H*0.45],[W*0.62,H*0.14,W*0.17,H*0.42],[W*0.80,H*0.19,W*0.14,H*0.38]]
	for mi2 in mpos.size():
		_draw_mon(mpos[mi2][0], mpos[mi2][1], mpos[mi2][2], mpos[mi2][3], mi2)
	_draw_whisky(W * 0.88, H * 0.702); _draw_phone(W * 0.28, H * 0.707)
	_draw_ashtray(W * 0.76, H * 0.720); _draw_cigar(W * 0.762, H * 0.714)
	_draw_trophy(W * 0.92, H * 0.717)
	_draw_npc_executive(W * 0.52, H * 0.720)
	_draw_npc_advisor(W * 0.63, H * 0.720)
	_draw_scan(W, H, 0.008)

# ── WORLD MAP ─────────────────────────────────────────────────────────────────
func _draw_map(W: float, H: float) -> void:
	# Ocean
	draw_rect(Rect2(0,0,W,H), Color(0.03,0.07,0.15))
	var ml:=36.0; var mt:=58.0; var mw:=W-72.0; var mh:=H-118.0
	_map_bounds = {"ml":ml,"mt":mt,"mw":mw,"mh":mh}
	# Subtle grid
	for gi in 8:
		var gx:=ml+float(gi+1)/9.0*mw
		draw_line(Vector2(gx,mt),Vector2(gx,mt+mh),Color(0.12,0.18,0.30,0.25),0.5)
	for gi in 5:
		var gy:=mt+float(gi+1)/6.0*mh
		draw_line(Vector2(ml,gy),Vector2(ml+mw,gy),Color(0.12,0.18,0.30,0.25),0.5)
	# Equator
	draw_line(Vector2(ml,mt+mh*0.5),Vector2(ml+mw,mt+mh*0.5),Color(0.25,0.42,0.68,0.45),0.8)
	# Map frame
	draw_rect(Rect2(ml-1,mt-1,mw+2,mh+2),Color(0.22,0.34,0.55,0.55),false,1.0)

	var font := ThemeDB.fallback_font

	# Render all country polygons from CountryShapes data
	for cid in _country_polys:
		var polys = _country_polys[cid]
		var c := CountrySystem.find_country(cid)
		var owned := CountrySystem.is_owned(cid)
		var hov   = _hovered_country == cid
		var base: Color
		if c.is_empty():
			base = Color(0.20, 0.23, 0.30)
		else:
			base = Color.from_string(CountrySystem.get_color(cid), Color(0.22,0.25,0.32))
		var fill: Color
		if owned:
			fill = Color(0.18, 0.76, 0.38, 0.92)
		elif hov:
			fill = Color(minf(base.r+0.28,1.0), minf(base.g+0.28,1.0), minf(base.b+0.28,1.0), 0.95)
		else:
			fill = Color(base.r*0.52, base.g*0.52, base.b*0.52, 0.82)
		var bord: Color
		if owned:   bord = Color(0.28,0.96,0.52,0.90)
		elif hov:   bord = Color(0.80,0.90,1.0,0.92)
		else:       bord = Color(0.07,0.09,0.14,0.70)
		for pts in polys:
			var sp := PackedVector2Array()
			for p in pts: sp.append(Vector2(ml+p.x*mw, mt+p.y*mh))
			if sp.size() >= 3:
				draw_colored_polygon(sp, fill)
				draw_polyline(sp, bord, 0.6, true)

	# Labels for hovered / owned countries
	for c in CountrySystem.get_all():
		var cid = c["id"]
		var owned := CountrySystem.is_owned(cid)
		var hov   = _hovered_country == cid
		if not (hov or owned): continue
		if not _country_polys.has(cid): continue
		var polys = _country_polys[cid]
		if polys.is_empty(): continue
		var cx_s:=0.0; var cy_s:=0.0; var nn:=0
		for p in polys[0]: cx_s+=p.x; cy_s+=p.y; nn+=1
		if nn == 0: continue
		var lp := Vector2(ml+(cx_s/nn)*mw, mt+(cy_s/nn)*mh)
		draw_string(font, lp, c["name"], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1,1,1,0.96))
		if not owned:
			draw_string(font, Vector2(lp.x, lp.y+14), "$%sM" % str(c["price"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.95,0.88,0.40,0.92))

	# Title and owned count
	draw_string(font, Vector2(ml,mt-36), _txt("MAP_LABEL"),
		HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(0.65,0.75,0.92,0.92))
	draw_string(font, Vector2(W-260,mt-36),
		_txt("MAP_OWNED") % [CountrySystem.owned.size(), CountrySystem.COUNTRIES.size()],
		HORIZONTAL_ALIGNMENT_LEFT,-1,11,CO)

	# ── Global influence bar (GDP 50% + Population 50% weighted) ─────────────
	var total_gdp := 0.0; var total_pop := 0.0
	for c2 in CountrySystem.COUNTRIES:
		total_gdp += float(c2["gdp"]); total_pop += float(c2["pop"])
	var owned_w := 0.0
	for oid in CountrySystem.owned:
		var oc := CountrySystem.find_country(oid)
		if not oc.is_empty():
			owned_w += 0.5*(float(oc["gdp"])/total_gdp) + 0.5*(float(oc["pop"])/total_pop)
	var dom_pct := clampf(owned_w * 100.0, 0.0, 100.0)
	var bx := ml; var by_ := mt - 22.0; var bw := mw; var bh := 10.0
	draw_rect(Rect2(bx, by_, bw, bh), Color(0.06,0.09,0.16))
	if dom_pct > 0.0:
		var fill_w := bw * (dom_pct / 100.0)
		var t := dom_pct / 100.0
		var bar_col := Color(0.18+0.62*t, 0.55-0.1*t, 0.95-0.55*t, 0.90)
		draw_rect(Rect2(bx, by_, fill_w, bh), bar_col)
	draw_rect(Rect2(bx, by_, bw, bh), Color(0.30,0.45,0.70,0.45), false, 0.8)
	var dom_lbl := "GLOBAL INFLUENCE:  %.2f%%" % dom_pct
	draw_string(font, Vector2(bx + bw*0.5, by_ + bh - 1.0), dom_lbl,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.90,0.92,1.0,0.95))
	_draw_buildings_on_map(ml, mt, mw, mh)
	_draw_mega_markers(ml, mt, mw, mh)
	_draw_scan(W, H, 0.02)

func _gui_input(event: InputEvent) -> void:
	if not _map_panel or not _map_panel.visible: return
	if event is InputEventMouseMotion:
		_hovered_country = _country_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var bid := _building_at(event.position)
		if bid != "": _show_building_popup(bid); return
		var mid := _mega_at(event.position)
		if mid != "": _show_mega_popup(mid); return
		var cid := _country_at(event.position)
		if cid != "": _show_country_popup(cid)

func _country_at(pos: Vector2) -> String:
	var W := size.x; var H := size.y
	var ml:=36.0; var mt:=58.0; var mw:=W-72.0; var mh:=H-118.0
	var nx := (pos.x - ml) / mw
	var ny := (pos.y - mt) / mh
	if nx < 0.0 or nx > 1.0 or ny < 0.0 or ny > 1.0: return ""
	var pt := Vector2(nx, ny)
	for c in CountrySystem.get_all():
		var cid = c["id"]
		if not _country_bbox.has(cid): continue
		var bb = _country_bbox[cid]
		if nx < bb.x0 or nx > bb.x1 or ny < bb.y0 or ny > bb.y1: continue
		for pts in _country_polys[cid]:
			if _point_in_polygon(pt, pts): return cid
	return ""

func _point_in_polygon(pt: Vector2, poly: PackedVector2Array) -> bool:
	var n := poly.size()
	if n < 3: return false
	var inside := false
	var j := n - 1
	for i in n:
		var xi := poly[i].x; var yi := poly[i].y
		var xj := poly[j].x; var yj := poly[j].y
		if ((yi > pt.y) != (yj > pt.y)) and (pt.x < (xj - xi) * (pt.y - yi) / (yj - yi) + xi):
			inside = !inside
		j = i
	return inside

# ── SHARED DRAW HELPERS ────────────────────────────────────────────────────────
func _draw_window(wx:float,wy:float,ww:float,wh:float,d:int) -> void:
	for i in 12:
		var t_:=float(i)/12.0
		draw_rect(Rect2(wx,wy+wh*t_,ww,wh/12.0+1),
			Color(lerp(0.04,0.09,t_),lerp(0.05,0.04,t_),lerp(0.14,0.07,t_)))
	for s in _stars:
		var br=0.35+0.50*abs(sin(_t*s["sp"]+s["ph"]))
		draw_circle(Vector2(wx+s["x"]*ww,wy+s["y"]*wh*0.46), s["r"], Color(1,1,1,br*0.72))
	var mr:=22.0+d*2; var mx:=wx+ww*0.82; var my:=wy+wh*0.14
	draw_circle(Vector2(mx,my), mr+6, Color(0.95,0.92,0.78,0.10))
	draw_circle(Vector2(mx,my), mr,   Color(0.96,0.94,0.82,0.92))
	draw_circle(Vector2(mx+9,my-5), mr-4, Color(0.04,0.05,0.11,0.90))
	var rng:=RandomNumberGenerator.new(); rng.seed=77665+d*100
	var sil:=PackedVector2Array()
	sil.append(Vector2(wx,wy+wh)); sil.append(Vector2(wx,wy+wh*0.60))
	var cx_:=wx
	while cx_<wx+ww+60:
		var bw:=rng.randf_range(18+d*5,55+d*12); var bh:=rng.randf_range(wh*0.06,wh*(0.25+d*0.05))
		var by_:=wy+wh-bh
		sil.append(Vector2(cx_,by_)); sil.append(Vector2(cx_+bw*0.3,by_-rng.randf_range(0,bh*0.18)))
		sil.append(Vector2(cx_+bw,by_)); cx_+=bw
	sil.append(Vector2(wx+ww,wy+wh*0.60)); sil.append(Vector2(wx+ww,wy+wh))
	draw_colored_polygon(sil, Color(0.075,0.082,0.120))
	for l in _lights:
		var lx_=wx+l["x"]*ww; var ly_=l["y"]*size.y
		if lx_<wx or lx_>wx+ww or ly_<wy+wh*0.50 or ly_>wy+wh: continue
		var a_:=0.92; if l["blink"]: a_=0.55+0.45*abs(sin(_t*l["sp"]+l["ph"]))
		draw_rect(Rect2(lx_,ly_,l["w"]*ww,l["h"]*wh*0.45), Color(l["r"],l["g"],l["b"],a_))
	for r in _rain:
		var ry_:=fmod(r["oy"]+_t*r["spd"],wh*1.3)+wy-wh*0.1
		if ry_<wy or ry_>wy+wh: continue
		draw_line(Vector2(wx+r["x"]*ww,ry_),Vector2(wx+r["x"]*ww+2,ry_+r["len"]),Color(0.55,0.70,0.95,0.07),1.0)
	var fw:=5.0 if d<3 else 3.0; var fc:=Color(0.09,0.10,0.14)
	draw_rect(Rect2(wx-fw,wy-fw,ww+fw*2,fw),fc); draw_rect(Rect2(wx-fw,wy+wh,ww+fw*2,fw),fc)
	draw_rect(Rect2(wx-fw,wy-fw,fw,wh+fw*2),fc); draw_rect(Rect2(wx+ww,wy-fw,fw,wh+fw*2),fc)
	if d<3:
		draw_rect(Rect2(wx+ww*0.5,wy,fw*0.8,wh),fc)
		draw_rect(Rect2(wx,wy+wh*0.50,ww,fw*0.8),fc)
	draw_line(Vector2(wx+14,wy+8),Vector2(wx+ww*0.22,wy+wh*0.24),Color(1,1,1,0.05),20.0)

func _draw_crt(mx:float,my:float,mw:float,mh:float) -> void:
	draw_rect(Rect2(mx-12,my-8,mw+24,mh+28),Color(0.20,0.19,0.17))
	draw_rect(Rect2(mx-6,my-4,mw+12,mh+16),Color(0.14,0.13,0.12))
	draw_rect(Rect2(mx,my,mw,mh),Color(0.03,0.10,0.06))
	for i in 8: draw_rect(Rect2(mx,my+mh*float(i)/8.0,mw,mh/16.0),Color(0.10,0.55,0.22,0.08))
	var rng:=RandomNumberGenerator.new(); rng.seed=44556
	for i in 7: draw_rect(Rect2(mx+6,my+mh*(0.10+float(i)*0.12),mw*rng.randf_range(0.2,0.75),2.5),Color(0.15,0.85,0.32,0.45))
	draw_arc(Vector2(mx+mw/2,my+mh/2),mw*0.52,0,TAU,32,Color(0,0,0,0.22),6.0)
	draw_rect(Rect2(mx+mw*0.35,my+mh+8,mw*0.30,10),Color(0.18,0.17,0.15))

func _draw_mon(mx:float,my:float,mw:float,mh:float,idx:int) -> void:
	var H := size.y
	draw_rect(Rect2(mx+mw*0.44,my+mh,mw*0.12,H*0.022),Color(0.12,0.12,0.15))
	draw_rect(Rect2(mx+mw*0.34,my+mh+H*0.022,mw*0.30,H*0.010),Color(0.10,0.10,0.13))
	draw_rect(Rect2(mx-7,my-7,mw+14,mh+14),Color(0.10,0.10,0.14))
	draw_rect(Rect2(mx-4,my-4,mw+8,mh+8),Color(0.08,0.08,0.11))
	var sc=[Color(0.04,0.14,0.30),Color(0.04,0.16,0.10),Color(0.14,0.06,0.22),
		Color(0.06,0.12,0.26),Color(0.04,0.14,0.08),Color(0.12,0.08,0.18)][idx%6]
	draw_rect(Rect2(mx,my,mw,mh),sc); draw_rect(Rect2(mx-2,my-2,mw+4,mh+4),Color(sc.r,sc.g,sc.b,0.14))
	var pts:=PackedVector2Array(); var rng2:=RandomNumberGenerator.new(); rng2.seed=9900+idx*77
	for i in 16:
		pts.append(Vector2(mx+mw*(0.06+float(i)/15.0*0.88),
			my+mh*(0.35+rng2.randf_range(-0.18,0.18)+0.04*sin(_t*0.28+idx+float(i)*0.4))))
	if pts.size()>1:
		draw_polyline(pts,Color(0.22,0.90,0.50,0.65) if idx%2==0 else Color(0.90,0.30,0.30,0.65),1.5,true)
	var rng3:=RandomNumberGenerator.new(); rng3.seed=1234+idx*33
	for i in 5: draw_rect(Rect2(mx+mw*0.05,my+mh*(0.62+float(i)*0.07),mw*rng3.randf_range(0.18,0.72),2),Color(0.55,0.60,0.80,0.18))
	draw_circle(Vector2(mx+mw-9,my+mh-7),2.8,Color(0.22,0.88,0.48,0.60+0.40*sin(_t*1.6+idx*1.2)))

func _draw_lamp(lx:float,by_:float) -> void:
	var ly:=by_-size.y*0.22
	draw_rect(Rect2(lx-18,by_-4,36,6),Color(0.16,0.15,0.14))
	draw_rect(Rect2(lx-2,by_-4,4,-(by_-ly-44)),Color(0.19,0.18,0.16))
	draw_line(Vector2(lx,ly+44),Vector2(lx-22,ly),Color(0.19,0.18,0.16),4.5)
	draw_colored_polygon(PackedVector2Array([Vector2(lx-32,ly),Vector2(lx+14,ly),Vector2(lx+8,ly+20),Vector2(lx-26,ly+20)]),Color(0.25,0.21,0.16))
	draw_colored_polygon(PackedVector2Array([Vector2(lx-30,ly+20),Vector2(lx+12,ly+20),Vector2(lx+64,by_-4),Vector2(lx-80,by_-4)]),Color(1.0,0.94,0.70,0.042))
	draw_circle(Vector2(lx-10,ly+10),6,Color(1.0,0.97,0.80,0.94))

func _draw_mug(cx:float,by_:float) -> void:
	var mh:=32.0; var mw:=26.0; var cy:=by_-mh
	draw_rect(Rect2(cx-mw/2,cy,mw,mh),Color(0.20,0.17,0.16))
	draw_rect(Rect2(cx-mw/2-1,cy,mw+2,3),Color(0.30,0.25,0.22))
	draw_arc(Vector2(cx+mw/2,cy+mh*0.48),mh*0.38,-PI*0.42,PI*0.42,14,Color(0.17,0.15,0.14),3.0)
	for i in 3:
		for j in 6:
			var ph:=_t*1.1+(i as float)*0.9+(j as float)*0.3
			draw_line(Vector2(cx-5.0+i*5.0+sin(ph)*3.5,cy-5-j*4.5),
				Vector2(cx-5.0+i*5.0+sin(ph+0.4)*3.5,cy-5-(j+1)*4.5),
				Color(0.82,0.82,0.88,maxf(0.0,0.07-j*0.010)),1.5)

func _draw_papers(px:float,py:float) -> void:
	for i in 4: draw_rect(Rect2(px+i*2.5,py-i*2-2,120,22),Color(0.88-i*0.02,0.87-i*0.02,0.83-i*0.02,0.68))
	var rng:=RandomNumberGenerator.new(); rng.seed=8899
	for j in 5: draw_rect(Rect2(px+8,py-j*5-4,rng.randf_range(40,90),1.5),Color(0.48,0.46,0.42,0.28))

func _draw_phone(px: float, by_: float) -> void:
	var RED  := Color(0.78, 0.08, 0.08)
	var DRED := Color(0.46, 0.04, 0.04)
	var LRED := Color(0.95, 0.42, 0.42, 0.55)
	# Body (trapezoid)
	var bw := 42.0; var bh := 18.0
	var bpts := PackedVector2Array([
		Vector2(px - bw*0.50, by_), Vector2(px + bw*0.50, by_),
		Vector2(px + bw*0.44, by_ - bh), Vector2(px - bw*0.44, by_ - bh)])
	draw_colored_polygon(bpts, RED)
	draw_line(Vector2(px - bw*0.42, by_ - bh + 1), Vector2(px + bw*0.42, by_ - bh + 1), LRED, 1.5)
	draw_polyline(PackedVector2Array([bpts[3], bpts[0], bpts[1], bpts[2]]), DRED, 1.0)
	# Rotary dial
	var dc := Vector2(px + 8, by_ - bh * 0.52)
	draw_circle(dc, 7.5, DRED)
	for di in 6:
		var ang := float(di) / 6.0 * TAU
		draw_circle(Vector2(dc.x + cos(ang)*5.0, dc.y + sin(ang)*5.0), 1.5, Color(0,0,0,0.5))
	draw_circle(dc, 2.0, Color(0,0,0,0.4))
	# Earpiece ends on cradle
	draw_rect(Rect2(px - bw*0.44, by_ - bh - 14, 12, 10), DRED)
	draw_rect(Rect2(px + bw*0.44 - 12, by_ - bh - 14, 12, 10), DRED)
	# Handset arc
	var hpts := PackedVector2Array()
	for i in 13:
		var f := float(i) / 12.0
		hpts.append(Vector2((px - bw*0.38) + f*bw*0.76, by_ - bh - 10 - sin(f*PI)*10))
	draw_polyline(hpts, DRED, 5.5)
	# Highlight on handset
	var hlpts := PackedVector2Array()
	for i in 9:
		var f := float(i) / 8.0
		hlpts.append(Vector2((px - bw*0.30) + f*bw*0.60, by_ - bh - 12 - sin(f*PI)*8))
	draw_polyline(hlpts, Color(RED.r+0.15, RED.g+0.05, RED.b+0.05, 0.55), 2.0)

func _draw_whisky(cx:float,by_:float) -> void:
	var pts:=PackedVector2Array([Vector2(cx-14,by_),Vector2(cx-10,by_-28),Vector2(cx+10,by_-28),Vector2(cx+14,by_)])
	draw_colored_polygon(pts,Color(0.80,0.60,0.18,0.32)); draw_polyline(pts,Color(0.90,0.75,0.35,0.65),1.5,true)
	draw_rect(Rect2(cx-5,by_-22,10,10),Color(0.80,0.90,1.0,0.45))

func _draw_scan(W:float,H:float,str:float) -> void:
	var y:=0.0
	while y<H: draw_line(Vector2(0,y),Vector2(W,y),Color(0,0,0,0.018),1.0); y+=4.0
	var d:=W*(0.04+str*0.5)
	draw_rect(Rect2(0,0,d,H),Color(0,0,0,0.10+str*0.5)); draw_rect(Rect2(W-d,0,d,H),Color(0,0,0,0.10+str*0.5))
	draw_rect(Rect2(0,0,W,H*0.03),Color(0,0,0,0.08)); draw_rect(Rect2(0,H*0.97,W,H*0.03),Color(0,0,0,0.08))

func _draw_desk_trophies(right_x: float, base_y: float) -> void:
	var owned_b: Array = BuildingSystem.BUILDINGS.filter(func(b): return BuildingSystem.is_owned(b["id"]))
	if owned_b.is_empty(): return
	var ih := 72.0; var iw := 48.0; var gap := 10.0
	var x := right_x - iw
	for b in owned_b:
		var tex := BuildingSystem.get_texture(b["id"])
		if tex:
			draw_texture_rect(tex, Rect2(x, base_y - ih, iw, ih), false)
		else:
			draw_rect(Rect2(x + 2, base_y - ih + 4, iw - 4, ih - 8), Color(0.55, 0.55, 0.70, 0.80))
		x -= (iw + gap)

# ── YENİ YARDIMCILAR ──────────────────────────────────────────────────────────

func _draw_lamp_colored(lx: float, by_: float) -> void:
	var ly := by_ - size.y * 0.21
	draw_rect(Rect2(lx-22,by_-5,44,7), Color(0.105, 0.088, 0.055))
	draw_rect(Rect2(lx-2.5,by_-5,5,-(by_-ly-46)), Color(0.130, 0.108, 0.068))
	draw_line(Vector2(lx,ly+46), Vector2(lx-24,ly), Color(0.130, 0.108, 0.068), 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(lx-34,ly),Vector2(lx+16,ly),Vector2(lx+10,ly+24),Vector2(lx-28,ly+24)]), Color(0.18, 0.12, 0.04))
	draw_circle(Vector2(lx-10, ly+12), 7.0, Color(1.0, 0.95, 0.72, 0.95))
	draw_circle(Vector2(lx-10, ly+12), 14.0, Color(1.0, 0.92, 0.60, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(lx-28,ly+24),Vector2(lx+10,ly+24),Vector2(lx+70,by_-5),Vector2(lx-88,by_-5)]), Color(1.0, 0.92, 0.60, 0.038))

func _draw_trophy(cx: float, by_: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-11,by_-32),Vector2(cx+11,by_-32),Vector2(cx+14,by_-18),Vector2(cx-14,by_-18)]), Color(0.78, 0.62, 0.12))
	draw_arc(Vector2(cx-12, by_-25), 5.5, PI*0.5, PI*1.5, 8, Color(0.68, 0.52, 0.08), 3.0)
	draw_arc(Vector2(cx+12, by_-25), 5.5, -PI*0.5, PI*0.5, 8, Color(0.68, 0.52, 0.08), 3.0)
	draw_circle(Vector2(cx, by_-32), 8.0, Color(0.72, 0.56, 0.10))
	draw_rect(Rect2(cx-3.5,by_-18,7,12), Color(0.58, 0.44, 0.08))
	draw_rect(Rect2(cx-12,by_-6,24,6), Color(0.50, 0.38, 0.06))
	draw_rect(Rect2(cx-12,by_-6,24,2), Color(0.82, 0.68, 0.18))

func _draw_ashtray(cx: float, by_: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-20,by_),Vector2(cx+20,by_),Vector2(cx+14,by_-8),Vector2(cx-14,by_-8)]), Color(0.095, 0.088, 0.072))
	draw_circle(Vector2(cx, by_-5), 10.0, Color(0.130, 0.120, 0.100))
	draw_circle(Vector2(cx, by_-5), 6.5, Color(0.065, 0.060, 0.050))
	draw_rect(Rect2(cx-18,by_-7,22,3.5), Color(0.82, 0.78, 0.60))
	draw_rect(Rect2(cx-18,by_-7,5,3.5), Color(0.42, 0.40, 0.30))

func _draw_cigar(cx: float, by_: float) -> void:
	draw_rect(Rect2(cx-28,by_-3,50,6), Color(0.28, 0.15, 0.06))
	draw_rect(Rect2(cx-28,by_-3,9,6), Color(0.52, 0.50, 0.48))
	var ember := 0.55 + 0.45 * sin(_t * 2.4)
	draw_circle(Vector2(cx-28, by_), 3.5, Color(1.0, 0.38, 0.06, ember * 0.85))
	draw_circle(Vector2(cx-28, by_), 6.0, Color(1.0, 0.20, 0.02, ember * 0.25))
	for dsi in 4:
		var ds_y := by_ - 4.0 - float(dsi) * 9.0
		var ds_x := cx - 28.0 + sin(_t * 0.7 + float(dsi) * 1.3) * 5.0
		draw_circle(Vector2(ds_x, ds_y), 3.5 + float(dsi) * 1.8, Color(0.70, 0.70, 0.72, 0.055 - float(dsi) * 0.010))

func _draw_wall_photo(wx3: float, wy3: float, w3: float, h3: float) -> void:
	draw_rect(Rect2(wx3, wy3, w3, h3), Color(0.098, 0.072, 0.038))
	draw_rect(Rect2(wx3+5, wy3+5, w3-10, h3-10), Color(0.060, 0.055, 0.048))
	draw_rect(Rect2(wx3+8, wy3+8, w3-16, h3-16), Color(0.028, 0.038, 0.062))
	var sil := PackedVector2Array()
	var rng2 := RandomNumberGenerator.new(); rng2.seed = 77765
	sil.append(Vector2(wx3+8, wy3+h3-8)); sil.append(Vector2(wx3+8, wy3+8+(h3-16)*0.60))
	var cx2_ := wx3+8.0
	while cx2_ < wx3+w3-8:
		var bw4 := rng2.randf_range(8,18); var bh4 := (h3-16) * rng2.randf_range(0.06, 0.22)
		sil.append(Vector2(cx2_, wy3+h3-8-bh4)); sil.append(Vector2(cx2_+bw4, wy3+h3-8-bh4)); cx2_ += bw4
	sil.append(Vector2(wx3+w3-8, wy3+8+(h3-16)*0.60)); sil.append(Vector2(wx3+w3-8, wy3+h3-8))
	if sil.size() >= 3: draw_colored_polygon(sil, Color(0.042, 0.032, 0.020))
	draw_rect(Rect2(wx3, wy3, w3, h3), Color(0.640, 0.520, 0.260, 0.45), false, 1.0)

func _draw_wall_certificate(wx4: float, wy4: float, w4: float, h4: float) -> void:
	draw_rect(Rect2(wx4, wy4, w4, h4), Color(0.098, 0.072, 0.038))
	draw_rect(Rect2(wx4+4, wy4+4, w4-8, h4-8), Color(0.88, 0.82, 0.64))
	draw_rect(Rect2(wx4+8, wy4+8, w4-16, 3), Color(0.20, 0.14, 0.06, 0.6))
	var rng3 := RandomNumberGenerator.new(); rng3.seed = 8877
	for li2 in 5:
		draw_rect(Rect2(wx4+8, wy4+16+float(li2)*10, rng3.randf_range(50, w4-20), 1.8), Color(0.20, 0.14, 0.06, 0.45))
	draw_arc(Vector2(wx4+w4-22, wy4+h4-20), 12.0, 0, TAU, 24, Color(0.60, 0.42, 0.10, 0.50), 1.5)
	draw_rect(Rect2(wx4, wy4, w4, h4), Color(0.640, 0.520, 0.260, 0.40), false, 1.0)

func _draw_wall_art(ax: float, ay: float, aw: float, ah: float) -> void:
	draw_rect(Rect2(ax, ay, aw, ah), Color(0.042, 0.038, 0.052))
	draw_rect(Rect2(ax+4, ay+4, aw-8, ah-8), Color(0.022, 0.020, 0.030))
	var apts := PackedVector2Array()
	for ai in 20:
		var af := float(ai) / 19.0
		apts.append(Vector2(ax+8+af*(aw-16), ay+8+(ah-16)*(0.5+0.4*sin(af*PI*2.2))))
	if apts.size() > 1: draw_polyline(apts, Color(0.78, 0.60, 0.14, 0.75), 2.0, true)
	draw_circle(Vector2(ax+aw/2, ay+ah/2), minf(aw,ah)*0.22, Color(0.78, 0.60, 0.14, 0.12))
	draw_arc(Vector2(ax+aw/2, ay+ah/2), minf(aw,ah)*0.22, 0, TAU, 32, Color(0.78, 0.60, 0.14, 0.40), 1.0)
	draw_rect(Rect2(ax, ay, aw, ah), Color(0.70, 0.55, 0.18, 0.32), false, 1.0)

func _draw_npc_hunched(cx: float, by_: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-18,by_+2),Vector2(cx+22,by_+2),Vector2(cx+20,by_+6),Vector2(cx-16,by_+6)]), Color(0,0,0,0.22))
	var sway := sin(_t * 0.4) * 1.5
	draw_colored_polygon(PackedVector2Array([Vector2(cx-15,by_-28),Vector2(cx-16,by_-55),Vector2(cx+6,by_-60+sway),Vector2(cx+13,by_-45+sway),Vector2(cx+13,by_-28)]), Color(0.085, 0.085, 0.085))
	draw_circle(Vector2(cx+6, by_-66+sway), 12.0, Color(0.62, 0.50, 0.36))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-3,by_-75+sway),Vector2(cx+15,by_-74+sway),Vector2(cx+18,by_-62+sway),Vector2(cx-2,by_-63+sway)]), Color(0.140, 0.095, 0.050))
	draw_line(Vector2(cx-13,by_-35), Vector2(cx-4,by_-10), Color(0.085, 0.085, 0.085), 7.0)
	draw_line(Vector2(cx+11,by_-40+sway), Vector2(cx+20,by_-10), Color(0.085, 0.085, 0.085), 7.0)

func _draw_npc_standing(cx: float, by_: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-16,by_+2),Vector2(cx+16,by_+2),Vector2(cx+14,by_+6),Vector2(cx-14,by_+6)]), Color(0,0,0,0.20))
	var sway := sin(_t * 0.5) * 1.0
	draw_rect(Rect2(cx-9,by_-52,8,52), Color(0.060, 0.060, 0.085))
	draw_rect(Rect2(cx+1,by_-52,8,52), Color(0.060, 0.060, 0.085))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-15,by_-52),Vector2(cx+15,by_-52),Vector2(cx+13+sway,by_-98),Vector2(cx-13+sway,by_-98)]), Color(0.060, 0.060, 0.085))
	draw_rect(Rect2(cx-5+sway*0.5,by_-94,10,38), Color(0.88, 0.86, 0.92))
	draw_colored_polygon(PackedVector2Array([Vector2(cx+sway*0.5,by_-93),Vector2(cx-3.5+sway*0.5,by_-76),Vector2(cx+sway*0.5,by_-58),Vector2(cx+3.5+sway*0.5,by_-76)]), Color(0.58, 0.08, 0.08))
	draw_circle(Vector2(cx+sway, by_-109), 12.5, Color(0.68, 0.55, 0.38))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-11+sway,by_-116),Vector2(cx+11+sway,by_-116),Vector2(cx+13+sway,by_-107),Vector2(cx-13+sway,by_-107)]), Color(0.200, 0.130, 0.065))

func _draw_npc_sitting(cx: float, by_: float, suit_col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-14,by_+2),Vector2(cx+14,by_+2),Vector2(cx+12,by_+5),Vector2(cx-12,by_+5)]), Color(0,0,0,0.18))
	var sway := sin(_t * 0.4) * 1.0
	draw_colored_polygon(PackedVector2Array([Vector2(cx-13,by_),Vector2(cx+13,by_),Vector2(cx+11+sway,by_-45),Vector2(cx-11+sway,by_-45)]), suit_col)
	draw_rect(Rect2(cx-3.5+sway*0.5,by_-41,7,30), Color(0.78, 0.78, 0.86))
	draw_circle(Vector2(cx+sway, by_-57), 11.5, Color(0.65, 0.50, 0.34))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-11+sway,by_-64),Vector2(cx+11+sway,by_-64),Vector2(cx+12+sway,by_-56),Vector2(cx-12+sway,by_-56)]), Color(0.140, 0.095, 0.045))

func _draw_npc_executive(cx: float, by_: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-18,by_+2),Vector2(cx+18,by_+2),Vector2(cx+16,by_+6),Vector2(cx-16,by_+6)]), Color(0,0,0,0.28))
	var sway := sin(_t * 0.35) * 1.2
	draw_rect(Rect2(cx-10,by_-58,9,58), Color(0.028, 0.024, 0.038))
	draw_rect(Rect2(cx+1,by_-58,9,58), Color(0.028, 0.024, 0.038))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-16,by_-58),Vector2(cx+16,by_-58),Vector2(cx+14+sway,by_-105),Vector2(cx-14+sway,by_-105)]), Color(0.032, 0.028, 0.045))
	draw_rect(Rect2(cx-5+sway*0.5,by_-101,10,42), Color(0.92, 0.92, 0.96))
	draw_colored_polygon(PackedVector2Array([Vector2(cx+sway*0.5,by_-101),Vector2(cx-4+sway*0.5,by_-82),Vector2(cx+sway*0.5,by_-64),Vector2(cx+4+sway*0.5,by_-82)]), Color(0.72, 0.52, 0.10))
	draw_colored_polygon(PackedVector2Array([Vector2(cx+9+sway,by_-93),Vector2(cx+15+sway,by_-98),Vector2(cx+16+sway,by_-90)]), Color(0.72, 0.52, 0.10))
	draw_circle(Vector2(cx+sway, by_-117), 13.5, Color(0.70, 0.56, 0.38))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-13+sway,by_-126),Vector2(cx+13+sway,by_-126),Vector2(cx+14+sway,by_-116),Vector2(cx-14+sway,by_-116)]), Color(0.72, 0.72, 0.76))

func _draw_npc_advisor(cx: float, by_: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(cx-15,by_+2),Vector2(cx+15,by_+2),Vector2(cx+13,by_+5),Vector2(cx-13,by_+5)]), Color(0,0,0,0.22))
	var sway := sin(_t * 0.45) * 1.0
	draw_rect(Rect2(cx-9,by_-52,8,52), Color(0.038, 0.034, 0.050))
	draw_rect(Rect2(cx+1,by_-52,8,52), Color(0.038, 0.034, 0.050))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-13,by_-52),Vector2(cx+13,by_-52),Vector2(cx+11+sway,by_-96),Vector2(cx-11+sway,by_-96)]), Color(0.042, 0.038, 0.055))
	draw_rect(Rect2(cx-4+sway*0.5,by_-92,8,36), Color(0.84, 0.82, 0.90))
	draw_rect(Rect2(cx+15+sway,by_-82,26,34), Color(0.032, 0.028, 0.045))
	draw_rect(Rect2(cx+17+sway,by_-80,22,30), Color(0.055, 0.068, 0.105))
	for ali in 3:
		draw_rect(Rect2(cx+19+sway, by_-75+float(ali)*8, 14, 2), Color(0.40, 0.62, 1.0, 0.45))
	draw_circle(Vector2(cx+sway, by_-107), 12.0, Color(0.62, 0.48, 0.30))
	draw_colored_polygon(PackedVector2Array([Vector2(cx-12+sway,by_-116),Vector2(cx+12+sway,by_-116),Vector2(cx+13+sway,by_-107),Vector2(cx-13+sway,by_-107)]), Color(0.080, 0.055, 0.030))

# ═══════════════════════════════════════════════════════════════════════════════
# UI BUILD
# ═══════════════════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	# Subtle overlay — very low alpha so animated background shows clearly through UI panels
	var ov:=ColorRect.new(); ov.color=Color(0,0,0,0.08)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(ov)

	# ── Top bar ──────────────────────────────────────────────────────────────────
	var top:=_hb(6); top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom=64; _sbp(top,true); add_child(top)
	_g(top,12)
	# Financial info block (two-row layout)
	var info_v:=VBoxContainer.new(); info_v.add_theme_constant_override("separation",2); top.add_child(info_v)
	var ir1:=_hb(8); info_v.add_child(ir1)
	_date_lbl=_l("Jan 1, 1929",11,CM); ir1.add_child(_date_lbl)
	_off_lbl=_l("  📍 "+OfficeSystem.get_current()["name"],10,Color(0.50,0.55,0.68)); ir1.add_child(_off_lbl)
	var ir2:=_hb(10); info_v.add_child(ir2)
	var dot:=ColorRect.new(); dot.color=CG; dot.custom_minimum_size=Vector2(7,7)
	dot.size_flags_vertical=Control.SIZE_SHRINK_CENTER; ir2.add_child(dot)
	_cash_lbl=_l("$1.0M",19,CT,true); ir2.add_child(_cash_lbl)
	_nw_lbl=_l("NW $1.0M",12,CM); _nw_lbl.size_flags_vertical=Control.SIZE_SHRINK_CENTER; ir2.add_child(_nw_lbl)
	_inf_lbl=_l("Inf 0/5",11,CA); _inf_lbl.size_flags_vertical=Control.SIZE_SHRINK_CENTER; ir2.add_child(_inf_lbl)
	_rank_lbl=_l("#100+",11,CO); _rank_lbl.size_flags_vertical=Control.SIZE_SHRINK_CENTER; ir2.add_child(_rank_lbl)
	# Spacer
	var tf:=Control.new(); tf.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(tf)
	# View group — navigation, teal accent
	_bst(top,_txt("WORLD"),_toggle_map,CA)
	_bst(top,_txt("RANK"),_toggle_lb,CA)
	_bst(top,_txt("OFFICE_BTN"),_toggle_office_view,CA)
	_bst(top,_txt("ACH_BTN"),_toggle_ach,CA)
	_vsep(top)
	# Feature group — overlay panels, gold accent
	_bst(top,_txt("CONTACTS_BTN"),_toggle_contacts,CO)
	_bst(top,_txt("LUXURY_BTN"),_toggle_luxury,CO)
	_bst(top,_txt("TECH_BTN"),_toggle_tech,CO)
	_vsep(top)
	# System group — save/load/settings/menu
	_pause_btn=_b(_txt("PAUSE"),_on_pause); top.add_child(_pause_btn)
	_ba(top,_txt("SAVE"),_on_save); _ba(top,_txt("LOAD"),_on_load)
	_ba(top,_txt("SETTINGS"),_toggle_settings)
	_ba(top,_txt("MENU"),func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_g(top,10)

	# ── Bottom trading bar ────────────────────────────────────────────────────────
	var bot:=_hb(8); bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top=-70; _sbp(bot,false); add_child(bot)
	_g(bot,12)
	bot.add_child(_l(_txt("ASSET_LBL"),11,CM))
	_g(bot,4)
	_tick_sel=OptionButton.new(); _tick_sel.custom_minimum_size=Vector2(168,40); bot.add_child(_tick_sel)
	_g(bot,10)
	bot.add_child(_l(_txt("QTY_LBL"),11,CM))
	_g(bot,4)
	_qty_in=SpinBox.new(); _qty_in.min_value=1; _qty_in.max_value=999999
	_qty_in.value=10; _qty_in.step=1; _qty_in.custom_minimum_size=Vector2(114,40); bot.add_child(_qty_in)
	_g(bot,14)
	var buy_b:=_b(_txt("BUY_BTN"),_on_buy)
	buy_b.custom_minimum_size=Vector2(100,40)
	_bcolor(buy_b,Color(0.10,0.38,0.20,0.95),Color(0.18,0.60,0.22),CG)
	bot.add_child(buy_b)
	_g(bot,6)
	var sel_b:=_b(_txt("SELL_BTN"),_on_sell)
	sel_b.custom_minimum_size=Vector2(100,40)
	_bcolor(sel_b,Color(0.38,0.10,0.10,0.95),Color(0.65,0.18,0.18),CR)
	bot.add_child(sel_b)
	_g(bot,14)
	_msg_lbl=_l(_txt("TIME_MSG"),12,CM)
	_msg_lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bot.add_child(_msg_lbl)
	_g(bot,10)

	# ── Content columns (stored so map can hide/show them) ────────────────────
	_content_columns=HBoxContainer.new()
	_content_columns.set_anchor_and_offset(SIDE_LEFT,0,0); _content_columns.set_anchor_and_offset(SIDE_RIGHT,1,0)
	_content_columns.set_anchor_and_offset(SIDE_TOP,0,64); _content_columns.set_anchor_and_offset(SIDE_BOTTOM,1,-70)
	_content_columns.add_theme_constant_override("separation",0); add_child(_content_columns)

	# Left panel
	var left:=_sp(308); _content_columns.add_child(left)
	var lv:=VBoxContainer.new(); lv.size_flags_vertical=Control.SIZE_EXPAND_FILL; left.add_child(lv)
	lv.add_child(_sh(_txt("LIVE_MARKETS")))
	var ts:=ScrollContainer.new(); ts.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ts.custom_minimum_size=Vector2(0,180); lv.add_child(ts)
	_ticker_list=VBoxContainer.new(); _ticker_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ts.add_child(_ticker_list)
	var ph:=_hb(6); ph.add_child(_sh(_txt("PORTFOLIO")))
	var pff:=Control.new(); pff.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ph.add_child(pff)
	var pdb:=_b(_txt("DETAILS"),_toggle_portfolio); pdb.add_theme_font_size_override("font_size",11); ph.add_child(pdb); lv.add_child(ph)
	var ps:=ScrollContainer.new(); ps.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ps.custom_minimum_size=Vector2(0,90); lv.add_child(ps)
	_port_list=VBoxContainer.new(); _port_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ps.add_child(_port_list)
	_office_card_ctrl = _office_card(); lv.add_child(_office_card_ctrl)
	_company_card_ctrl = _company_card(); lv.add_child(_company_card_ctrl)

	# Center (chart)
	var ctr:=VBoxContainer.new(); ctr.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ctr.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var csb:=StyleBoxFlat.new(); csb.bg_color=Color(0.02,0.025,0.04,0.32)
	csb.border_color = CB
	csb.border_width_left = 1
	csb.border_width_right = 1
	ctr.add_theme_stylebox_override("panel",csb); _content_columns.add_child(ctr)
	var chm:=MarginContainer.new()
	chm.add_theme_constant_override("margin_left",10)
	chm.add_theme_constant_override("margin_top",5); chm.add_theme_constant_override("margin_bottom",5)
	var ch:=_hb(8); chm.add_child(ch); ctr.add_child(chm)
	_sel_lbl=_l(_txt("SELECT_ASSET"),12,CM); ch.add_child(_sel_lbl)
	_chart=ChartControl.new(); _chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_chart.size_flags_vertical=Control.SIZE_EXPAND_FILL; _chart.set_ticker(_sel_ticker); ctr.add_child(_chart)

	# Right panel removed — news delivered via weekly newspaper popup

	# Map must be added first so all overlay panels sit on top of it in z-order
	_build_map_panel()
	# Overlay panels (drawn on top of everything)
	_build_contacts_panel()
	_build_portfolio_panel()
	_build_lb_panel()
	_build_settings_panel()
	_build_spec_panel()
	_build_council_panel()
	_build_luxury_panel()
	_build_tech_panel()
	_build_ach_panel()
	_build_trade_popup()

func _build_contacts_panel() -> void:
	_contacts_panel=_ovp(0.24,0.99,0.97,CA); add_child(_contacts_panel)
	var v:=VBoxContainer.new(); _contacts_panel.add_child(v)
	var mg:=_mg12(v); var hh:=_hb(8); mg.add_child(hh)
	hh.add_child(_l(_txt("CONTACTS_TITLE"),13,CA,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f)
	_ba(hh,"✕",_toggle_contacts)
	var cs:=ScrollContainer.new(); cs.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(cs)
	_contacts_list=VBoxContainer.new(); _contacts_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_contacts_list.add_theme_constant_override("separation",10); cs.add_child(_contacts_list)

func _build_portfolio_panel() -> void:
	_port_panel=_ovp(0.24,0.76,0.96,CB); add_child(_port_panel)
	var v:=VBoxContainer.new(); _port_panel.add_child(v)
	var mg:=_mg12(v); var hh:=_hb(8); mg.add_child(hh)
	hh.add_child(_l(_txt("PORTFOLIO_ALL"),14,CT,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f); _ba(hh,"✕",_toggle_portfolio)
	var ps:=ScrollContainer.new(); ps.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(ps)
	_port_detail=RichTextLabel.new(); _port_detail.bbcode_enabled=true; _port_detail.fit_content=true
	_port_detail.add_theme_font_size_override("normal_font_size",12)
	_port_detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ps.add_child(_port_detail)

func _build_lb_panel() -> void:
	_lb_panel=_ovp(0.30,0.72,0.97,CO); add_child(_lb_panel)
	var v:=VBoxContainer.new(); _lb_panel.add_child(v)
	var mg:=_mg12(v); var hh:=_hb(8); mg.add_child(hh)
	hh.add_child(_l(_txt("WEALTH_RANK"),14,CO,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f); _ba(hh,"✕",_toggle_lb)
	var ps:=ScrollContainer.new(); ps.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(ps)
	_lb_lbl=RichTextLabel.new(); _lb_lbl.bbcode_enabled=true; _lb_lbl.fit_content=true
	_lb_lbl.add_theme_font_size_override("normal_font_size",12)
	_lb_lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ps.add_child(_lb_lbl)

func _build_settings_panel() -> void:
	_settings_panel=_ovpc(0.28,0.72,0.10,0.90,CA); add_child(_settings_panel)
	var v:=VBoxContainer.new(); _settings_panel.add_child(v)
	var mg:=_mg12(v); var mv:=VBoxContainer.new(); mv.add_theme_constant_override("separation",14); mg.add_child(mv)
	var hh:=_hb(8); hh.add_child(_l(_txt("SETTINGS_TITLE"),15,CT,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f); _ba(hh,"✕",_toggle_settings); mv.add_child(hh)
	var div0:=ColorRect.new(); div0.color=Color(CA.r,CA.g,CA.b,0.30); div0.custom_minimum_size=Vector2(0,1); mv.add_child(div0)
	# Language
	mv.add_child(_l(_txt("LANGUAGE_LBL"),10,CM))
	var lr:=_hb(10); mv.add_child(lr)
	var en_btn:=Button.new(); en_btn.text="🇬🇧  English"; en_btn.flat=false
	en_btn.add_theme_font_size_override("font_size",13); en_btn.custom_minimum_size=Vector2(148,40)
	if LocaleSystem.current_language=="en":
		var esb:=StyleBoxFlat.new(); esb.bg_color=Color(0.18,0.38,0.72)
		esb.border_color=Color(0.36,0.62,1.0); esb.border_width_top=1; esb.border_width_bottom=1
		esb.border_width_left=1; esb.border_width_right=1; en_btn.add_theme_stylebox_override("normal",esb)
		en_btn.add_theme_color_override("font_color",Color(0.90,0.94,1.0))
	else:
		en_btn.add_theme_color_override("font_color",Color(0.55,0.58,0.65))
	en_btn.pressed.connect(func(): LocaleSystem.set_language("en")); lr.add_child(en_btn)
	var tr_btn:=Button.new(); tr_btn.text="🇹🇷  Türkçe"; tr_btn.flat=false
	tr_btn.add_theme_font_size_override("font_size",13); tr_btn.custom_minimum_size=Vector2(148,40)
	if LocaleSystem.current_language=="tr":
		var tsb:=StyleBoxFlat.new(); tsb.bg_color=Color(0.55,0.10,0.10)
		tsb.border_color=Color(0.90,0.22,0.22); tsb.border_width_top=1; tsb.border_width_bottom=1
		tsb.border_width_left=1; tsb.border_width_right=1; tr_btn.add_theme_stylebox_override("normal",tsb)
		tr_btn.add_theme_color_override("font_color",Color(1.0,0.90,0.90))
	else:
		tr_btn.add_theme_color_override("font_color",Color(0.55,0.58,0.65))
	tr_btn.pressed.connect(func(): LocaleSystem.set_language("tr")); lr.add_child(tr_btn)
	# Resolution
	mv.add_child(_l(_txt("RESOLUTION"),10,CM))
	var rr2:=_hb(6); mv.add_child(rr2)
	for res in [[1280,720,"1280×720"],[1440,900,"1440×900"],[1600,900,"1600×900"],[1920,1080,"1920×1080"],[2560,1440,"2560×1440"]]:
		var rb:=_b(res[2],func(): DisplayServer.window_set_size(Vector2i(res[0],res[1])))
		rb.add_theme_font_size_override("font_size",11); rr2.add_child(rb)
	# Music volume
	mv.add_child(_l(_txt("MUSIC_VOLUME"),10,CM))
	var vr:=_hb(8); vr.add_child(_l(_txt("VOLUME_LBL"),12,CM))
	var sl:=HSlider.new(); sl.min_value=0.0; sl.max_value=1.0; sl.value=0.42; sl.step=0.01
	sl.custom_minimum_size=Vector2(160,28); sl.value_changed.connect(func(v2): MusicSystem.set_volume(v2))
	vr.add_child(sl); mv.add_child(vr)
	# Player name
	mv.add_child(_l(_txt("SETTINGS_NAME"),10,CM))
	var name_edit:=LineEdit.new(); name_edit.text=GameState.player_name
	name_edit.placeholder_text=_txt("SETTINGS_NAME_HINT")
	name_edit.custom_minimum_size=Vector2(240,36)
	name_edit.text_changed.connect(func(t): GameState.player_name = t if t.strip_edges() != "" else "The Investor")
	mv.add_child(name_edit)
	# Company name
	mv.add_child(_l(_txt("SETTINGS_COMPANY"), 10, CM))
	var co_edit := LineEdit.new(); co_edit.text = GameState.company_name
	co_edit.placeholder_text = _txt("SETTINGS_COMPANY_HINT")
	co_edit.custom_minimum_size = Vector2(240, 36)
	co_edit.text_changed.connect(func(t):
		GameState.company_name = t if t.strip_edges() != "" else "The Exchange"
		_rebuild_company_card()
	)
	mv.add_child(co_edit)

func _build_spec_panel() -> void:
	_spec_panel=_ovpc(0.28,0.72,0.20,0.80,CO); _spec_panel.visible=false; add_child(_spec_panel)
	var v:=VBoxContainer.new(); _spec_panel.add_child(v)
	var mg:=_mg12(v); var mv:=VBoxContainer.new(); mv.add_theme_constant_override("separation",10); mg.add_child(mv)
	var ht:=_hb(10); mv.add_child(ht)
	var portrait_lbl:=_l("🕵",22,CT); portrait_lbl.name="portrait"; ht.add_child(portrait_lbl)
	var nv:=VBoxContainer.new(); ht.add_child(nv)
	var name_lbl:=_l("—",14,CO,true); name_lbl.name="sname"; nv.add_child(name_lbl)
	var title_lbl:=_l("—",11,CM); title_lbl.name="stitle"; nv.add_child(title_lbl)
	var div:=ColorRect.new(); div.color=Color(CO.r,CO.g,CO.b,0.3); div.custom_minimum_size=Vector2(0,1); mv.add_child(div)
	var tl:=_l("—",13,CA,true); tl.name="sticker"; mv.add_child(tl)
	var rl:=_l("—",12,CT); rl.name="sreason"; rl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; mv.add_child(rl)
	var pl:=_l(_txt("SPEC_PRICE"),12,CM); pl.name="sprice"; mv.add_child(pl)
	mv.add_child(_l(_txt("SPEC_RELIABILITY"),10,Color(0.8,0.6,0.3)))
	var br:=_hb(12); mv.add_child(br)
	var ab:=_b(_txt("SPEC_ACCEPT"),_on_spec_accept); ab.add_theme_color_override("font_color",CG); br.add_child(ab)
	br.add_child(_b(_txt("SPEC_DECLINE"),func(): _spec_panel.visible=false))

func _build_map_panel() -> void:
	_map_panel=PanelContainer.new()
	_map_panel.set_anchor_and_offset(SIDE_LEFT,0,0); _map_panel.set_anchor_and_offset(SIDE_RIGHT,1,0)
	_map_panel.set_anchor_and_offset(SIDE_TOP,0,50); _map_panel.set_anchor_and_offset(SIDE_BOTTOM,1,-60)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0,0,0,0.0)
	_map_panel.add_theme_stylebox_override("panel",sb)
	_map_panel.visible=false
	_map_panel.mouse_filter=Control.MOUSE_FILTER_PASS; add_child(_map_panel)
	_country_popup=_ovpc(0.34,0.66,0.30,0.72,CB); _country_popup.visible=false; add_child(_country_popup)
	_building_popup=_ovpc(0.30,0.70,0.28,0.72,Color(0.85,0.65,0.20)); _building_popup.visible=false; add_child(_building_popup)

func _build_council_panel() -> void:
	_council_panel = _ovpc(0.18, 0.82, 0.08, 0.92, CO)
	_council_panel.visible = false; add_child(_council_panel)

func _build_luxury_panel() -> void:
	var gold := Color(0.92, 0.78, 0.22)
	_luxury_panel = _ovpc(0.08, 0.92, 0.04, 0.96, gold)
	_luxury_panel.visible = false
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 14)
	_luxury_panel.add_child(mg)
	var root_v := VBoxContainer.new(); root_v.add_theme_constant_override("separation", 10); mg.add_child(root_v)
	# Header
	var hrow := _hb(10); root_v.add_child(hrow)
	hrow.add_child(_l("💎", 24, gold))
	var ht := _l(_txt("LUXURY_TITLE"), 15, gold, true); ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(ht)
	_ba(hrow, "✕", func(): _luxury_panel.visible = false)
	var div := ColorRect.new(); div.color = Color(gold.r, gold.g, gold.b, 0.30)
	div.custom_minimum_size = Vector2(0, 1); root_v.add_child(div)
	# Scrollable items container
	var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; root_v.add_child(sc)
	_luxury_list = VBoxContainer.new()
	_luxury_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_luxury_list.add_theme_constant_override("separation", 8)
	sc.add_child(_luxury_list)
	add_child(_luxury_panel)

func _refresh_luxury_panel() -> void:
	for ch in _luxury_list.get_children(): ch.queue_free()
	var gold := Color(0.92, 0.78, 0.22)
	for item in LuxurySystem.ITEMS:
		var owned := LuxurySystem.is_owned(item["id"])
		var can_buy = GameState.cash >= item["price"] and not owned
		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		card_sb.bg_color = Color(0.06, 0.07, 0.04, 0.92) if owned else Color(0.04, 0.05, 0.08, 0.90)
		card_sb.border_color = Color(gold.r, gold.g, gold.b, 0.70) if owned else Color(0.25, 0.28, 0.38, 0.60)
		card_sb.border_width_left = 2; card_sb.border_width_right = 1
		card_sb.border_width_top  = 1; card_sb.border_width_bottom = 1
		card.add_theme_stylebox_override("panel", card_sb)
		var cmg := MarginContainer.new()
		for s in ["margin_left","margin_right","margin_top","margin_bottom"]: cmg.add_theme_constant_override(s, 12)
		card.add_child(cmg)
		var row := _hb(16); cmg.add_child(row)
		# Icon
		var icon_lbl := _l(item["icon"], 42, CT)
		icon_lbl.custom_minimum_size = Vector2(56, 0); row.add_child(icon_lbl)
		# Name + desc
		var info_v := VBoxContainer.new(); info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_v.add_theme_constant_override("separation", 4); row.add_child(info_v)
		var name_col := gold if owned else CT
		info_v.add_child(_l(_txt(item["name_key"]), 15, name_col, true))
		var desc_lbl := _l(_txt(item["desc_key"]), 11, CM)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; info_v.add_child(desc_lbl)
		# Price + action
		var act_v := VBoxContainer.new(); act_v.add_theme_constant_override("separation", 6)
		act_v.custom_minimum_size = Vector2(180, 0); row.add_child(act_v)
		var price_str := _fmt(item["price"])
		act_v.add_child(_l("$" + price_str, 14, gold, true))
		if owned:
			act_v.add_child(_l(_txt("LUXURY_OWNED"), 13, CG, true))
		else:
			var iid = item["id"]
			var btn := _b(_txt("LUXURY_BUY") % price_str, func(): _on_buy_luxury(iid))
			btn.add_theme_font_size_override("font_size", 13)
			if not can_buy: btn.disabled = true
			act_v.add_child(btn)
		_luxury_list.add_child(card)

func _toggle_luxury() -> void:
	_luxury_panel.visible = not _luxury_panel.visible
	if _luxury_panel.visible: _refresh_luxury_panel()

func _on_buy_luxury(item_id: String) -> void:
	if LuxurySystem.buy(item_id):
		var item := LuxurySystem._find(item_id)
		MusicSystem.play_purchase()
		_msg(_txt("MSG_LUXURY") % _txt(item.get("name_key", "")), Color(0.92, 0.78, 0.22))
		_refresh_luxury_panel()

func _build_tech_panel() -> void:
	var ac := Color(0.40, 0.82, 0.96)
	_tech_panel = _ovpc(0.05, 0.95, 0.04, 0.96, ac)
	_tech_panel.visible = false
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 14)
	_tech_panel.add_child(mg)
	var root_v := VBoxContainer.new(); root_v.add_theme_constant_override("separation", 10); mg.add_child(root_v)
	var hrow := _hb(10); root_v.add_child(hrow)
	hrow.add_child(_l("🔬", 24, ac))
	var ht := _l(_txt("TECH_TITLE"), 15, ac, true); ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(ht)
	_tech_income_lbl = _l("", 12, CG, true); hrow.add_child(_tech_income_lbl)
	_g(hrow, 12)
	_ba(hrow, "✕", func(): _tech_panel.visible = false)
	var div := ColorRect.new(); div.color = Color(ac.r, ac.g, ac.b, 0.30)
	div.custom_minimum_size = Vector2(0, 1); root_v.add_child(div)
	var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; root_v.add_child(sc)
	_tech_list = VBoxContainer.new()
	_tech_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tech_list.add_theme_constant_override("separation", 6)
	sc.add_child(_tech_list)
	add_child(_tech_panel)

func _refresh_tech_panel() -> void:
	for ch in _tech_list.get_children(): ch.queue_free()
	var ac := Color(0.40, 0.82, 0.96)
	var daily := TechSystem.get_total_daily_income()
	_tech_income_lbl.text = _txt("TECH_TOTAL_INCOME") % _fmt(daily)
	var cur_decade := -1
	for tech in TechSystem.TECHS:
		var decade := int(tech["year"] / 10) * 10
		if decade != cur_decade:
			cur_decade = decade
			var dec_lbl := _l("── %ds ──" % decade, 11, Color(0.55, 0.60, 0.70), true)
			dec_lbl.add_theme_constant_override("margin_top", 8)
			_tech_list.add_child(dec_lbl)
		var owned := TechSystem.is_owned(tech["id"])
		var can_buy_now := TechSystem.can_buy(tech["id"])
		var year_locked = GameState.game_year < tech["year"]
		var req_locked := false
		if not owned and not year_locked:
			for r in tech["req"]:
				if not TechSystem.is_owned(r): req_locked = true; break
		var card := PanelContainer.new()
		var card_sb := StyleBoxFlat.new()
		if owned:
			card_sb.bg_color = Color(0.04, 0.09, 0.06, 0.92)
			card_sb.border_color = Color(0.22, 0.88, 0.52, 0.70)
		elif can_buy_now:
			card_sb.bg_color = Color(0.04, 0.07, 0.12, 0.92)
			card_sb.border_color = Color(ac.r, ac.g, ac.b, 0.70)
		else:
			card_sb.bg_color = Color(0.05, 0.05, 0.07, 0.88)
			card_sb.border_color = Color(0.20, 0.22, 0.28, 0.50)
		card_sb.border_width_left = 2; card_sb.border_width_right = 1
		card_sb.border_width_top  = 1; card_sb.border_width_bottom = 1
		card.add_theme_stylebox_override("panel", card_sb)
		var cmg := MarginContainer.new()
		for s in ["margin_left","margin_right","margin_top","margin_bottom"]: cmg.add_theme_constant_override(s, 10)
		card.add_child(cmg)
		var row := _hb(12); cmg.add_child(row)
		var icon_lbl := _l(tech["icon"], 36, CT)
		icon_lbl.custom_minimum_size = Vector2(48, 0); row.add_child(icon_lbl)
		var info_v := VBoxContainer.new(); info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_v.add_theme_constant_override("separation", 3); row.add_child(info_v)
		var _vl := LocaleSystem.current_language
		var tname = tech.get("name_tr", tech["name"]) if _vl == "tr" else tech["name"]
		var tdesc = tech.get("desc_tr", tech["desc"]) if _vl == "tr" else tech["desc"]
		var name_col := CG if owned else (ac if can_buy_now else CM)
		info_v.add_child(_l(tname, 14, name_col, true))
		var desc_lbl := _l(tdesc, 11, CM)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; info_v.add_child(desc_lbl)
		var act_v := VBoxContainer.new(); act_v.add_theme_constant_override("separation", 5)
		act_v.custom_minimum_size = Vector2(190, 0); row.add_child(act_v)
		act_v.add_child(_l("$" + _fmt(tech["price"]), 13, CO, true))
		act_v.add_child(_l(_txt("TECH_INCOME") % _fmt(tech["income"]), 11, CG))
		if owned:
			act_v.add_child(_l(_txt("TECH_OWNED"), 12, CG, true))
		elif year_locked:
			act_v.add_child(_l(_txt("TECH_LOCKED_YEAR") % tech["year"], 12, CM))
		elif req_locked:
			var req_names: Array = []
			for r in tech["req"]:
				if not TechSystem.is_owned(r):
					var rt := TechSystem._find(r)
					var rn = rt.get("name_tr", rt["name"]) if _vl == "tr" else rt["name"]
					req_names.append(rn)
			act_v.add_child(_l(_txt("TECH_LOCKED_REQ") % ", ".join(req_names), 11, Color(0.90, 0.55, 0.20)))
		else:
			var tid = tech["id"]
			var btn := _b(_txt("TECH_BUY") % _fmt(tech["price"]), func(): _on_buy_tech(tid))
			btn.add_theme_font_size_override("font_size", 12)
			if not can_buy_now: btn.disabled = true
			act_v.add_child(btn)
		_tech_list.add_child(card)

func _toggle_tech() -> void:
	_tech_panel.visible = not _tech_panel.visible
	if _tech_panel.visible: _refresh_tech_panel()

func _on_buy_tech(tech_id: String) -> void:
	if TechSystem.buy(tech_id):
		var t := TechSystem._find(tech_id)
		MusicSystem.play_purchase()
		var _vl := LocaleSystem.current_language
		var tname = t.get("name_tr", t["name"]) if _vl == "tr" else t["name"]
		_msg(_txt("MSG_TECH") % tname, Color(0.40, 0.82, 0.96))
		_refresh_tech_panel()

# ── Achievement panel ──────────────────────────────────────────────────────────
func _build_ach_panel() -> void:
	var gc := Color(0.88, 0.82, 0.22)
	_ach_panel = _ovpc(0.06, 0.94, 0.04, 0.96, gc)
	_ach_panel.visible = false
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 14)
	_ach_panel.add_child(mg)
	var root_v := VBoxContainer.new(); root_v.add_theme_constant_override("separation", 10); mg.add_child(root_v)
	var hrow := _hb(10); root_v.add_child(hrow)
	hrow.add_child(_l("⭐", 24, gc))
	var ht := _l(_txt("ACH_TITLE"), 15, gc, true); ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(ht)
	_ba(hrow, "✕", func(): _ach_panel.visible = false)
	var div := ColorRect.new(); div.color = Color(gc.r, gc.g, gc.b, 0.30)
	div.custom_minimum_size = Vector2(0, 1); root_v.add_child(div)
	var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL; root_v.add_child(sc)
	_ach_list = VBoxContainer.new()
	_ach_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ach_list.add_theme_constant_override("separation", 6)
	sc.add_child(_ach_list)
	add_child(_ach_panel)

func _refresh_ach_panel() -> void:
	if not _ach_list or not is_instance_valid(_ach_list): return
	for ch in _ach_list.get_children(): ch.queue_free()
	var gc := Color(0.88, 0.82, 0.22)
	var total := AchievementSystem.ACHIEVEMENTS.size()
	var got   := AchievementSystem.get_count()
	_ach_list.add_child(_l(_txt("ACH_COUNT") % [got, total], 11, CM))
	var lang := LocaleSystem.current_language
	for ach in AchievementSystem.ACHIEVEMENTS:
		var owned = ach["id"] in AchievementSystem.unlocked
		var card  := PanelContainer.new()
		var csb   := StyleBoxFlat.new()
		csb.bg_color    = Color(0.07, 0.07, 0.03, 0.92) if owned else Color(0.05, 0.05, 0.07, 0.88)
		csb.border_color = Color(gc.r, gc.g, gc.b, 0.70) if owned else Color(0.22, 0.24, 0.30, 0.50)
		csb.border_width_left = 3; csb.border_width_right = 1
		csb.border_width_top  = 1; csb.border_width_bottom = 1
		card.add_theme_stylebox_override("panel", csb)
		var cmg := MarginContainer.new()
		for s2 in ["margin_left","margin_right","margin_top","margin_bottom"]: cmg.add_theme_constant_override(s2, 10)
		card.add_child(cmg)
		var row := _hb(12); cmg.add_child(row)
		var ic := _l(ach["icon"] if owned else "🔒", 32, gc if owned else CM)
		ic.custom_minimum_size = Vector2(44, 0); row.add_child(ic)
		var tv := VBoxContainer.new(); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_theme_constant_override("separation", 3); row.add_child(tv)
		var aname = ach.get("name_tr", ach["name"]) if lang == "tr" else ach["name"]
		var adesc = ach.get("desc_tr", ach["desc"]) if lang == "tr" else ach["desc"]
		if "%s" in aname: aname = aname % GameState.company_name
		if "%s" in adesc: adesc = adesc % GameState.company_name
		tv.add_child(_l(aname, 14, gc if owned else CT, true))
		var dl := _l(adesc if owned else _txt("ACH_LOCKED"), 11, CM)
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tv.add_child(dl)
		_ach_list.add_child(card)

func _toggle_ach() -> void:
	_ach_panel.visible = not _ach_panel.visible
	if _ach_panel.visible: _refresh_ach_panel()

# ── Achievement unlock handler ────────────────────────────────────────────────
func _on_achievement_unlocked(ach: Dictionary) -> void:
	_show_achievement_toast(ach)
	if _ach_panel and is_instance_valid(_ach_panel) and _ach_panel.visible:
		_refresh_ach_panel()
	if not ach.get("newspaper", false): return
	# Build player-profile newspaper article
	var lang := LocaleSystem.current_language
	var pname := GameState.player_name
	var raw_hl = ach.get("news_headline_tr", ach["news_headline"]) if lang == "tr" else ach["news_headline"]
	var raw_body = ach.get("news_body_tr", ach["news_body"]) if lang == "tr" else ach["news_body"]
	var headline = (raw_hl % pname) if "%s" in raw_hl else raw_hl
	var body_txt = (raw_body % pname) if "%s" in raw_body else raw_body
	_show_player_news_popup(headline, body_txt)

func _show_player_news_popup(headline: String, body_txt: String) -> void:
	_pre_news_paused = GameState.paused
	GameState.paused = true
	var gold := Color(0.92, 0.78, 0.22)
	var pop  := _ovpc(0.08, 0.92, 0.06, 0.94, gold)
	pop.visible = true
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 24)
	pop.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 14); mg.add_child(v)
	var hrow := _hb(12); v.add_child(hrow)
	hrow.add_child(_l("📰", 22, gold))
	var ht := _l("THE FINANCIAL CHRONICLE", 11, gold, true)
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(ht)
	hrow.add_child(_l(GameState.get_date_string(), 11, CM))
	_ba(hrow, "✕", func():
		pop.queue_free(); _newspaper_popup = null
		if not _pre_news_paused: GameState.paused = false)
	var div := ColorRect.new(); div.color = Color(gold.r, gold.g, gold.b, 0.40)
	div.custom_minimum_size = Vector2(0, 2); v.add_child(div)
	var hl_lbl := _l(headline, 22, CT, true)
	hl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(hl_lbl)
	var byline := _l("BY OUR WEALTH CORRESPONDENT  ·  EXCLUSIVE", 10, gold)
	v.add_child(byline)
	var body_lbl := _l(body_txt, 13, Color(0.84, 0.80, 0.76))
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(body_lbl)
	var cb := _b("✕  Close", func():
		pop.queue_free(); _newspaper_popup = null
		if not _pre_news_paused: GameState.paused = false)
	cb.add_theme_color_override("font_color", gold); v.add_child(cb)
	_newspaper_popup = pop
	add_child(pop)

# ── Screen flash (crisis) ────────────────────────────────────────────────────
func _play_crisis_flash(col: Color) -> void:
	_flash_color = Color(col.r, col.g, col.b, 0.55)
	var tw := create_tween()
	tw.tween_method(func(a: float): _flash_color.a = a; queue_redraw(), 0.55, 0.0, 0.65)

# ── Office transition (fade-to-black) ─────────────────────────────────────────
func _play_office_transition(on_mid: Callable) -> void:
	var tw_in := create_tween()
	tw_in.tween_method(func(a: float): _transition_alpha = a; queue_redraw(), 0.0, 1.0, 0.35)
	tw_in.tween_callback(func():
		on_mid.call()
		var tw_out := create_tween()
		tw_out.tween_method(func(a: float): _transition_alpha = a; queue_redraw(), 1.0, 0.0, 0.45))

# ── Historical crisis popup ───────────────────────────────────────────────────
func _show_crisis_popup(ev: Dictionary) -> void:
	_play_crisis_flash(Color(0.95, 0.35, 0.08))
	_pre_news_paused = GameState.paused
	GameState.paused = true
	var lang := LocaleSystem.current_language
	var title  = ev.get("title_tr",  ev["title"])  if lang == "tr" else ev["title"]
	var body   = ev.get("body_tr",   ev["body"])   if lang == "tr" else ev["body"]
	var orange := Color(0.95, 0.48, 0.12)
	var pop    := _ovpc(0.06, 0.94, 0.06, 0.94, orange)
	pop.visible = true
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 24)
	pop.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 14); mg.add_child(v)
	var hrow := _hb(12); v.add_child(hrow)
	hrow.add_child(_l("⚡", 26, orange))
	var ht := _l(_txt("CRISIS_EDITION"), 11, orange, true)
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(ht)
	hrow.add_child(_l(GameState.get_date_string(), 11, CM))
	_ba(hrow, "✕", func():
		pop.queue_free(); _newspaper_popup = null
		if not _pre_news_paused: GameState.paused = false)
	var div := ColorRect.new(); div.color = Color(orange.r, orange.g, orange.b, 0.40)
	div.custom_minimum_size = Vector2(0, 3); v.add_child(div)
	var hl_lbl := _l(title, 24, CT, true)
	hl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(hl_lbl)
	var body_lbl := _l(body, 13, Color(0.88, 0.82, 0.76))
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(body_lbl)
	var imp_lbl := _l(_txt("CRISIS_IMPACT"), 11, orange)
	v.add_child(imp_lbl)
	var cb := _b(_txt("CRISIS_CLOSE"), func():
		pop.queue_free(); _newspaper_popup = null
		if not _pre_news_paused: GameState.paused = false)
	cb.add_theme_color_override("font_color", orange); v.add_child(cb)
	_newspaper_popup = pop
	add_child(pop)
	pop.pivot_offset = pop.size * 0.5
	pop.scale = Vector2(0.88, 0.88)
	pop.modulate.a = 0.0
	var ptw := create_tween(); ptw.set_parallel(true)
	ptw.tween_property(pop, "scale",          Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ptw.tween_property(pop, "modulate:a",     1.0,               0.22)

# ── Achievement toast ─────────────────────────────────────────────────────────
func _show_achievement_toast(ach: Dictionary) -> void:
	_toast_queue.append(ach)
	if not _toast_active: _next_toast()

func _next_toast() -> void:
	if _toast_queue.is_empty(): _toast_active = false; return
	_toast_active = true
	var ach  = _toast_queue.pop_front()
	var lang := LocaleSystem.current_language
	var aname = ach.get("name_tr", ach["name"]) if lang == "tr" else ach["name"]
	var toast := PanelContainer.new()
	toast.set_anchor_and_offset(SIDE_RIGHT,  1, -20)
	toast.set_anchor_and_offset(SIDE_LEFT,   1, -380)
	toast.set_anchor_and_offset(SIDE_BOTTOM, 1, -80)
	toast.set_anchor_and_offset(SIDE_TOP,    1, -148)
	var sb := StyleBoxFlat.new()
	sb.bg_color    = Color(0.05, 0.09, 0.05, 0.97)
	sb.border_color = CG; sb.border_width_left = 3
	sb.border_width_top = 1; sb.border_width_bottom = 1; sb.border_width_right = 1
	sb.corner_radius_top_left = 4; sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4; sb.corner_radius_bottom_right = 4
	toast.add_theme_stylebox_override("panel", sb)
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 12)
	toast.add_child(mg)
	var row := _hb(10); mg.add_child(row)
	var ic := _l(ach["icon"], 32, Color(0.88, 0.82, 0.22))
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(ic)
	var tv := VBoxContainer.new(); tv.add_theme_constant_override("separation", 3)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(tv)
	tv.add_child(_l(_txt("ACH_TOAST"), 10, CG, true))
	tv.add_child(_l(aname, 15, CT, true))
	add_child(toast)
	var t := Timer.new(); t.wait_time = 4.5; t.one_shot = true; add_child(t)
	t.timeout.connect(func():
		if is_instance_valid(toast): toast.queue_free()
		if is_instance_valid(t): t.queue_free()
		await get_tree().create_timer(0.4).timeout
		_next_toast())
	t.start()

func _on_newspaper(paper: Dictionary) -> void:
	_pre_news_paused = GameState.paused
	GameState.paused = true
	# Build newspaper popup
	if _newspaper_popup and is_instance_valid(_newspaper_popup):
		_newspaper_popup.queue_free()
	_newspaper_popup = PanelContainer.new()
	_newspaper_popup.set_anchor_and_offset(SIDE_LEFT,   0.05, 0)
	_newspaper_popup.set_anchor_and_offset(SIDE_RIGHT,  0.95, 0)
	_newspaper_popup.set_anchor_and_offset(SIDE_TOP,    0.02, 0)
	_newspaper_popup.set_anchor_and_offset(SIDE_BOTTOM, 0.98, 0)
	var paper_sb := StyleBoxFlat.new()
	paper_sb.bg_color      = Color(0.918, 0.895, 0.840)
	paper_sb.border_color  = Color(0.10, 0.08, 0.05)
	for s in [0,1,2,3]: paper_sb.set("border_width_"+["left","right","top","bottom"][s], 6)
	paper_sb.shadow_color  = Color(0,0,0,0.65); paper_sb.shadow_size = 18
	_newspaper_popup.add_theme_stylebox_override("panel", paper_sb)
	add_child(_newspaper_popup)

	# outer margin
	var omg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		omg.add_theme_constant_override(s, 18)
	_newspaper_popup.add_child(omg)
	var root_v := VBoxContainer.new(); root_v.add_theme_constant_override("separation", 0)
	omg.add_child(root_v)

	var ink  := Color(0.07, 0.05, 0.03)
	var ink2 := Color(0.22, 0.16, 0.10)
	var ink3 := Color(0.38, 0.28, 0.18)

	# helper lambdas
	var hr = func(h:int, c:Color) -> ColorRect:
		var r:=ColorRect.new(); r.color=c; r.custom_minimum_size=Vector2(0,h); return r
	var gap = func(h:int) -> Control:
		var g:=Control.new(); g.custom_minimum_size=Vector2(0,h); return g
	var lbl = func(txt:String, sz:int, c:Color, al:=HORIZONTAL_ALIGNMENT_LEFT, wrap:=false) -> Label:
		var l:=Label.new(); l.text=txt
		l.add_theme_font_size_override("font_size",sz)
		l.add_theme_color_override("font_color",c)
		l.horizontal_alignment=al
		if wrap: l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		return l

	# ── Outer decorative border line ─────────────────────────────────────────
	root_v.add_child(hr.call(1, ink))
	root_v.add_child(gap.call(3))
	root_v.add_child(hr.call(3, ink))
	root_v.add_child(gap.call(4))

	# ── Masthead row ──────────────────────────────────────────────────────────
	var mast_row := HBoxContainer.new(); mast_row.add_theme_constant_override("separation",0)
	# Left meta block
	var meta_l := VBoxContainer.new(); meta_l.custom_minimum_size=Vector2(140,0)
	meta_l.add_theme_constant_override("separation",2)
	meta_l.add_child(lbl.call(_txt("PAPER_EST"), 9, ink3))
	meta_l.add_child(lbl.call(paper["date"].to_upper(), 10, ink2))
	meta_l.add_child(lbl.call(_txt("PAPER_VOL") % (NewspaperSystem._econ_idx + NewspaperSystem._fill_idx), 9, ink3))
	mast_row.add_child(meta_l)

	# Paper title
	var title_lbl = lbl.call(_txt("PAPER_TITLE"), 42, ink, HORIZONTAL_ALIGNMENT_CENTER)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mast_row.add_child(title_lbl)

	# Right meta block
	var meta_r := VBoxContainer.new(); meta_r.custom_minimum_size=Vector2(140,0)
	meta_r.add_theme_constant_override("separation",2)
	var mr1 = lbl.call(_txt("PAPER_PRICE"), 9, ink3, HORIZONTAL_ALIGNMENT_RIGHT)
	meta_r.add_child(mr1)
	var mr2 = lbl.call(_txt("PAPER_EDITION"), 10, ink2, HORIZONTAL_ALIGNMENT_RIGHT)
	meta_r.add_child(mr2)
	var mr3 = lbl.call(_txt("PAPER_TAGLINE"), 9, ink3, HORIZONTAL_ALIGNMENT_RIGHT)
	meta_r.add_child(mr3)
	mast_row.add_child(meta_r)
	root_v.add_child(mast_row)

	root_v.add_child(gap.call(4))
	root_v.add_child(hr.call(4, ink))
	root_v.add_child(hr.call(1, ink))
	root_v.add_child(gap.call(2))
	root_v.add_child(hr.call(1, ink))
	root_v.add_child(gap.call(6))

	# ── Section label ─────────────────────────────────────────────────────────
	var articles: Array = paper["articles"]
	var econ_art: Dictionary = articles[0]
	var sec_lbl = lbl.call(_txt("PAPER_SEC_FIN"), 11, ink2, HORIZONTAL_ALIGNMENT_CENTER)
	root_v.add_child(sec_lbl)
	root_v.add_child(gap.call(3))
	root_v.add_child(hr.call(1, ink2))
	root_v.add_child(gap.call(8))

	# ── Lead article (economic) — full width headline ─────────────────────────
	if econ_art.get("impact_label","") != "":
		var tag = lbl.call(_txt("PAPER_ALERT") + econ_art["impact_label"], 10, Color(0.55,0.08,0.08), HORIZONTAL_ALIGNMENT_CENTER)
		root_v.add_child(tag)
		root_v.add_child(gap.call(3))

	var lead_hl = lbl.call(econ_art["headline"].to_upper(), 24, ink, HORIZONTAL_ALIGNMENT_CENTER, true)
	root_v.add_child(lead_hl)
	root_v.add_child(gap.call(4))
	root_v.add_child(hr.call(1, ink2))
	root_v.add_child(gap.call(2))
	var byline = lbl.call(econ_art.get("byline", _txt("PAPER_BYLINE_FIN")), 10, ink3, HORIZONTAL_ALIGNMENT_CENTER)
	root_v.add_child(byline)
	root_v.add_child(gap.call(6))

	# Lead article body — two mini-columns
	var lead_cols := HBoxContainer.new(); lead_cols.add_theme_constant_override("separation",0)
	lead_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for ci in 2:
		if ci > 0:
			lead_cols.add_child(hr.call(0, Color(0,0,0,0)))  # spacer trick
			var vd := ColorRect.new(); vd.color=Color(ink.r,ink.g,ink.b,0.35)
			vd.custom_minimum_size=Vector2(1,0); lead_cols.add_child(vd)
		var lmg := MarginContainer.new()
		for s in ["margin_left","margin_right"]: lmg.add_theme_constant_override(s, 12)
		lmg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lead_cols.add_child(lmg)
		var half = econ_art["body"]
		var mid = half.length() / 2
		while mid < half.length() and half[mid] != " ": mid += 1
		var body_part = half.substr(0, mid) if ci == 0 else half.substr(mid).strip_edges()
		var bl = lbl.call(body_part, 13, ink, HORIZONTAL_ALIGNMENT_LEFT, true)
		bl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lmg.add_child(bl)
	root_v.add_child(lead_cols)

	root_v.add_child(gap.call(8))
	root_v.add_child(hr.call(2, ink))
	root_v.add_child(hr.call(1, ink))
	root_v.add_child(gap.call(6))

	# ── Section label for filler ──────────────────────────────────────────────
	var sec2 = lbl.call(_txt("PAPER_SEC_MISC"), 11, ink2, HORIZONTAL_ALIGNMENT_CENTER)
	root_v.add_child(sec2)
	root_v.add_child(gap.call(3))
	root_v.add_child(hr.call(1, ink2))
	root_v.add_child(gap.call(8))

	# ── Two filler columns ────────────────────────────────────────────────────
	var fill_cols := HBoxContainer.new(); fill_cols.add_theme_constant_override("separation",0)
	fill_cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill_cols.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	for fi in [1, 2]:
		if fi > 1:
			var vd2 := ColorRect.new(); vd2.color=Color(ink.r,ink.g,ink.b,0.35)
			vd2.custom_minimum_size=Vector2(1,0); fill_cols.add_child(vd2)
		var fmg := MarginContainer.new()
		for s in ["margin_left","margin_right"]: fmg.add_theme_constant_override(s, 14)
		fmg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fmg.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		fill_cols.add_child(fmg)
		var fv := VBoxContainer.new(); fv.add_theme_constant_override("separation",5)
		fmg.add_child(fv)
		var fa: Dictionary = articles[fi]
		var fhl = lbl.call(fa["headline"].to_upper(), 14, ink, HORIZONTAL_ALIGNMENT_LEFT, true)
		fv.add_child(fhl)
		fv.add_child(hr.call(1, Color(ink.r,ink.g,ink.b,0.35)))
		var fby = lbl.call(fa.get("byline", _txt("PAPER_BYLINE_MISC")), 9, ink3)
		fv.add_child(fby)
		fv.add_child(gap.call(2))
		var fbl = lbl.call(fa["body"], 13, ink, HORIZONTAL_ALIGNMENT_LEFT, true)
		fbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fv.add_child(fbl)
	root_v.add_child(fill_cols)

	# ── Footer ────────────────────────────────────────────────────────────────
	root_v.add_child(gap.call(8))
	root_v.add_child(hr.call(1, ink))
	root_v.add_child(hr.call(2, ink))
	root_v.add_child(gap.call(8))

	var close_btn := Button.new()
	close_btn.text = _txt("PAPER_CLOSE")
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.add_theme_color_override("font_color", ink)
	var close_sb := StyleBoxFlat.new()
	close_sb.bg_color = Color(0.87, 0.84, 0.78)
	close_sb.border_color = ink; for s in [0,1,2,3]: close_sb.set("border_width_"+["left","right","top","bottom"][s],1)
	close_btn.add_theme_stylebox_override("normal", close_sb)
	close_btn.custom_minimum_size = Vector2(300, 34)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_close_newspaper)
	root_v.add_child(close_btn)
	root_v.add_child(gap.call(4))

func _close_newspaper() -> void:
	if _newspaper_popup and is_instance_valid(_newspaper_popup):
		_newspaper_popup.queue_free()
		_newspaper_popup = null
	GameState.paused = _pre_news_paused

# ── Phone call popup ──────────────────────────────────────────────────────────
func _on_phone_call(tip: Dictionary) -> void:
	if _phone_popup and is_instance_valid(_phone_popup):
		_phone_popup.queue_free()
	GameState.paused = true
	MusicSystem.play_ring()

	var CR2 := Color(0.75, 0.08, 0.08)
	var CG2 := Color(0.20, 0.82, 0.40)
	var CT2 := Color(0.82, 0.78, 0.70)
	var CM2 := Color(0.50, 0.46, 0.40)
	var BG  := Color(0.04, 0.03, 0.05)

	_phone_popup = PanelContainer.new()
	_phone_popup.set_anchor_and_offset(SIDE_LEFT,   0.30, 0)
	_phone_popup.set_anchor_and_offset(SIDE_RIGHT,  0.70, 0)
	_phone_popup.set_anchor_and_offset(SIDE_TOP,    0.18, 0)
	_phone_popup.set_anchor_and_offset(SIDE_BOTTOM, 0.82, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color     = BG
	psb.border_color = CR2
	for s in [0,1,2,3]: psb.set("border_width_"+["left","right","top","bottom"][s], 3)
	psb.shadow_color = Color(0,0,0,0.80); psb.shadow_size = 24
	_phone_popup.add_theme_stylebox_override("panel", psb)
	add_child(_phone_popup)

	var omg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		omg.add_theme_constant_override(s, 22)
	_phone_popup.add_child(omg)
	var rv := VBoxContainer.new(); rv.add_theme_constant_override("separation", 0)
	omg.add_child(rv)

	var gap = func(h:int) -> Control:
		var g:=Control.new(); g.custom_minimum_size=Vector2(0,h); return g
	var hr = func(h:int, c:Color) -> ColorRect:
		var r:=ColorRect.new(); r.color=c; r.custom_minimum_size=Vector2(0,h); return r
	var lbl = func(txt:String, sz:int, c:Color, al:=HORIZONTAL_ALIGNMENT_LEFT, wrap:=false) -> Label:
		var l:=Label.new(); l.text=txt
		l.add_theme_font_size_override("font_size",sz)
		l.add_theme_color_override("font_color",c)
		l.horizontal_alignment=al
		if wrap: l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		return l

	# ── Header (always visible) ───────────────────────────────────────────────
	rv.add_child(lbl.call("☎", 38, CR2, HORIZONTAL_ALIGNMENT_CENTER))
	rv.add_child(gap.call(4))
	rv.add_child(hr.call(1, Color(CR2.r, CR2.g, CR2.b, 0.4)))
	rv.add_child(gap.call(6))
	rv.add_child(lbl.call(_txt("PRIVATE_LINE"), 10, CR2, HORIZONTAL_ALIGNMENT_CENTER))
	rv.add_child(gap.call(2))
	rv.add_child(lbl.call(_txt("INCOMING_CALL"), 9, CM2, HORIZONTAL_ALIGNMENT_CENTER))
	rv.add_child(gap.call(10))
	rv.add_child(hr.call(1, Color(CR2.r, CR2.g, CR2.b, 0.3)))
	rv.add_child(gap.call(18))

	# ── Phase-2 elements (hidden until answered) ──────────────────────────────
	var voice_lbl := Label.new()
	voice_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	voice_lbl.add_theme_font_size_override("font_size", 13)
	voice_lbl.add_theme_color_override("font_color", CT2)
	voice_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voice_lbl.visible = false
	rv.add_child(voice_lbl)

	var g2   = gap.call(16);  g2.visible   = false; rv.add_child(g2)
	var sep2 = hr.call(1, Color(CR2.r, CR2.g, CR2.b, 0.3)); sep2.visible = false; rv.add_child(sep2)
	var g3   = gap.call(8);   g3.visible   = false; rv.add_child(g3)
	var disc = lbl.call(_txt("RELIABILITY_UNV"), 9, CM2, HORIZONTAL_ALIGNMENT_CENTER)
	disc.visible = false; rv.add_child(disc)
	var g4   = gap.call(14);  g4.visible   = false; rv.add_child(g4)

	var hang_btn := Button.new()
	hang_btn.text = _txt("HANG_UP")
	hang_btn.add_theme_font_size_override("font_size", 12)
	hang_btn.add_theme_color_override("font_color", CR2)
	var hsb := StyleBoxFlat.new()
	hsb.bg_color = Color(0.12, 0.03, 0.03); hsb.border_color = CR2
	for s in [0,1,2,3]: hsb.set("border_width_"+["left","right","top","bottom"][s], 1)
	hang_btn.add_theme_stylebox_override("normal", hsb)
	hang_btn.custom_minimum_size   = Vector2(140, 34)
	hang_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hang_btn.visible = false
	hang_btn.pressed.connect(_close_phone_popup)
	rv.add_child(hang_btn)

	# ── Phase-1: ANSWER button ────────────────────────────────────────────────
	var ans_btn := Button.new()
	ans_btn.text = _txt("ANSWER_CALL")
	ans_btn.add_theme_font_size_override("font_size", 12)
	ans_btn.add_theme_color_override("font_color", CG2)
	var asb := StyleBoxFlat.new()
	asb.bg_color = Color(0.04, 0.14, 0.06); asb.border_color = CG2
	for s in [0,1,2,3]: asb.set("border_width_"+["left","right","top","bottom"][s], 1)
	ans_btn.add_theme_stylebox_override("normal", asb)
	ans_btn.custom_minimum_size   = Vector2(140, 34)
	ans_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rv.add_child(ans_btn)

	var _vl := LocaleSystem.current_language
	var full_text = '"' + (tip.get("voice_tr", tip["voice"]) if _vl == "tr" else tip["voice"]) + '"'

	ans_btn.pressed.connect(func():
		ans_btn.queue_free()
		voice_lbl.visible = true
		var idx := [0]
		var timer := Timer.new()
		timer.wait_time = 0.038
		timer.one_shot  = false
		_phone_popup.add_child(timer)
		timer.timeout.connect(func():
			if not is_instance_valid(_phone_popup):
				timer.stop(); return
			if idx[0] < full_text.length():
				voice_lbl.text = full_text.substr(0, idx[0] + 1)
				idx[0] += 1
			else:
				timer.stop(); timer.queue_free()
				g2.visible   = true; sep2.visible = true
				g3.visible   = true; disc.visible = true
				g4.visible   = true; hang_btn.visible = true
		)
		timer.start()
	)

func _close_phone_popup() -> void:
	if _phone_popup and is_instance_valid(_phone_popup):
		_phone_popup.queue_free()
		_phone_popup = null
	# Only unpause if no other blocking popup is still open
	if not (_newspaper_popup and is_instance_valid(_newspaper_popup)):
		GameState.paused = false

func _build_trade_popup() -> void:
	_trade_popup = _ovpc(0.01, 0.24, 0.50, 0.82, CB)
	_trade_popup.visible = false; add_child(_trade_popup)

func _show_trade_popup(ticker: String) -> void:
	for ch in _trade_popup.get_children(): ch.queue_free()
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 12)
	_trade_popup.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); mg.add_child(v)

	# Header
	var hh := _hb(6)
	var info := MarketEngine.get_asset_info(ticker)
	hh.add_child(_l("%s  %s" % [TICON.get(ticker,"◆"), ticker], 15, CT, true))
	var ff := Control.new(); ff.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hh.add_child(ff)
	_ba(hh, "✕", func(): _trade_popup.visible = false); v.add_child(hh)

	# Price & holding info
	var cur := MarketEngine.get_price(ticker)
	v.add_child(_l(info.get("name",""), 10, Color(0.50,0.53,0.62)))
	v.add_child(_l("$%.2f  ·  %s" % [cur, info.get("sector","")], 12, CO))
	if Portfolio.holdings.has(ticker):
		var h = Portfolio.holdings[ticker]
		var pnl := Portfolio.get_unrealized_pnl(ticker)
		var pct = (cur - h["avg_cost"]) / h["avg_cost"] * 100.0
		v.add_child(_l(_txt("TRADE_HELD") % [h["qty"], h["avg_cost"], "+" if pnl>=0 else "", pnl, pct],
			11, CG if pnl>=0 else CR))

	var div := ColorRect.new(); div.color = Color(CB.r,CB.g,CB.b,0.4)
	div.custom_minimum_size = Vector2(0,1); v.add_child(div)

	# Qty spinbox
	var ql := _hb(8); v.add_child(ql)
	ql.add_child(_l(_txt("QTY_LBL"), 12, CM))
	var qty_sp := SpinBox.new(); qty_sp.min_value = 1; qty_sp.max_value = 999999
	qty_sp.step = 1; qty_sp.value = 10
	qty_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ql.add_child(qty_sp)

	# Buy / Sell buttons
	var br := _hb(8); v.add_child(br)
	var bb := Button.new(); bb.text = _txt("BUY_BTN"); bb.flat = false
	bb.add_theme_font_size_override("font_size", 13)
	bb.add_theme_color_override("font_color", CG)
	bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bb.pressed.connect(func():
		if Portfolio.buy(ticker, qty_sp.value):
			_msg(_txt("MSG_BOUGHT") % [qty_sp.value, ticker], CG)
			_show_trade_popup(ticker))
	br.add_child(bb)

	var sb := Button.new(); sb.text = _txt("SELL_BTN"); sb.flat = false
	sb.add_theme_font_size_override("font_size", 13)
	sb.add_theme_color_override("font_color", CR)
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not Portfolio.holdings.has(ticker): sb.disabled = true
	sb.pressed.connect(func():
		if Portfolio.sell(ticker, qty_sp.value):
			_msg(_txt("MSG_SOLD") % [qty_sp.value, ticker], CR)
			if Portfolio.holdings.has(ticker): _show_trade_popup(ticker)
			else: _trade_popup.visible = false)
	br.add_child(sb)
	_trade_popup.visible = true

func _show_council_vote(res: Dictionary) -> void:
	for ch in _council_panel.get_children(): ch.queue_free()
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 18)
	_council_panel.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 12); mg.add_child(v)

	# Header
	var hrow := _hb(10); v.add_child(hrow)
	hrow.add_child(_l("🌐", 28, CO))
	var hv := VBoxContainer.new(); hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(hv)
	hv.add_child(_l(_txt("COUNCIL_MEETING"), 11, CM))
	hv.add_child(_l(res.get("meeting_date",""), 10, CM))
	var filler := Control.new(); filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(filler)
	_ba(hrow, "✕", func(): CouncilSystem.abstain(); _council_panel.visible = false)

	var div := ColorRect.new(); div.color = Color(CO.r, CO.g, CO.b, 0.35)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)

	# Resolution title
	v.add_child(_l(res["title"], 17, CO, true))

	# Body text
	var bl := _l(res["body"], 12, Color(0.82, 0.78, 0.72))
	bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(bl)

	# Impact preview
	var imp_box := PanelContainer.new()
	var imp_sb := StyleBoxFlat.new(); imp_sb.bg_color = Color(0.06, 0.08, 0.04, 0.80)
	imp_sb.border_color = Color(0.40, 0.60, 0.20); imp_sb.border_width_left = 3
	imp_box.add_theme_stylebox_override("panel", imp_sb)
	var imp_mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: imp_mg.add_theme_constant_override(s, 8)
	imp_box.add_child(imp_mg)
	var imp_v := VBoxContainer.new(); imp_v.add_theme_constant_override("separation", 4); imp_mg.add_child(imp_v)
	imp_v.add_child(_l(_txt("COUNCIL_IF_PASSED"), 10, CM))
	imp_v.add_child(_l(res.get("impact_label","—"), 12, CG, true))
	v.add_child(imp_box)

	# Voting weight display
	var pw := CouncilSystem.get_player_vote_weight()
	var pct_str := "%.1f%%" % (pw * 100.0)
	var vote_info: String
	if pw < 0.001:
		vote_info = _txt("VOTE_NONE")
	else:
		vote_info = _txt("VOTE_WEIGHT") % [CountrySystem.owned.size(), pw * 100.0]
	var vl := _l(vote_info, 11, CA); vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(vl)

	# Buttons
	var br := _hb(14); br.alignment = BoxContainer.ALIGNMENT_CENTER; v.add_child(br)
	var yes_btn := _b(_txt("VOTE_YES"), func():
		CouncilSystem.vote(true); _council_panel.visible = false)
	yes_btn.add_theme_color_override("font_color", CG)
	yes_btn.custom_minimum_size = Vector2(260, 0); br.add_child(yes_btn)
	var no_btn := _b(_txt("VOTE_NO"), func():
		CouncilSystem.vote(false); _council_panel.visible = false)
	no_btn.add_theme_color_override("font_color", CR)
	no_btn.custom_minimum_size = Vector2(260, 0); br.add_child(no_btn)
	if pw < 0.001:
		yes_btn.disabled = true; no_btn.disabled = true
	_council_panel.visible = true

func _show_council_result(res: Dictionary, passed: bool, yes_pct: float) -> void:
	for ch in _council_panel.get_children(): ch.queue_free()
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 18)
	_council_panel.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 12); mg.add_child(v)

	# Header
	var hrow := _hb(10); v.add_child(hrow)
	hrow.add_child(_l("🌐", 28, CO))
	var hv := VBoxContainer.new(); hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(hv)
	hv.add_child(_l(_txt("COUNCIL_RESULT"), 11, CM))
	var filler := Control.new(); filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(filler)
	_ba(hrow, "✕", func(): _council_panel.visible = false)

	var div := ColorRect.new(); div.color = Color(CO.r, CO.g, CO.b, 0.35)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)

	v.add_child(_l(res["title"], 15, CO, true))

	var verdict_col := CG if passed else CR
	var verdict_txt := (_txt("VERDICT_PASSED") if passed else _txt("VERDICT_BLOCKED")) % (yes_pct * 100.0)
	v.add_child(_l(verdict_txt, 16, verdict_col, true))

	if passed:
		v.add_child(_l(_txt("IMPACT_APPLIED"), 11, CM))
		v.add_child(_l(res.get("impact_label","—"), 18, CG, true))
	else:
		var el := _l(_txt("NO_IMPACT"), 12, Color(0.72, 0.68, 0.62))
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(el)

	_ba(v, _txt("CLOSE"), func(): _council_panel.visible = false)
	_council_panel.visible = true

func _show_country_popup(cid: String) -> void:
	var c:=CountrySystem.find_country(cid); if c.is_empty(): return
	for ch in _country_popup.get_children(): ch.queue_free()
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,14)
	_country_popup.add_child(mg)
	var v:=VBoxContainer.new(); v.add_theme_constant_override("separation",8); mg.add_child(v)
	var hh:=_hb(8); hh.add_child(_l(c["name"],16,CT,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f)
	_ba(hh,"✕",func(): _country_popup.visible=false); v.add_child(hh)
	v.add_child(_l(_txt("REGION_INFO") % [c.get("region",""),c["gdp"],c["pop"]],11,CM))
	v.add_child(_l(_txt("PURCHASE_PRICE") % c["price"], 13, CO))
	if CountrySystem.is_owned(cid):
		v.add_child(_l(_txt("STATUS_OWNED"),12,CG))
		v.add_child(_l(_txt("AMB_NOTE"),11,CM))
	else:
		var bb:=_b(_txt("PURCHASE_MAP") % str(c["price"]), func(): _on_buy_country(cid))
		if not CountrySystem.can_afford(cid): bb.disabled=true
		v.add_child(bb)
	_country_popup.visible=true

func _on_buy_country(cid: String) -> void:
	if CountrySystem.buy(cid):
		MusicSystem.play_cash()
		_msg(_txt("MSG_PURCHASED") % CountrySystem.find_country(cid).get("name",""),CO)
		_country_popup.visible=false; _refresh_contacts()

func _office_card() -> Control:
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 8 if s in ["margin_left","margin_right"] else 6)
	var p:=PanelContainer.new(); var sb:=StyleBoxFlat.new()
	sb.bg_color=Color(0.06,0.07,0.12,0.85); sb.border_color=CA
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_width_left = 1; sb.border_width_right = 1
	p.add_theme_stylebox_override("panel",sb); mg.add_child(p)
	var gm:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		gm.add_theme_constant_override(s, 8 if s in ["margin_left","margin_right"] else 6)
	p.add_child(gm)
	var iv:=VBoxContainer.new(); gm.add_child(iv)
	iv.add_child(_l(_txt("OFFICE_PROG"),10,CA,true)); _gv(iv,4)
	var dr:=_hb(6)
	for i in 4:
		var d:=ColorRect.new(); d.custom_minimum_size=Vector2(12,12)
		d.color=CA if i<=OfficeSystem.current_level else CM; dr.add_child(d)
	iv.add_child(dr); _gv(iv,4)
	var cur:=OfficeSystem.get_current()
	iv.add_child(_l(cur["name"],11,CT,true)); iv.add_child(_l(cur.get("desc",""),10,CM)); _gv(iv,4)
	if OfficeSystem.can_upgrade():
		var nxt:=OfficeSystem.get_next()
		var ub:=_b(_txt("UPGRADE_BTN") % [nxt["name"], _fmt(OfficeSystem.get_upgrade_cost())],_on_upgrade)
		ub.add_theme_font_size_override("font_size",11); iv.add_child(ub)
	elif OfficeSystem.current_level<3:
		var nxt:=OfficeSystem.get_next()
		iv.add_child(_l(_txt("UNLOCK_AT") % _fmt(nxt.get("unlock",0.0)),10,CM))
	else:
		iv.add_child(_l(_txt("MAX_LEVEL"),10,CG))
	# Private line phone decoration
	_gv(iv, 8)
	var phone_sep := ColorRect.new(); phone_sep.color = Color(0.4,0.05,0.05,0.5)
	phone_sep.custom_minimum_size = Vector2(0,1); iv.add_child(phone_sep)
	_gv(iv, 5)
	var phone_row := _hb(6)
	phone_row.add_child(_l("☎", 16, Color(0.80, 0.10, 0.10)))
	var pl := _l("  " + _txt("PRIVATE_LINE"), 9, Color(0.65, 0.10, 0.10)); pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phone_row.add_child(pl)
	iv.add_child(phone_row)
	return mg

func _company_card() -> Control:
	var gold := Color(0.92, 0.78, 0.22)
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 8 if s in ["margin_left","margin_right"] else 6)
	var p := PanelContainer.new(); var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.02, 0.88); sb.border_color = gold
	sb.border_width_top = 1; sb.border_width_bottom = 1
	sb.border_width_left = 2; sb.border_width_right = 1
	p.add_theme_stylebox_override("panel", sb); mg.add_child(p)
	var gm := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		gm.add_theme_constant_override(s, 8 if s in ["margin_left","margin_right"] else 6)
	p.add_child(gm)
	var iv := VBoxContainer.new(); iv.add_theme_constant_override("separation", 4); gm.add_child(iv)
	iv.add_child(_l("🏢  " + GameState.company_name.to_upper(), 10, gold, true)); _gv(iv, 2)
	var div := ColorRect.new(); div.color = Color(gold.r, gold.g, gold.b, 0.35)
	div.custom_minimum_size = Vector2(0, 1); iv.add_child(div); _gv(iv, 3)
	var pct := ShareholdingSystem.get_ownership_pct()
	var val := ShareholdingSystem.get_total_value()
	var row1 := _hb(6); iv.add_child(row1)
	row1.add_child(_l(_txt("CO_OWNERSHIP") + ":", 10, CM))
	_co_own_lbl = _l("%.0f%%  ·  $%s" % [pct, _fmt(val)], 10, gold, true)
	row1.add_child(_co_own_lbl)
	var d := ShareholdingSystem.days_to_next_agm()
	_co_agm_lbl = _l(_agm_days_text(d), 10, CM)
	_co_agm_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; iv.add_child(_co_agm_lbl); _gv(iv, 4)
	var btn_row := _hb(6); iv.add_child(btn_row)
	if ShareholdingSystem.owned_units < ShareholdingSystem.TOTAL_UNITS:
		var bb := _b(_txt("CO_BUY_BTN"), _show_share_buy_popup)
		bb.add_theme_font_size_override("font_size", 11)
		bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL; btn_row.add_child(bb)
	else:
		iv.add_child(_l(_txt("CO_NO_AGM"), 9, CG))
	if ShareholdingSystem.owned_units > 1:
			var sell_btn = _b_txt("CO_SELL_BTN", _show_share_sell_popup)
			sell_btn.add_theme_font_size_override("font_size", 11)
			sell_btn.add_theme_color_override("font_color", CR)
			sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL; btn_row.add_child(sell_btn)
	return mg

func _agm_days_text(d: int) -> String:
	if d < 0:  return _txt("CO_NO_AGM")
	if ShareholdingSystem.owned_units > 51: return _txt("CO_AGM_5Y") % d
	return _txt("CO_AGM_DAYS") % d

func _refresh_company_labels() -> void:
	if not _co_own_lbl: return
	var pct := ShareholdingSystem.get_ownership_pct()
	var val := ShareholdingSystem.get_total_value()
	_co_own_lbl.text = "%.0f%%  ·  $%s" % [pct, _fmt(val)]
	_co_agm_lbl.text = _agm_days_text(ShareholdingSystem.days_to_next_agm())

func _rebuild_company_card() -> void:
	var parent := _company_card_ctrl.get_parent()
	var idx    := _company_card_ctrl.get_index()
	var nc     := _company_card()
	parent.add_child(nc); parent.move_child(nc, idx)
	_company_card_ctrl.queue_free(); _company_card_ctrl = nc

func _show_share_buy_popup() -> void:
	var gold  := Color(0.92, 0.78, 0.22)
	var avail := ShareholdingSystem.TOTAL_UNITS - ShareholdingSystem.owned_units
	if avail <= 0: return
	var pop = _ovpc(0.30, 0.70, 0.30, 0.72, gold)
	pop.visible = true
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 16)
	pop.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); mg.add_child(v)
	var hrow := _hb(8); hrow.add_child(_l("🏢", 18, gold)); v.add_child(hrow)
	var ht := _l(_txt("CO_BUY_TITLE") % GameState.company_name.to_upper(), 13, gold, true); ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(ht); _ba(hrow, "✕", func(): pop.queue_free())
	var div := ColorRect.new(); div.color = Color(gold.r, gold.g, gold.b, 0.30)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)
	v.add_child(_l(_txt("CO_UNITS_LBL"), 11, CM))
	var sb := SpinBox.new(); sb.min_value = 1; sb.max_value = avail
	sb.value = 1; sb.step = 1; v.add_child(sb)
	var cost_lbl := _l(_txt("CO_COST_LBL") % _fmt(ShareholdingSystem.UNIT_VALUE), 12, gold)
	v.add_child(cost_lbl)
	sb.value_changed.connect(func(n):
		cost_lbl.text = _txt("CO_COST_LBL") % _fmt(float(n) * ShareholdingSystem.UNIT_VALUE))
	var buy_b := _b(_txt("CO_CONFIRM"), func():
		if ShareholdingSystem.buy_units(int(sb.value)):
			pop.queue_free()
			if ShareholdingSystem.owned_units > 51:
				_msg(_txt("CO_MAJORITY"), gold)
			if ShareholdingSystem.owned_units >= ShareholdingSystem.TOTAL_UNITS:
				_msg(_txt("CO_FULL"), CG))
	buy_b.add_theme_color_override("font_color", CG); v.add_child(buy_b)
	add_child(pop)

func _show_share_sell_popup() -> void:
	var red   := Color(0.92, 0.32, 0.32)
	var avail := ShareholdingSystem.owned_units - 1  # keep at least 1
	if avail <= 0: return
	var pop := _ovpc(0.30, 0.70, 0.30, 0.72, red)
	pop.visible = true
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 16)
	pop.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); mg.add_child(v)
	var hrow := _hb(8); hrow.add_child(_l("🏢", 18, red)); v.add_child(hrow)
	var ht := _l(_txt("CO_SELL_TITLE") % GameState.company_name.to_upper(), 13, red, true); ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(ht); _ba(hrow, "✕", func(): pop.queue_free())
	var div := ColorRect.new(); div.color = Color(red.r, red.g, red.b, 0.30)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)
	v.add_child(_l(_txt("CO_SELL_UNITS_LBL"), 11, CM))
	var sb := SpinBox.new(); sb.min_value = 1; sb.max_value = avail
	sb.value = 1; sb.step = 1; v.add_child(sb)
	var proc_lbl := _l(_txt("CO_SELL_PROC_LBL") % _fmt(ShareholdingSystem.UNIT_VALUE), 12, red)
	v.add_child(proc_lbl)
	sb.value_changed.connect(func(n):
		proc_lbl.text = _txt("CO_SELL_PROC_LBL") % _fmt(float(n) * ShareholdingSystem.UNIT_VALUE))
	var warn := _l(_txt("CO_SELL_WARN"), 10, Color(0.90, 0.65, 0.20))
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(warn)
	var sell_b := _b(_txt("CO_SELL_CONFIRM"), func():
		if ShareholdingSystem.sell_units(int(sb.value)):
			pop.queue_free()
			_msg(_txt("CO_SOLD_MSG") % [int(sb.value), GameState.company_name], CR))
	sell_b.add_theme_color_override("font_color", CR); v.add_child(sell_b)
	add_child(pop)

func _on_agm(profitable: bool, nw: float, prev_nw: float) -> void:
	GameState.paused = true
	var gold := Color(0.92, 0.78, 0.22)
	var bord := CG if profitable else CR
	var pop  := _ovpc(0.20, 0.80, 0.20, 0.82, bord)
	pop.visible = true
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 20)
	pop.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 10); mg.add_child(v)
	# Header
	var hrow := _hb(8)
	hrow.add_child(_l("🏛", 28, gold))
	var hv := VBoxContainer.new(); hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(hv)
	hv.add_child(_l(_txt("AGM_TITLE"), 11, CM))
	hv.add_child(_l(_txt("AGM_COMPANY"), 16, gold, true))
	hv.add_child(_l(GameState.get_date_string(), 10, CM))
	v.add_child(hrow)
	var div := ColorRect.new(); div.color = Color(gold.r, gold.g, gold.b, 0.30)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)
	# Performance
	v.add_child(_l(_txt("AGM_PERF"), 11, CM))
	var dir := "▲" if nw > prev_nw else "▼"
	var diff_pct := ((nw - prev_nw) / maxf(abs(prev_nw), 1.0)) * 100.0
	var perf_col := CG if nw > prev_nw else CR
	v.add_child(_l(_txt("AGM_NW_NOW") % _fmt(nw) + "  %s%.1f%%" % [dir, abs(diff_pct)], 12, perf_col, true))
	v.add_child(_l(_txt("AGM_NW_PREV") % _fmt(prev_nw), 11, CM))
	# Verdict box
	var vbox := PanelContainer.new()
	var vsb := StyleBoxFlat.new(); vsb.bg_color = Color(bord.r, bord.g, bord.b, 0.12)
	vsb.border_color = bord; vsb.border_width_left = 3
	vbox.add_theme_stylebox_override("panel", vsb)
	var vmg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: vmg.add_theme_constant_override(s, 10)
	vbox.add_child(vmg); var vv := VBoxContainer.new(); vv.add_theme_constant_override("separation", 5); vmg.add_child(vv)
	vv.add_child(_l(_txt("AGM_PASS" if profitable else "AGM_FAIL"), 14, bord, true))
	var sub_lbl := _l(_txt("AGM_PASS_SUB" if profitable else "AGM_FAIL_SUB"), 11, CT)
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; vv.add_child(sub_lbl)
	v.add_child(vbox)
	# Button
	var btn_txt := _txt("AGM_OK") if profitable else _txt("AGM_ACCEPT")
	var ok := _b(btn_txt, func():
		pop.queue_free()
		GameState.paused = false
		if not profitable:
			_show_game_over())
	ok.add_theme_color_override("font_color", bord); v.add_child(ok)
	add_child(pop)

func _show_game_over() -> void:
	GameState.paused = true
	var pop := PanelContainer.new()
	pop.set_anchor_and_offset(SIDE_LEFT, 0, 0); pop.set_anchor_and_offset(SIDE_RIGHT, 1, 0)
	pop.set_anchor_and_offset(SIDE_TOP, 0, 0); pop.set_anchor_and_offset(SIDE_BOTTOM, 1, 0)
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.06, 0.02, 0.02, 0.97)
	sb.border_color = CR; sb.border_width_top = 2; sb.border_width_bottom = 2
	pop.add_theme_stylebox_override("panel", sb); add_child(pop)
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 0)
	pop.add_child(mg)
	var center := CenterContainer.new(); center.set_anchors_preset(Control.PRESET_FULL_RECT); mg.add_child(center)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 16)
	v.alignment = BoxContainer.ALIGNMENT_CENTER; center.add_child(v)
	v.add_child(_l("✗", 64, CR)); _gv(v, 4)
	v.add_child(_l(_txt("GO_TITLE"), 42, CR, true))
	var days := GameState.total_days_passed
	var years := days / 365; var rem := days % 365
	var nw := GameState.get_net_worth()
	var body_lbl := _l(_txt("GO_BODY"), 14, CT)
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.custom_minimum_size = Vector2(500, 0); v.add_child(body_lbl); _gv(v, 8)
	v.add_child(_l(_txt("GO_PLAYED") % [years, rem], 13, CM))
	v.add_child(_l(_txt("GO_NW") % _fmt(nw), 13, CM)); _gv(v, 16)
	var mb := _b(_txt("GO_MENU"), func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	mb.add_theme_font_size_override("font_size", 16)
	mb.add_theme_color_override("font_color", CT)
	mb.custom_minimum_size = Vector2(300, 0); v.add_child(mb)

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNAL CONNECTIONS
# ═══════════════════════════════════════════════════════════════════════════════
func _connect_all() -> void:
	GameState.day_advanced.connect(_on_day)
	GameState.cash_changed.connect(_on_cash)
	GameState.influence_changed.connect(_on_inf)
	MarketEngine.prices_updated.connect(_on_prices)
	NewsSystem.news_published.connect(_on_news)
	NewsSystem.historical_event_triggered.connect(_on_crisis)
	Portfolio.position_opened.connect(func(_a,_b,_c): _refresh_portfolio())
	Portfolio.position_closed.connect(func(_a,_b,_c,_d): _refresh_portfolio())
	Portfolio.trade_failed.connect(_on_fail)
	ContactsSystem.manipulation_executed.connect(_on_manip)
	ContactsSystem.action_failed.connect(_on_fail)
	OfficeSystem.office_upgraded.connect(_on_office_up)
	SaveSystem.game_saved.connect(func(): _msg(_txt("MSG_SAVED"),CG))
	SaveSystem.game_loaded.connect(func(): _refresh_all(); _msg(_txt("MSG_LOADED"),CA))
	SaveSystem.save_failed.connect(func(r): _msg(_txt("MSG_ERROR") % r,CR))
	SpeculatorSystem.speculator_arrived.connect(_on_speculator)
	SpeculatorSystem.tip_resolved.connect(_on_tip_resolved)
	CountrySystem.country_purchased.connect(func(c): _msg(_txt("MSG_PURCHASED") % c["name"],CO); _refresh_contacts())
	CouncilSystem.council_called.connect(_on_council_called)
	CouncilSystem.council_resolved.connect(_on_council_resolved)
	NewspaperSystem.newspaper_ready.connect(_on_newspaper)
	PhoneCallSystem.call_received.connect(_on_phone_call)
	ShareholdingSystem.agm_called.connect(_on_agm)
	ShareholdingSystem.share_purchased.connect(func(_u): _rebuild_company_card())
	ShareholdingSystem.share_sold.connect(func(_u): _rebuild_company_card())
	AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
	MegaProjectSystem.project_purchased.connect(func(p):
		var lang := LocaleSystem.current_language
		var pname = p.get("name_tr", p["name"]) if lang == "tr" else p["name"]
		_msg(_txt("MSG_MEGA_BUY") % pname, Color(0.40, 0.90, 0.70)))
	MegaProjectSystem.project_completed.connect(func(p):
		var lang := LocaleSystem.current_language
		var pname = p.get("name_tr", p["name"]) if lang == "tr" else p["name"]
		_msg(_txt("MSG_MEGA_DONE") % pname, CG))
	if not LocaleSystem.language_changed.is_connected(_on_language_changed):
		LocaleSystem.language_changed.connect(_on_language_changed)
	_tick_sel.item_selected.connect(_on_tick_sel)

# ── Event handlers ─────────────────────────────────────────────────────────────
func _on_day(d:String)           -> void: _date_lbl.text=d; _refresh_all()
func _on_cash(v:float)           -> void: _cash_lbl.text="$"+_fmt(v); _update_nw()
func _on_inf(l:int)              -> void: _inf_lbl.text="│  Inf: %d/5"%l
func _on_prices()                -> void: _refresh_tickers(); _chart.queue_redraw()
func _on_news(a:Dictionary)      -> void: _add_news(a)
func _on_fail(r:String)          -> void: _msg(r,CR)
func _on_manip(a:Dictionary)     -> void: _show_action_result(a)

func _show_action_result(a: Dictionary) -> void:
	if _action_result_panel and is_instance_valid(_action_result_panel):
		_action_result_panel.queue_free()

	var mag  = a.get("mag", 0.0)
	var up   = mag >= 0.0
	var CACC := CG if up else CR
	var pct_str = ("%+.1f%%" % (mag * 100.0))

	var target_line := ""
	var sub_line    := _txt("ACTION_DELAY")
	match a.get("effect", ""):
		"ticker":
			var tk: String = a["ticker"]
			target_line = "%s  %s  %s" % [tk, ("▲" if up else "▼"), pct_str]
		"sector":
			target_line = _txt("ACTION_SECTOR") % [a["sector"], ("▲" if up else "▼"), pct_str]
		"global":
			target_line = _txt("ACTION_GLOBAL") % [("▲" if up else "▼"), pct_str]

	_action_result_panel = PanelContainer.new()
	_action_result_panel.set_anchor_and_offset(SIDE_LEFT,   0.30, 0)
	_action_result_panel.set_anchor_and_offset(SIDE_RIGHT,  0.70, 0)
	_action_result_panel.set_anchor_and_offset(SIDE_TOP,    0.38, 0)
	_action_result_panel.set_anchor_and_offset(SIDE_BOTTOM, 0.62, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color    = Color(0.06, 0.09, 0.07, 0.97)
	sb.border_color = CACC
	for s in [0,1,2,3]: sb.set("border_width_"+["left","right","top","bottom"][s], 2)
	sb.shadow_color = Color(0,0,0,0.70); sb.shadow_size = 14
	_action_result_panel.add_theme_stylebox_override("panel", sb)
	add_child(_action_result_panel)

	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 18)
	_action_result_panel.add_child(mg)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 6)
	mg.add_child(vb)

	var hl := Label.new()
	var _clbl_key = "CLBL_" + a.get("id", "")
	hl.text = "✓  " + (_txt(_clbl_key) if LocaleSystem.STRINGS["en"].has(_clbl_key) else a.get("label", ""))
	hl.add_theme_font_size_override("font_size", 12)
	hl.add_theme_color_override("font_color", CT)
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hl)

	var sep := ColorRect.new(); sep.color = Color(CACC.r,CACC.g,CACC.b,0.35)
	sep.custom_minimum_size = Vector2(0,1); vb.add_child(sep)

	var tl := Label.new()
	tl.text = target_line
	tl.add_theme_font_size_override("font_size", 16)
	tl.add_theme_color_override("font_color", CACC)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tl)

	var pl := Label.new()
	pl.text = sub_line
	pl.add_theme_font_size_override("font_size", 11)
	pl.add_theme_color_override("font_color", CM)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(pl)

	var dismiss := Button.new()
	dismiss.text = _txt("DISMISS")
	dismiss.add_theme_font_size_override("font_size", 11)
	dismiss.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dismiss.pressed.connect(func():
		if is_instance_valid(_action_result_panel):
			_action_result_panel.queue_free(); _action_result_panel = null
	)
	vb.add_child(dismiss)

	var t := Timer.new(); t.wait_time = 6.0; t.one_shot = true
	_action_result_panel.add_child(t)
	t.timeout.connect(func():
		if is_instance_valid(_action_result_panel):
			_action_result_panel.queue_free(); _action_result_panel = null
	)
	t.start()
func _on_crisis(ev: Dictionary) -> void:
	_msg(_txt("MSG_CRISIS") % ev["title"], CO)
	_show_crisis_popup(ev)
func _on_office_up(lv: int) -> void:
	_play_office_transition(func():
		_refresh_all()
		if _office_card_ctrl and is_instance_valid(_office_card_ctrl):
			var parent   := _office_card_ctrl.get_parent()
			var idx      := _office_card_ctrl.get_index()
			var new_card := _office_card()
			parent.add_child(new_card)
			parent.move_child(new_card, idx)
			_office_card_ctrl.queue_free()
			_office_card_ctrl = new_card
		_show_office_bonus_popup(lv))

func _show_office_bonus_popup(lv: int) -> void:
	var cur := OfficeSystem.get_current()
	var bonus_title := ""
	var bonus_body  := ""
	match lv:
		1:
			bonus_title = _txt("BONUS_T1")
			bonus_body  = _txt("BONUS_B1")
		2:
			bonus_title = _txt("BONUS_T2")
			bonus_body  = _txt("BONUS_B2")
		3:
			bonus_title = _txt("BONUS_T3")
			bonus_body  = _txt("BONUS_B3")
		_:
			bonus_title = _txt("OFFICE_UPGRADED")
			bonus_body  = cur.get("desc","")

	var pop := PanelContainer.new()
	pop.set_anchor_and_offset(SIDE_LEFT,   0.28, 0)
	pop.set_anchor_and_offset(SIDE_RIGHT,  0.72, 0)
	pop.set_anchor_and_offset(SIDE_TOP,    0.30, 0)
	pop.set_anchor_and_offset(SIDE_BOTTOM, 0.70, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.06, 0.08, 0.06, 0.97)
	sb.border_color = CO
	for s in [0,1,2,3]: sb.set("border_width_"+["left","right","top","bottom"][s], 2)
	sb.shadow_color = Color(0,0,0,0.70); sb.shadow_size = 18
	pop.add_theme_stylebox_override("panel", sb)
	add_child(pop)

	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 20)
	pop.add_child(mg)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 8)
	mg.add_child(vb)

	var ttl := Label.new()
	ttl.text = "🏢  " + cur["name"]
	ttl.add_theme_font_size_override("font_size", 11)
	ttl.add_theme_color_override("font_color", CM)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ttl)

	var sep1 := ColorRect.new(); sep1.color = Color(CO.r,CO.g,CO.b,0.4)
	sep1.custom_minimum_size = Vector2(0,1); vb.add_child(sep1)

	var bt := Label.new()
	bt.text = "✦  " + bonus_title + "  ✦"
	bt.add_theme_font_size_override("font_size", 18)
	bt.add_theme_color_override("font_color", CO)
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(bt)

	var sep2 := ColorRect.new(); sep2.color = Color(CO.r,CO.g,CO.b,0.25)
	sep2.custom_minimum_size = Vector2(0,1); vb.add_child(sep2)

	var bd := Label.new()
	bd.text = bonus_body
	bd.add_theme_font_size_override("font_size", 12)
	bd.add_theme_color_override("font_color", CT)
	bd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(bd)

	var g := Control.new(); g.custom_minimum_size = Vector2(0,6); vb.add_child(g)

	var ok := Button.new()
	ok.text = _txt("OK_BTN")
	ok.add_theme_font_size_override("font_size", 12)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func(): pop.queue_free())
	vb.add_child(ok)

func _spec_header(v: VBoxContainer, offer: Dictionary) -> void:
	var hrow:=_hb(10)
	hrow.add_child(_l(offer.get("portrait","🕵"),26,CT))
	var nv:=VBoxContainer.new(); nv.add_theme_constant_override("separation",2)
	nv.add_child(_l(offer["name"],15,CO,true)); nv.add_child(_l(offer["title"],10,CM))
	nv.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hrow.add_child(nv)
	_ba(hrow,"✕",func(): _spec_panel.visible=false); v.add_child(hrow)
	var d:=ColorRect.new(); d.color=Color(CO.r,CO.g,CO.b,0.35); d.custom_minimum_size=Vector2(0,1); v.add_child(d)

func _on_speculator(offer:Dictionary) -> void:
	_current_offer=offer
	for ch in _spec_panel.get_children(): ch.queue_free()
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,16)
	_spec_panel.add_child(mg)
	var v:=VBoxContainer.new(); v.add_theme_constant_override("separation",10); mg.add_child(v)
	_spec_header(v, offer)
	# Stage 1: greeting + vague subject — NO ticker revealed yet
	var gl:=_l(_offer_txt(offer,"greeting"),12,Color(0.88,0.84,0.76)); gl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; v.add_child(gl)
	var d2:=ColorRect.new(); d2.color=Color(CO.r,CO.g,CO.b,0.2); d2.custom_minimum_size=Vector2(0,1); v.add_child(d2)
	v.add_child(_l(_offer_txt(offer,"hint"),11,Color(0.72,0.68,0.58)))
	v.add_child(_l(_txt("SPEC_RELIABILITY"),10,Color(0.82,0.62,0.28)))
	v.add_child(_l(_txt("SPEC_ASKING") % _fmt(offer["price"]),13,CO,true))
	var br:=_hb(12); v.add_child(br)
	var ab:=_b(_txt("PAY_TIP"),_on_spec_accept); ab.add_theme_color_override("font_color",CG); br.add_child(ab)
	br.add_child(_b(_txt("PASS_BTN"),func(): _spec_panel.visible=false))
	_spec_panel.visible=true

func _show_spec_reveal(offer: Dictionary) -> void:
	for ch in _spec_panel.get_children(): ch.queue_free()
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,16)
	_spec_panel.add_child(mg)
	var v:=VBoxContainer.new(); v.add_theme_constant_override("separation",10); mg.add_child(v)
	_spec_header(v, offer)
	# Stage 2: actual recommendation revealed after payment
	var tc:=CG if offer["action"]=="BUY" else CR
	v.add_child(_l((_txt("BUY_ACTION") if offer["action"]=="BUY" else _txt("SELL_ACTION"))+offer["ticker"],20,tc,true))
	var rl:=_l(_offer_txt(offer,"reason"),12,Color(0.78,0.74,0.68)); rl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; v.add_child(rl)
	var d:=ColorRect.new(); d.color=Color(CO.r,CO.g,CO.b,0.2); d.custom_minimum_size=Vector2(0,1); v.add_child(d)
	v.add_child(_l(_txt("TIP_ACTIVE"),11,Color(0.72,0.68,0.58)))
	_ba(v,_txt("CLOSE"),func(): _spec_panel.visible=false)
	_spec_panel.visible=true

func _on_spec_accept() -> void:
	if _current_offer.is_empty(): _spec_panel.visible=false; return
	if GameState.cash < _current_offer["price"]:
		_msg(_txt("MSG_NO_CASH"),CR); return
	SpeculatorSystem.accept_tip(_current_offer)
	_msg(_txt("MSG_TIP_PAID"),CO)
	_show_spec_reveal(_current_offer)
	_current_offer={}

func _on_tip_resolved(tip:Dictionary,correct:bool) -> void:
	var key:="outcome_win" if correct else "outcome_lose"
	var body:=_offer_txt(tip, key)
	if body=="": body = (_txt("MSG_TIP_WIN") if correct else _txt("MSG_TIP_LOSE")) % tip["ticker"]
	_msg(("✓ " if correct else "✗ ")+body, CG if correct else CR)
	NewsSystem._publish({"headline":("✓ " if correct else "✗ ")+_txt("INTEL_RESOLVED") % tip["ticker"],"body":body,"cat":"intel","crisis":false,"date":GameState.get_date_string()})

func _on_council_called(res: Dictionary) -> void:
	_show_council_vote(res)
	_msg(_txt("MSG_COUNCIL_START") % res["title"], CO)

func _on_council_resolved(res: Dictionary, passed: bool, yes_pct: float) -> void:
	_show_council_result(res, passed, yes_pct)
	var verdict := _txt("COUNCIL_PASSED") if passed else _txt("COUNCIL_BLOCKED")
	_msg(_txt("MSG_COUNCIL_END") % [res["title"], verdict, yes_pct * 100.0], CG if passed else CR)
	NewsSystem._publish({"headline":"🌐 " + _txt("COUNCIL_LABEL") + ": " + res["title"] + " — " + verdict,
		"body": res["body"] + "\n\n" + _txt("COUNCIL_RESULT") + ": " + verdict + " (%.0f%%)" % (yes_pct * 100.0),
		"cat":"politics","crisis":passed,"date":GameState.get_date_string()})

func _on_tick_sel(idx:int) -> void:
	_sel_ticker=_tick_sel.get_item_text(idx); _chart.set_ticker(_sel_ticker)
	var info:=MarketEngine.get_asset_info(_sel_ticker)
	_sel_lbl.text="%s %s  ·  %s  ·  $%.2f" % [TICON.get(_sel_ticker,"◆"),_sel_ticker,info.get("name",""),MarketEngine.get_price(_sel_ticker)]

func _on_buy()     -> void:
	if Portfolio.buy(_sel_ticker,_qty_in.value): _msg(_txt("MSG_BOUGHT") % [_qty_in.value, _sel_ticker], CG)
func _on_sell()    -> void:
	if Portfolio.sell(_sel_ticker,_qty_in.value): _msg(_txt("MSG_SOLD") % [_qty_in.value, _sel_ticker], CR)
func _on_save()    -> void: SaveSystem.save()
func _on_load()    -> void: SaveSystem.load_game()
func _on_upgrade() -> void: if not OfficeSystem.upgrade(): _msg(_txt("MSG_UPGRADE_FAIL"), CM)
func _on_pause()   -> void:
	GameState.toggle_pause()
	_pause_btn.text = _txt("RESUME") if GameState.paused else _txt("PAUSE")

# ── Panel toggles ──────────────────────────────────────────────────────────────
func _toggle_contacts() -> void:
	_contacts_panel.visible=!_contacts_panel.visible
	if _contacts_panel.visible: _refresh_contacts()

func _toggle_portfolio() -> void:
	_port_panel.visible=!_port_panel.visible
	if _port_panel.visible: _refresh_port_detail()

func _toggle_lb() -> void:
	_lb_panel.visible=!_lb_panel.visible
	if _lb_panel.visible: _refresh_lb()

func _toggle_settings() -> void:
	_settings_panel.visible=!_settings_panel.visible

func _toggle_map() -> void:
	if _office_view: _toggle_office_view()
	_map_panel.visible=!_map_panel.visible
	_content_columns.visible=!_map_panel.visible
	if not _map_panel.visible:
		_country_popup.visible=false
		if _building_popup: _building_popup.visible=false

func _toggle_office_view() -> void:
	_office_view = !_office_view
	if _office_view:
		_content_columns.visible = false
		if _map_panel:      _map_panel.visible      = false
		if _country_popup:  _country_popup.visible  = false
		if _building_popup: _building_popup.visible = false
		if _contacts_panel: _contacts_panel.visible = false
		if _port_panel:     _port_panel.visible     = false
		if _lb_panel:       _lb_panel.visible       = false
		if _settings_panel: _settings_panel.visible = false
		if _spec_panel:     _spec_panel.visible     = false
		if _council_panel:  _council_panel.visible  = false
		if _trade_popup:    _trade_popup.visible    = false
	else:
		_content_columns.visible = true

# ═══════════════════════════════════════════════════════════════════════════════
# REFRESH METHODS
# ═══════════════════════════════════════════════════════════════════════════════
func _refresh_all() -> void:
	_update_nw(); _refresh_tickers(); _refresh_portfolio()
	_off_lbl.text="📍 "+OfficeSystem.get_current()["name"]
	_update_rank(); _refresh_company_labels()

func _update_nw() -> void:
	var nw:=GameState.get_net_worth(); var pnl:=nw-GameState.starting_capital
	_nw_lbl.text="Net: $"+_fmt(nw)+("  ▲" if pnl>=0 else "  ▼")
	_nw_lbl.add_theme_color_override("font_color",CG if pnl>=0 else CR)

func _update_rank() -> void:
	var r:=WealthLeaderboard.get_player_rank()
	_rank_lbl.text="│  "+("#%d" % r if r<=100 else "#100+")
	_rank_lbl.add_theme_color_override("font_color",CO if r<=100 else CM)

func _refresh_tickers() -> void:
	for c in _ticker_list.get_children(): c.queue_free()
	for ticker in MarketEngine.get_all_tickers():
		var price:=MarketEngine.get_price(ticker); var pct:=MarketEngine.get_change_pct(ticker); var up:=pct>=0
		var row:=_hb(4)
		# YENİ — SVG ikon
		var icon_tex := IconLoader.get_icon(ticker)
		if icon_tex:
			var tr := TextureRect.new()
			tr.texture = icon_tex
			tr.custom_minimum_size = Vector2(20, 20)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(tr)
		else:
			var il := Label.new()  # fallback: sembol kalsın
			il.text = TICON.get(ticker, "◆")
			il.add_theme_font_size_override("font_size", 11)
			il.add_theme_color_override("font_color",
				Color.from_string(TCOL.get(ticker, "#888780"), Color.WHITE))
			il.custom_minimum_size = Vector2(20, 0)
			row.add_child(il)
		var bt:=Button.new(); bt.flat=true
		bt.text="%-6s  $%-10s  %s%.2f%%" % [ticker,"%.2f"%price,("+" if up else ""),pct]
		bt.add_theme_font_size_override("font_size",12); bt.alignment=HORIZONTAL_ALIGNMENT_LEFT
		bt.add_theme_color_override("font_color",CA if ticker==_sel_ticker else (CG if up else CR))
		var t2=ticker; bt.pressed.connect(func(): _select_ticker(t2)); row.add_child(bt)
		_ticker_list.add_child(row)

func _select_ticker(t2:String) -> void:
	_sel_ticker=t2; _chart.set_ticker(t2)
	var info:=MarketEngine.get_asset_info(t2)
	_sel_lbl.text="%s %s  ·  %s  ·  $%.2f" % [TICON.get(t2,"◆"),t2,info.get("name",""),MarketEngine.get_price(t2)]
	for i in _tick_sel.item_count:
		if _tick_sel.get_item_text(i)==t2: _tick_sel.select(i); break
	_refresh_tickers()

func _refresh_portfolio() -> void:
	for c in _port_list.get_children(): c.queue_free()
	if Portfolio.holdings.is_empty(): _port_list.add_child(_l(_txt("NO_POSITIONS"),11,CM)); return
	for t2 in Portfolio.holdings:
		var h=Portfolio.holdings[t2]; var pnl=Portfolio.get_unrealized_pnl(t2)
		var row:=_hb(4)
		var icon_tex := IconLoader.get_icon(t2)
		if icon_tex:
			var tr := TextureRect.new()
			tr.texture = icon_tex
			tr.custom_minimum_size = Vector2(20, 20)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(tr)
		else:
			var il := Label.new()
			il.text = TICON.get(t2, "◆")
			il.add_theme_font_size_override("font_size", 11)
			il.add_theme_color_override("font_color",
				Color.from_string(TCOL.get(t2, "#888780"), Color.WHITE))
			il.custom_minimum_size = Vector2(20, 0)
			row.add_child(il)
		row.add_child(_l("%s"%t2,12,CT)); row.add_child(_l("  ×%.0f"%h["qty"],11,CM))
		row.add_child(_l("  %+.2f"%pnl,12,CG if pnl>=0 else CR,true))
		var sp:=Control.new(); sp.size_flags_horizontal=Control.SIZE_EXPAND_FILL; row.add_child(sp)
		var tb:=Button.new(); tb.text="⇄"; tb.flat=true
		tb.add_theme_font_size_override("font_size",13)
		tb.add_theme_color_override("font_color",Color(0.55,0.72,1.0))
		var tt=t2; tb.pressed.connect(func(): _show_trade_popup(tt))
		row.add_child(tb)
		_port_list.add_child(row)

func _refresh_port_detail() -> void:
	if Portfolio.holdings.is_empty(): _port_detail.text="[color=#6e7a99]" + _txt("NO_POSITIONS_DETAIL") + "[/color]"; return
	var txt:="[b]  " + _txt("PORT_HEADER") + "[/b]\n  ────────────────────────────────────────────────────\n"
	var total:=0.0
	for t2 in Portfolio.holdings:
		var h=Portfolio.holdings[t2]; var cur=MarketEngine.get_price(t2)
		var pnl=Portfolio.get_unrealized_pnl(t2); var pct=(cur-h["avg_cost"])/h["avg_cost"]*100.0; total+=pnl
		var col:="[color=#38e085]" if pnl>=0 else "[color=#eb4848]"
		var supply:=MarketEngine.get_supply(t2)
		var own_str:="%s / %s" % [_fmt(h["qty"]), _fmt(supply) if supply > 0 else "—"]
		txt+="  [b]%-8s[/b] %-22s $%-11.2f  $%-11.2f  %s%+.2f[/color]  %s%+.1f%%[/color]\n" % [t2,own_str,h["avg_cost"],cur,col,pnl,col,pct]
	var tc:="[color=#38e085]" if total>=0 else "[color=#eb4848]"
	txt+="\n  [b]" + _txt("PORT_FOOTER") % [tc, total, _fmt(GameState.cash), _fmt(GameState.get_net_worth())] + "[/b]"
	_port_detail.text=txt

func _refresh_lb() -> void:
	var pr:=WealthLeaderboard.get_player_rank(); var nw_b:=GameState.get_net_worth()/1_000_000_000.0
	var txt:="[b]  " + _txt("LB_HEADER") + "[/b]\n  ────────────────────────────────────────────\n"
	for e in WealthLeaderboard.get_top_entries(10):
		txt+="  [b]#%-4d[/b] %-30s $%.1fB   %s\n" % [e[0],e[1],e[2],e[3]]
	if pr>10:
		txt+="\n  [color=#888780]  " + _txt("LB_ENTRIES") % (pr-10) + "[/color]\n\n"
		for e in WealthLeaderboard.get_nearest_entries(7):
			var col:="[color=#FAC775]" if e[0]==pr else ""; var ec:="[/color]" if e[0]==pr else ""
			txt+="  [b]#%-4d[/b] %s%-30s $%.1fB%s\n" % [e[0],col,e[1],e[2],ec]
	txt+="\n  ──────────────────────────────────────────\n"
	if pr<=100: txt+="  [color=#FAC775][b]" + _txt("LB_TOP100") % [pr, nw_b] + "[/b][/color]\n"
	else:
		var nxt:=WealthLeaderboard.BILLIONAIRES[99]
		txt+="  [b]" + _txt("LB_UNRANKED") % [nw_b, nxt[2]-nw_b] + "[/b]"
	_lb_lbl.text=txt

func _add_news(article:Dictionary) -> void:
	var ic=article.get("crisis",false)
	var p:=PanelContainer.new()
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,10)
	var sb:=StyleBoxFlat.new()
	sb.bg_color=Color(0.10,0.07,0.04) if ic else Color(0.04,0.055,0.09,0.88)
	sb.border_color=CO if ic else CB; sb.border_width_left=4 if ic else 0
	p.add_theme_stylebox_override("panel",sb); p.add_child(mg)
	var v:=VBoxContainer.new(); v.add_theme_constant_override("separation",6); mg.add_child(v)
	if ic:
		var tl:=Label.new(); tl.text=article["headline"]; tl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		tl.add_theme_font_size_override("font_size",13); tl.add_theme_color_override("font_color",CO); v.add_child(tl)
	var bl:=Label.new(); bl.text=article["body"]; bl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bl.add_theme_font_size_override("font_size",12)
	bl.add_theme_color_override("font_color",CT if not ic else Color(0.85,0.80,0.72)); v.add_child(bl)
	var dl:=Label.new(); dl.text=article["date"]+"  ·  "+article.get("cat","").to_upper()
	dl.add_theme_font_size_override("font_size",10); dl.add_theme_color_override("font_color",CM); v.add_child(dl)
	if not _news_container: return
	_news_container.add_child(p)
	if _news_container.get_child_count()>7: _news_container.get_child(0).queue_free()

func _refresh_contacts() -> void:
	for c in _contacts_list.get_children(): c.queue_free()
	for ct2 in ContactsSystem.get_available_contacts(): _contacts_list.add_child(_contact_card(ct2))
	for country in CountrySystem.get_owned_with_actions(): _contacts_list.add_child(_ambassador_card(country))

func _contact_card(ct2:Dictionary) -> PanelContainer:
	var p:=PanelContainer.new()
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,10)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.06,0.07,0.11,0.90); sb.border_color=CB
	sb.border_width_top=1; sb.border_width_bottom=1; sb.border_width_left=1; sb.border_width_right=1
	p.add_theme_stylebox_override("panel",sb); p.add_child(mg)
	var v:=VBoxContainer.new(); mg.add_child(v)
	var h:=_hb(8); v.add_child(h)
	h.add_child(_l(ct2.get("portrait","")+"  "+ct2["name"],14,CT,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(f)
	if not ContactsSystem.is_unlocked(ct2["id"]):
		h.add_child(_b(_txt("UNLOCK_BTN") % _fmt(ct2["unlock_cost"]),func(): ContactsSystem.unlock_contact(ct2["id"]); _refresh_contacts()))
	v.add_child(_l(_txt("CTITLE_"+ct2["id"]),11,CM))
	if ContactsSystem.is_unlocked(ct2["id"]):
		_gv(v,4); v.add_child(_l(_txt("CBIO_"+ct2["id"]),10,Color(0.48,0.52,0.60))); _gv(v,6)
		for action in ct2["actions"]:
			var ab:=Button.new(); ab.flat=false; ab.add_theme_font_size_override("font_size",12)
			var cd:=ContactsSystem.get_cooldown(action["id"])
			var lbl:=_txt("CLBL_"+action["id"])
			if cd>0: ab.text=_txt("COOLDOWN_DAYS") % [lbl,cd]; ab.disabled=true
			else: ab.text="%s  —  $%s" % [lbl,_fmt(action["cost"])]
			var cid=ct2["id"]; var aid=action["id"]
			ab.pressed.connect(func(): ContactsSystem.execute_action(cid,aid); _refresh_contacts())
			v.add_child(ab)
	return p

func _ambassador_card(country:Dictionary) -> PanelContainer:
	var p:=PanelContainer.new()
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,10)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.06,0.09,0.06,0.90); sb.border_color=CO
	sb.border_width_top=1; sb.border_width_bottom=1; sb.border_width_left=1; sb.border_width_right=1
	p.add_theme_stylebox_override("panel",sb); p.add_child(mg)
	var v:=VBoxContainer.new(); mg.add_child(v)
	v.add_child(_l("🌍  %s — %s" % [country["name"], _txt("AMBASSADOR")],13,CO,true))
	v.add_child(_l(_txt("REGION_LBL") % country.get("region",""),10,CM)); _gv(v,6)
	for action in country.get("amb_actions",[]):
		var ab:=Button.new(); ab.flat=false; ab.add_theme_font_size_override("font_size",12)
		var ckey="amb_"+country["id"]+"_"+action["id"]
		var cd:=ContactsSystem.get_cooldown(ckey)
		var albl:=_txt("ALBL_"+action["label"])
		if cd>0: ab.text=_txt("COOLDOWN_DAYS") % [albl,cd]; ab.disabled=true
		else: ab.text="%s  —  $%s" % [albl,_fmt(action["cost"])]
		var act=action; var ck=ckey
		ab.pressed.connect(func(): ContactsSystem.execute_country_action(act,ck); _refresh_contacts())
		v.add_child(ab)
	return p

func _pop_dropdown() -> void:
	_tick_sel.clear()
	for t2 in MarketEngine.get_all_tickers(): _tick_sel.add_item(t2)
	for i in _tick_sel.item_count:
		if _tick_sel.get_item_text(i)==_sel_ticker: _tick_sel.select(i); break

# ═══════════════════════════════════════════════════════════════════════════════
# UI FACTORY HELPERS
# ═══════════════════════════════════════════════════════════════════════════════
func _hb(s:int)->HBoxContainer:
	var h:=HBoxContainer.new(); h.add_theme_constant_override("separation",s); return h

func _sbp(c:Control, bb:bool) -> void:
	var sb:=StyleBoxFlat.new(); sb.bg_color=CP; sb.border_color=CB
	if bb: sb.border_width_bottom = 1
	else:  sb.border_width_top = 1
	c.add_theme_stylebox_override("panel",sb)

func _sp(w:int)->PanelContainer:
	var p:=PanelContainer.new(); p.custom_minimum_size=Vector2(w,0)
	p.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var sb:=StyleBoxFlat.new(); sb.bg_color=CP; sb.border_color=CB; sb.border_width_right=1
	p.add_theme_stylebox_override("panel",sb); return p

func _l(t2:String,sz:int,col:Color,bold:bool=false)->Label:
	var l:=Label.new(); l.text=t2
	l.add_theme_font_size_override("font_size",sz); l.add_theme_color_override("font_color",col); return l

func _b(t2:String,cb:Callable)->Button:
	var b:=Button.new(); b.text=t2; b.flat=false
	b.add_theme_font_size_override("font_size",12); b.pressed.connect(cb); return b

func _ba(p:Control,t2:String,cb:Callable)->void: p.add_child(_b(t2,cb))

# Styled button — subtle tinted background with coloured bottom border
func _bst(parent:Control,t2:String,cb:Callable,col:Color)->Button:
	var b:=_b(t2,cb)
	var sn:=StyleBoxFlat.new()
	sn.bg_color=Color(col.r,col.g,col.b,0.10)
	sn.border_color=Color(col.r,col.g,col.b,0.50)
	sn.border_width_bottom=2
	sn.corner_radius_top_left=3; sn.corner_radius_top_right=3
	sn.corner_radius_bottom_left=3; sn.corner_radius_bottom_right=3
	sn.content_margin_left=8; sn.content_margin_right=8
	var sh:=StyleBoxFlat.new()
	sh.bg_color=Color(col.r,col.g,col.b,0.22)
	sh.border_color=Color(col.r,col.g,col.b,0.80)
	sh.border_width_bottom=2
	sh.corner_radius_top_left=3; sh.corner_radius_top_right=3
	sh.corner_radius_bottom_left=3; sh.corner_radius_bottom_right=3
	sh.content_margin_left=8; sh.content_margin_right=8
	b.add_theme_stylebox_override("normal",sn)
	b.add_theme_stylebox_override("hover",sh)
	b.add_theme_color_override("font_color",col)
	parent.add_child(b); return b

# Colored trade button — solid background with border
func _bcolor(b:Button,bg:Color,border:Color,text_col:Color)->void:
	var sn:=StyleBoxFlat.new()
	sn.bg_color=bg; sn.border_color=border
	sn.border_width_bottom=3; sn.border_width_top=1
	sn.border_width_left=1; sn.border_width_right=1
	sn.corner_radius_top_left=4; sn.corner_radius_top_right=4
	sn.corner_radius_bottom_left=4; sn.corner_radius_bottom_right=4
	sn.content_margin_left=10; sn.content_margin_right=10
	var sh:=StyleBoxFlat.new()
	sh.bg_color=Color(bg.r*1.3,bg.g*1.3,bg.b*1.3,0.95)
	sh.border_color=border; sh.border_width_bottom=3; sh.border_width_top=1
	sh.border_width_left=1; sh.border_width_right=1
	sh.corner_radius_top_left=4; sh.corner_radius_top_right=4
	sh.corner_radius_bottom_left=4; sh.corner_radius_bottom_right=4
	sh.content_margin_left=10; sh.content_margin_right=10
	b.add_theme_stylebox_override("normal",sn)
	b.add_theme_stylebox_override("hover",sh)
	b.add_theme_color_override("font_color",text_col)
	b.add_theme_font_size_override("font_size",14)

# Vertical separator for top bar button groups
func _vsep(parent:Control)->void:
	_g(parent,6)
	var s:=ColorRect.new(); s.custom_minimum_size=Vector2(1,26)
	s.color=Color(0.30,0.34,0.44,0.45)
	s.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	parent.add_child(s); _g(parent,6)

func _sh(t2:String)->Control:
	var mg:=MarginContainer.new()
	mg.add_theme_constant_override("margin_left",10); mg.add_theme_constant_override("margin_top",8); mg.add_theme_constant_override("margin_bottom",3)
	var r:=_hb(6); mg.add_child(r)
	var ln:=ColorRect.new(); ln.color=CA; ln.custom_minimum_size=Vector2(3,16); r.add_child(ln)
	r.add_child(_l(t2,11,Color(0.65,0.72,0.88),true)); return mg

func _g(p:Control,w:int)->void:
	var s:=Control.new(); s.custom_minimum_size=Vector2(w,0); p.add_child(s)

func _gv(p:Control,h:int)->void:
	var s:=Control.new(); s.custom_minimum_size=Vector2(0,h); p.add_child(s)

func _mg12(parent:Control)->Control:
	var mg:=MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s,12)
	parent.add_child(mg); return mg

func _ovp(l:float,r:float,b:float,bc:Color)->PanelContainer:
	var p:=PanelContainer.new(); p.visible=false
	p.set_anchor_and_offset(SIDE_LEFT,l,0); p.set_anchor_and_offset(SIDE_RIGHT,r,0)
	p.set_anchor_and_offset(SIDE_TOP,0,66); p.set_anchor_and_offset(SIDE_BOTTOM,b,0)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.04,0.05,0.09,0.96); sb.border_color=bc
	sb.border_width_top=1; sb.border_width_bottom=1; sb.border_width_left=1; sb.border_width_right=1
	p.add_theme_stylebox_override("panel",sb); return p

func _ovpc(l:float,r:float,t2:float,b:float,bc:Color)->PanelContainer:
	var p:=PanelContainer.new(); p.visible=false
	p.set_anchor_and_offset(SIDE_LEFT,l,0); p.set_anchor_and_offset(SIDE_RIGHT,r,0)
	p.set_anchor_and_offset(SIDE_TOP,t2,0); p.set_anchor_and_offset(SIDE_BOTTOM,b,0)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0.04,0.05,0.09,0.96); sb.border_color=bc
	sb.border_width_top=1; sb.border_width_bottom=1; sb.border_width_left=1; sb.border_width_right=1
	p.add_theme_stylebox_override("panel",sb); return p

func _msg(t2:String,col:Color=CM)->void:
	_msg_lbl.text=t2; _msg_lbl.add_theme_color_override("font_color",col)

func _offer_txt(offer: Dictionary, key: String) -> String:
	var lang := LocaleSystem.current_language
	if lang != "en":
		var tr_key := key + "_" + lang
		if offer.has(tr_key): return offer[tr_key]
	return offer.get(key, "")

func _fmt(n:float)->String:
	if n>=1_000_000_000_000: return "%.2fT"%(n/1_000_000_000_000.0)
	elif n>=1_000_000_000: return "%.2fB"%(n/1_000_000_000.0)
	elif n>=1_000_000:   return "%.2fM"%(n/1_000_000.0)
	elif n>=1_000:       return "%.1fK"%(n/1_000.0)
	return "%.2f"%n
func _draw_buildings_on_map(ml: float, mt: float, mw: float, mh: float) -> void:
	var font := ThemeDB.fallback_font
	for b in BuildingSystem.BUILDINGS:
		var nx := (float(b["lon"]) + 180.0) / 360.0
		var ny := (90.0 - float(b["lat"])) / 180.0
		var px := ml + nx * mw
		var py := mt + ny * mh
		var owned := BuildingSystem.is_owned(b["id"])
		var dw: float = float(b.get("dw", 40.0)) * 0.5
		var dh: float = float(b.get("dh", 40.0)) * 0.5
		var rect := Rect2(px - dw * 0.5, py - dh, dw, dh)
		var tex: Texture2D = BuildingSystem.get_texture(b["id"])
		if tex:
			var tint := Color(1.0, 1.0, 1.0, 0.92) if owned else Color(0.95, 0.82, 0.35, 0.85)
			draw_texture_rect(tex, rect, false, tint)
		else:
			var col := Color(0.20, 0.96, 0.55, 0.95) if owned else Color(0.95, 0.80, 0.20, 0.90)
			draw_circle(Vector2(px, py - dh * 0.5), 6.0, col)
		draw_string(font, Vector2(px - dw * 0.5, py + 10.0), b["name"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(1.0, 0.95, 0.55, 0.85) if not owned else Color(0.35, 1.0, 0.60, 0.85))

func _draw_mega_markers(ml: float, mt: float, mw: float, mh: float) -> void:
	var font := ThemeDB.fallback_font
	var pulse := 0.7 + 0.3 * sin(_t * 2.5)
	for p in MegaProjectSystem.PROJECTS:
		var nx := (float(p["lon"]) + 180.0) / 360.0
		var ny := (90.0 - float(p["lat"])) / 180.0
		var px := ml + nx * mw
		var py := mt + ny * mh
		var complete := MegaProjectSystem.is_complete(p["id"])
		var building := MegaProjectSystem.is_owned(p["id"]) and not complete
		var col: Color
		if complete:    col = Color(0.20, 1.00, 0.55, 0.95)
		elif building:  col = Color(1.00, 0.75, 0.10, 0.80 + 0.20 * pulse)
		else:           col = Color(0.40, 0.75, 1.00, 0.70 + 0.25 * pulse)
		draw_circle(Vector2(px, py), 9.0, Color(col.r, col.g, col.b, 0.20))
		draw_circle(Vector2(px, py), 6.0, col)
		draw_arc(Vector2(px, py), 6.0, 0, TAU, 32, Color(1, 1, 1, 0.25), 1.0)
		draw_string(font, Vector2(px + 9.0, py + 4.0), p["icon"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.90))

func _mega_at(pos: Vector2) -> String:
	if _map_bounds.is_empty(): return ""
	var ml: float = _map_bounds["ml"]; var mt: float = _map_bounds["mt"]
	var mw: float = _map_bounds["mw"]; var mh: float = _map_bounds["mh"]
	for p in MegaProjectSystem.PROJECTS:
		var nx := (float(p["lon"]) + 180.0) / 360.0
		var ny := (90.0 - float(p["lat"])) / 180.0
		var px := ml + nx * mw
		var py := mt + ny * mh
		if pos.distance_to(Vector2(px, py)) < 18.0: return p["id"]
	return ""

func _show_mega_popup(pid: String) -> void:
	if _mega_popup and is_instance_valid(_mega_popup): _mega_popup.queue_free()
	var p := MegaProjectSystem._find(pid)
	if p.is_empty(): return
	var lang    := LocaleSystem.current_language
	var pname   = p.get("name_tr", p["name"])   if lang == "tr" else p["name"]
	var pdesc_raw = p.get("desc_tr", p["desc"]) if lang == "tr" else p["desc"]
	var pdesc   = pdesc_raw % GameState.company_name if "%s" in pdesc_raw else pdesc_raw
	var teal    := Color(0.30, 0.90, 0.70)
	var pop     := _ovpc(0.18, 0.82, 0.12, 0.90, teal)
	pop.visible = true
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]: mg.add_theme_constant_override(s, 18)
	pop.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 12); mg.add_child(v)
	# Header
	var hrow := _hb(10); v.add_child(hrow)
	hrow.add_child(_l(p["icon"], 28, teal))
	var ht := _l(_txt("MEGA_TITLE"), 11, teal, true)
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hrow.add_child(ht)
	_ba(hrow, "✕", func(): pop.queue_free(); _mega_popup = null)
	var div := ColorRect.new(); div.color = Color(teal.r, teal.g, teal.b, 0.35)
	div.custom_minimum_size = Vector2(0, 2); v.add_child(div)
	# Name
	var nl := _l(pname, 18, CT, true); nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(nl)
	# Desc
	var dl := _l(pdesc, 12, Color(0.78, 0.82, 0.88))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(dl)
	# Stats
	var stat_div := ColorRect.new(); stat_div.color = Color(teal.r, teal.g, teal.b, 0.20)
	stat_div.custom_minimum_size = Vector2(0, 1); v.add_child(stat_div)
	var sv := VBoxContainer.new(); sv.add_theme_constant_override("separation", 6); v.add_child(sv)
	sv.add_child(_l(_txt("MEGA_PRICE") % _fmt(float(p["price"])), 13, CO, true))
	var bd: int = p["build_days"]
	sv.add_child(_l(_txt("MEGA_BUILD") % (_txt("MEGA_BUILD_DAYS") % [bd, bd / 365]), 12, CM))
	match p["income_type"]:
		"daily", "atlantis":
			sv.add_child(_l(_txt("MEGA_INCOME") % _fmt(float(p["daily_income"])), 13, CG, true))
		"mariana":
			sv.add_child(_l(_txt("MEGA_INCOME_MAR") % [p.get("daily_xau",12), p.get("daily_xag",60)], 13, CG, true))
		"annual_limited":
			sv.add_child(_l(_txt("MEGA_INCOME_ANN") % _fmt(float(p["price"])), 13, CG, true))
	# Status / Buy button
	var state := MegaProjectSystem.get_state(pid)
	if state.is_empty():
		# Not purchased
		var can := GameState.cash >= float(p["price"])
		var btn := _b(_txt("MEGA_BUY") % _fmt(float(p["price"])), func():
			if MegaProjectSystem.buy(pid):
				_mega_popup.queue_free(); _mega_popup = null)
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", teal)
		if not can: btn.disabled = true
		v.add_child(btn)
	elif not state.get("complete", false):
		# Building
		v.add_child(_l(_txt("MEGA_BUILDING"), 13, Color(1.0, 0.75, 0.10), true))
		v.add_child(_l(_txt("MEGA_DAYS_LEFT") % state.get("days_remaining", 0), 12, CM))
	else:
		# Complete
		v.add_child(_l(_txt("MEGA_COMPLETE"), 14, CG, true))
	_mega_popup = pop
	add_child(pop)

func _building_at(pos: Vector2) -> String:
	var W := size.x; var H := size.y
	var ml := 36.0; var mt := 58.0; var mw := W - 72.0; var mh := H - 118.0
	for b in BuildingSystem.BUILDINGS:
		var nx := (float(b["lon"]) + 180.0) / 360.0
		var ny := (90.0 - float(b["lat"])) / 180.0
		var px := ml + nx * mw
		var py := mt + ny * mh
		var dw: float = float(b.get("dw", 40.0)) * 0.5
		var dh: float = float(b.get("dh", 40.0)) * 0.5
		var rect := Rect2(px - dw * 0.5, py - dh, dw, dh)
		if rect.has_point(pos):
			return b["id"]
	return ""

func _show_building_popup(bid: String) -> void:
	var b := BuildingSystem.get_building(bid)
	if b.is_empty(): return
	for ch in _building_popup.get_children(): ch.queue_free()
	var mg := MarginContainer.new()
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(s, 14)
	_building_popup.add_child(mg)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); mg.add_child(v)
	var hh := _hb(8)
	hh.add_child(_l("🏛  " + b["name"], 15, Color(1.0, 0.90, 0.40), true))
	var f := Control.new(); f.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hh.add_child(f)
	_ba(hh, "✕", func(): _building_popup.visible = false); v.add_child(hh)
	v.add_child(_l(b["loc"], 11, Color(0.65, 0.68, 0.78)))
	var div := ColorRect.new(); div.color = Color(0.85, 0.65, 0.20, 0.35)
	div.custom_minimum_size = Vector2(0, 1); v.add_child(div)
	v.add_child(_l(b["effect"], 12, Color(0.70, 0.92, 0.65)))
	v.add_child(_l(_txt("BLDG_PRICE") % _fmt(float(b["price"])), 13, Color(0.95, 0.80, 0.20)))
	if BuildingSystem.is_owned(bid):
		v.add_child(_l(_txt("BLDG_OWNED"), 13, Color(0.22, 0.90, 0.52)))
	else:
		var bb := _b(_txt("BLDG_PURCHASE") % _fmt(float(b["price"])),
			func(): _on_buy_building(bid))
		if GameState.cash < float(b["price"]): bb.disabled = true
		v.add_child(bb)
	_building_popup.visible = true

func _on_buy_building(bid: String) -> void:
	if BuildingSystem.buy(bid):
		var b := BuildingSystem.get_building(bid)
		_msg(_txt("MSG_BUILDING") % b.get("name", bid), Color(0.95, 0.80, 0.20))
		_building_popup.visible = false
		queue_redraw()
func _b_txt(btn_text: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = tr(btn_text) # Metni arayüze/çeviriye uygun hale getirir
	b.pressed.connect(action) # Tıklandığında çalışacak olan kodu bağlar
	return b
