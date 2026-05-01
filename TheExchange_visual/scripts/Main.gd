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
var _country_popup:  PanelContainer

# ── KEY: store content columns so we can hide them ───────────────────────────
var _content_columns: HBoxContainer

var _sel_ticker      := "GIDX"
var _current_offer:  Dictionary = {}
var _hovered_country := ""

# ── Background animation data ─────────────────────────────────────────────────
var _t      := 0.0
var _lights := []
var _stars  := []
var _rain   := []

# ── Colours ───────────────────────────────────────────────────────────────────
const CP = Color(0.04, 0.05, 0.09, 0.72)   # panels – more transparent so bg shows
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
func _t(key: String) -> String:
	return LocaleSystem.tr(key)

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

	# Rebuild UI when the player switches language
	LocaleSystem.language_changed.connect(_on_language_changed)

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
	_country_popup = null; _content_columns = null
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

# ── BASEMENT ──────────────────────────────────────────────────────────────────
func _bg_basement(W: float, H: float) -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.068,0.070,0.080))
	draw_rect(Rect2(0,0,W,H*0.14), Color(0.090,0.092,0.102))
	for yp in [H*0.100, H*0.135, H*0.172]:
		draw_rect(Rect2(0,yp,W,7), Color(0.18,0.16,0.14))
		draw_rect(Rect2(0,yp,W,2), Color(0.30,0.25,0.20))
	draw_rect(Rect2(W*0.09,0,11,H*0.73), Color(0.170,0.150,0.130))
	draw_rect(Rect2(W*0.09,0,2.5,H*0.73), Color(0.280,0.230,0.180))
	var rng := RandomNumberGenerator.new(); rng.seed = 11223
	for _i in 8:
		draw_rect(Rect2(rng.randf_range(0.1,0.85)*W, rng.randf_range(0.18,0.62)*H,
			rng.randf_range(20,90), rng.randf_range(40,130)), Color(0.055,0.065,0.085,0.55))
	var wx:=W*0.65; var wy:=H*0.15; var ww:=W*0.18; var wh:=H*0.13
	draw_rect(Rect2(wx,wy,ww,wh), Color(0.04,0.06,0.12))
	for s in _stars:
		draw_circle(Vector2(wx+s["x"]*ww, wy+s["y"]*wh*0.6), s["r"],
			Color(1,1,1,(0.35+0.5*abs(sin(_t*s["sp"]+s["ph"])))*0.72))
	for gi in 5: draw_rect(Rect2(wx+gi*(ww/5.0),wy,2.5,wh), Color(0.10,0.10,0.11,0.85))
	draw_rect(Rect2(wx-5,wy-5,ww+10,5), Color(0.13,0.12,0.11))
	draw_rect(Rect2(wx-5,wy+wh,ww+10,5), Color(0.13,0.12,0.11))
	draw_rect(Rect2(wx-5,wy-5,5,wh+10), Color(0.13,0.12,0.11))
	draw_rect(Rect2(wx+ww,wy-5,5,wh+10), Color(0.13,0.12,0.11))
	draw_rect(Rect2(0,H*0.73,W,H-H*0.73), Color(0.075,0.070,0.065))
	draw_rect(Rect2(0,H*0.73,W,4), Color(0.160,0.140,0.120))
	draw_rect(Rect2(W*0.28,H*0.58,W*0.44,H*0.14), Color(0.150,0.120,0.100))
	draw_rect(Rect2(W*0.28,H*0.58,W*0.44,3), Color(0.280,0.210,0.170))
	for lx2 in [W*0.30, W*0.68]: draw_rect(Rect2(lx2,H*0.72,8,H*0.06), Color(0.12,0.10,0.08))
	_draw_crt(W*0.43, H*0.30, W*0.16, H*0.26)
	var bx := W*0.35; var by_ := H*0.24
	draw_line(Vector2(bx,0), Vector2(bx,by_), Color(0.18,0.15,0.12), 2.5)
	draw_circle(Vector2(bx,by_), 8, Color(1.0,0.95,0.72, 0.88+0.12*sin(_t*1.3)))
	draw_colored_polygon(PackedVector2Array([Vector2(bx-8,by_+8),Vector2(bx+8,by_+8),
		Vector2(bx+130,H*0.73),Vector2(bx-130,H*0.73)]), Color(1.0,0.94,0.68,0.04))
	draw_circle(Vector2(W*0.24, H*0.40+fmod(_t*48.0,H*0.32)), 2.8, Color(0.30,0.38,0.55,0.75))
	draw_rect(Rect2(W*0.05,H*0.60,W*0.10,H*0.12), Color(0.30,0.24,0.16))
	draw_rect(Rect2(W*0.06,H*0.55,W*0.08,H*0.08), Color(0.27,0.22,0.15))
	_draw_papers(W*0.30, H*0.715); _draw_mug(W*0.62, H*0.715)
	_draw_scan(W, H, 0.04)

# ── SMALL OFFICE ──────────────────────────────────────────────────────────────
func _bg_small_office(W: float, H: float) -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.13,0.14,0.16))
	_draw_window(W*0.52, H*0.07, W*0.44, H*0.58, 1)
	draw_rect(Rect2(0,H*0.73,W,H-H*0.73), Color(0.17,0.15,0.13))
	draw_rect(Rect2(0,H*0.73,W,4), Color(0.32,0.27,0.22))
	draw_rect(Rect2(W*0.06,H*0.60,W*0.62,H*0.13), Color(0.22,0.19,0.16))
	draw_rect(Rect2(W*0.06,H*0.60,W*0.62,3), Color(0.40,0.33,0.26))
	_draw_mon(W*0.10,H*0.20,W*0.22,H*0.38,0)
	_draw_mon(W*0.36,H*0.17,W*0.22,H*0.42,1)
	_draw_lamp(W*0.72, H*0.72); _draw_mug(W*0.78, H*0.715); _draw_papers(W*0.10, H*0.715)
	_draw_scan(W, H, 0.03)

# ── TRADING FLOOR ─────────────────────────────────────────────────────────────
func _bg_trading_floor(W: float, H: float) -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.06,0.07,0.095))
	_draw_window(W*0.26, H*0.04, W*0.70, H*0.60, 2)
	draw_rect(Rect2(0,H*0.72,W,H-H*0.72), Color(0.085,0.085,0.105))
	for ti in 9: draw_rect(Rect2(float(ti)*W/9.0,H*0.72,1.5,H*0.28), Color(0.14,0.14,0.17,0.55))
	draw_rect(Rect2(W*0.03,H*0.59,W*0.76,H*0.13), Color(0.11,0.10,0.13))
	draw_rect(Rect2(W*0.03,H*0.59,W*0.76,3), Color(0.24,0.28,0.40))
	_draw_mon(W*0.04,H*0.22,W*0.18,H*0.35,0); _draw_mon(W*0.24,H*0.18,W*0.18,H*0.39,1)
	_draw_mon(W*0.44,H*0.22,W*0.18,H*0.35,2); _draw_mon(W*0.64,H*0.26,W*0.15,H*0.30,3)
	draw_rect(Rect2(W*0.13,H*0.675,W*0.24,H*0.032), Color(0.14,0.14,0.17))
	for ki in 15: draw_rect(Rect2(W*0.135+ki*(W*0.013),H*0.678,W*0.011,H*0.022), Color(0.20,0.19,0.23))
	_draw_lamp(W*0.85, H*0.72); _draw_mug(W*0.89, H*0.715)
	_draw_scan(W, H, 0.025)

# ── PENTHOUSE ─────────────────────────────────────────────────────────────────
func _bg_penthouse(W: float, H: float) -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.04,0.045,0.062))
	_draw_window(W*0.01, H*0.02, W*0.98, H*0.64, 3)
	draw_rect(Rect2(0,H*0.72,W,H-H*0.72), Color(0.15,0.15,0.17))
	var rng := RandomNumberGenerator.new(); rng.seed = 55667
	for _i in 22: draw_rect(Rect2(rng.randf()*W,H*0.72,rng.randf_range(30,200),1), Color(0.20,0.20,0.22,0.28))
	var dp := PackedVector2Array([
		Vector2(W*0.07,H*0.72),Vector2(W*0.07,H*0.62),Vector2(W*0.30,H*0.595),
		Vector2(W*0.72,H*0.595),Vector2(W*0.93,H*0.62),Vector2(W*0.93,H*0.72)])
	draw_colored_polygon(dp, Color(0.09,0.08,0.11))
	draw_polyline(dp, Color(0.35,0.52,0.92,0.32), 2.5, false)
	var mp := [[W*0.04,H*0.20,W*0.16,H*0.38],[W*0.22,H*0.15,W*0.16,H*0.42],
		[W*0.40,H*0.13,W*0.18,H*0.45],[W*0.60,H*0.15,W*0.16,H*0.42],
		[W*0.78,H*0.20,W*0.14,H*0.38],[W*0.07,H*0.38,W*0.10,H*0.22]]
	for mi in mp.size(): _draw_mon(mp[mi][0],mp[mi][1],mp[mi][2],mp[mi][3],mi)
	_draw_whisky(W*0.91, H*0.70)
	_draw_scan(W, H, 0.015)

# ── WORLD MAP ─────────────────────────────────────────────────────────────────
func _draw_map(W: float, H: float) -> void:
	draw_rect(Rect2(0,0,W,H), Color(0.04,0.09,0.18))
	var ml:=40.0; var mt:=62.0; var mw:=W-80.0; var mh:=H-130.0
	var f := func(lon:float,lat:float)->Vector2:
		return Vector2(ml+(lon+180.0)/360.0*mw, mt+(90.0-lat)/180.0*mh)
	# Continents
	for poly_pts in [
		[[-165,65],[-60,72],[-55,47],[-80,25],[-87,15],[-105,18],[-120,32],[-130,52]],
		[[-73,12],[-35,5],[-35,-23],[-52,-35],[-65,-55],[-75,-45],[-80,-5]],
		[[-10,36],[-9,44],[5,48],[15,54],[28,70],[32,47],[28,36]],
		[[-17,35],[32,30],[45,10],[40,-10],[32,-28],[18,-35],[8,-5],[-17,15]],
		[[35,37],[60,55],[90,52],[132,50],[145,43],[122,22],[100,12],[70,8],[45,15]],
		[[114,-22],[131,-12],[153,-25],[151,-38],[130,-35],[114,-32]]
	]:
		var pts := PackedVector2Array()
		for p in poly_pts: pts.append(f.call(float(p[0]), float(p[1])))
		draw_colored_polygon(pts, Color(0.14,0.19,0.12))
		draw_polyline(pts, Color(0.28,0.38,0.22,0.8), 1.0, true)
	var font := ThemeDB.fallback_font
	for c in CountrySystem.get_all():
		var pos = f.call(float(c["lon"]), float(c["lat"]))
		var owned := CountrySystem.is_owned(c["id"])
		var hov   = _hovered_country == c["id"]
		var r     := 10.0 if hov else 7.0
		var col   := Color.from_string(c.get("color","#888780"), Color.WHITE)
		if owned:
			draw_circle(pos, r+4, Color(1.0,0.85,0.2,0.35))
			draw_circle(pos, r, col)
			draw_arc(pos, r, 0, TAU, 16, Color(1.0,0.85,0.2,0.9), 2.0)
		else:
			draw_circle(pos, r, Color(col.r,col.g,col.b,0.50))
			draw_arc(pos, r, 0, TAU, 16, Color(col.r, col.g, col.b, 0.85), 1.2)
		if hov or owned:
			draw_string(font, pos+Vector2(12,-4), c["name"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1,1,1,0.95))
			if not owned:
				draw_string(font, pos+Vector2(12,8), "$%dM" % c["price"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9,0.85,0.4,0.9))
	draw_string(font, Vector2(ml,mt-36), _t("MAP_TITLE"),
		HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(0.7,0.75,0.9,0.9))
	draw_string(font, Vector2(W-200,mt-36), _t("MAP_OWNED") % [CountrySystem.owned.size(),CountrySystem.COUNTRIES.size()],
		HORIZONTAL_ALIGNMENT_LEFT,-1,11,CO)
	_draw_scan(W, H, 0.02)

func _gui_input(event: InputEvent) -> void:
	if not _map_panel or not _map_panel.visible: return
	if event is InputEventMouseMotion:
		_hovered_country = _country_at(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cid := _country_at(event.position)
		if cid != "": _show_country_popup(cid)

func _country_at(pos: Vector2) -> String:
	var W := size.x; var H := size.y
	var ml:=40.0; var mt:=62.0; var mw:=W-80.0; var mh:=H-130.0
	for c in CountrySystem.get_all():
		var cx := ml+(float(c["lon"])+180.0)/360.0*mw
		var cy := mt+(90.0-float(c["lat"]))/180.0*mh
		if Vector2(cx,cy).distance_to(pos) < 14: return c["id"]
	return ""

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
	draw_colored_polygon(sil, Color(0.055,0.060,0.090))
	for l in _lights:
		var lx_=wx+l["x"]*ww; var ly_=l["y"]*size.y
		if lx_<wx or lx_>wx+ww or ly_<wy+wh*0.50 or ly_>wy+wh: continue
		var a_:=0.72; if l["blink"]: a_=0.35+0.55*abs(sin(_t*l["sp"]+l["ph"]))
		draw_rect(Rect2(lx_,ly_,l["w"]*ww,l["h"]*wh*0.45), Color(l["r"],l["g"],l["b"],a_*0.80))
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

func _draw_whisky(cx:float,by_:float) -> void:
	var pts:=PackedVector2Array([Vector2(cx-14,by_),Vector2(cx-10,by_-28),Vector2(cx+10,by_-28),Vector2(cx+14,by_)])
	draw_colored_polygon(pts,Color(0.80,0.60,0.18,0.32)); draw_polyline(pts,Color(0.90,0.75,0.35,0.65),1.5,true)
	draw_rect(Rect2(cx-5,by_-22,10,10),Color(0.80,0.90,1.0,0.45))

func _draw_scan(W:float,H:float,str:float) -> void:
	var y:=0.0
	while y<H: draw_line(Vector2(0,y),Vector2(W,y),Color(0,0,0,0.025),1.0); y+=4.0
	var d:=W*(0.05+str)
	draw_rect(Rect2(0,0,d,H),Color(0,0,0,0.18+str)); draw_rect(Rect2(W-d,0,d,H),Color(0,0,0,0.18+str))
	draw_rect(Rect2(0,0,W,H*0.04),Color(0,0,0,0.12)); draw_rect(Rect2(0,H*0.96,W,H*0.04),Color(0,0,0,0.12))

# ═══════════════════════════════════════════════════════════════════════════════
# UI BUILD
# ═══════════════════════════════════════════════════════════════════════════════
func _build_ui() -> void:
	# Subtle overlay — low alpha so animated background shows through UI panels
	var ov:=ColorRect.new(); ov.color=Color(0,0,0,0.28)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(ov)

	# Top bar
	var top:=_hb(7); top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom=50; _sbp(top,true); add_child(top)
	_g(top,10); _date_lbl=_l("Jan 1, 1990",13,CM); top.add_child(_date_lbl); _g(top,8)
	var dot:=ColorRect.new(); dot.color=CG; dot.custom_minimum_size=Vector2(6,6); top.add_child(dot); _g(top,6)
	_cash_lbl=_l("$1.0M",16,CT,true); top.add_child(_cash_lbl); _g(top,6)
	_nw_lbl=_l("Net: $1.0M",12,CM); top.add_child(_nw_lbl); _g(top,6)
	_inf_lbl=_l("│  Inf: 0/5",12,CA); top.add_child(_inf_lbl); _g(top,6)
	_rank_lbl=_l("│  #100+",12,CO); top.add_child(_rank_lbl); _g(top,6)
	_off_lbl=_l("⌂  "+LocaleSystem.office_name(0),11,CM); top.add_child(_off_lbl)
	var tf:=Control.new(); tf.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(tf)
	_pause_btn=_b(_t("PAUSE"),_on_pause); top.add_child(_pause_btn)
	_ba(top,_t("SAVE"),_on_save); _ba(top,_t("LOAD"),_on_load)
	_ba(top,_t("WORLD"),_toggle_map); _ba(top,_t("RANK"),_toggle_lb)
	_ba(top,_t("SETTINGS"),_toggle_settings)
	_ba(top,_t("MENU"),func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_ba(top,_t("CONTACTS_BTN"),_toggle_contacts); _g(top,8)

	# Bottom bar
	var bot:=_hb(8); bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_top=-60; _sbp(bot,false); add_child(bot)
	_g(bot,10); bot.add_child(_l(_t("ASSET_LBL"),11,CM)); _g(bot,4)
	_tick_sel=OptionButton.new(); _tick_sel.custom_minimum_size=Vector2(156,36); bot.add_child(_tick_sel)
	_g(bot,8); bot.add_child(_l(_t("QTY_LBL"),11,CM)); _g(bot,4)
	_qty_in=SpinBox.new(); _qty_in.min_value=1; _qty_in.max_value=999999
	_qty_in.value=10; _qty_in.step=1; _qty_in.custom_minimum_size=Vector2(108,36); bot.add_child(_qty_in)
	_g(bot,10)
	var buy_b:=_b(_t("BUY_BTN"),_on_buy); buy_b.add_theme_color_override("font_color",CG); bot.add_child(buy_b)
	var sel_b:=_b(_t("SELL_BTN"),_on_sell); sel_b.add_theme_color_override("font_color",CR); bot.add_child(sel_b)
	_g(bot,10)
	_msg_lbl=_l(_t("TIME_MSG"),12,CM)
	_msg_lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bot.add_child(_msg_lbl)

	# ── Content columns (stored so map can hide/show them) ────────────────────
	_content_columns=HBoxContainer.new()
	_content_columns.set_anchor_and_offset(SIDE_LEFT,0,0); _content_columns.set_anchor_and_offset(SIDE_RIGHT,1,0)
	_content_columns.set_anchor_and_offset(SIDE_TOP,0,50); _content_columns.set_anchor_and_offset(SIDE_BOTTOM,1,-60)
	_content_columns.add_theme_constant_override("separation",0); add_child(_content_columns)

	# Left panel
	var left:=_sp(284); _content_columns.add_child(left)
	var lv:=VBoxContainer.new(); lv.size_flags_vertical=Control.SIZE_EXPAND_FILL; left.add_child(lv)
	lv.add_child(_sh(_t("LIVE_MARKETS")))
	var ts:=ScrollContainer.new(); ts.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ts.custom_minimum_size=Vector2(0,180); lv.add_child(ts)
	_ticker_list=VBoxContainer.new(); _ticker_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ts.add_child(_ticker_list)
	var ph:=_hb(6); ph.add_child(_sh(_t("PORTFOLIO")))
	var pff:=Control.new(); pff.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ph.add_child(pff)
	var pdb:=_b(_t("DETAILS"),_toggle_portfolio); pdb.add_theme_font_size_override("font_size",11); ph.add_child(pdb); lv.add_child(ph)
	var ps:=ScrollContainer.new(); ps.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ps.custom_minimum_size=Vector2(0,90); lv.add_child(ps)
	_port_list=VBoxContainer.new(); _port_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ps.add_child(_port_list)
	lv.add_child(_office_card())

	# Center (chart)
	var ctr:=VBoxContainer.new(); ctr.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ctr.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var csb:=StyleBoxFlat.new(); csb.bg_color=Color(0.02,0.025,0.04,0.65)
	csb.border_color = CB
	csb.border_width_left = 1
	csb.border_width_right = 1
	ctr.add_theme_stylebox_override("panel",csb); _content_columns.add_child(ctr)
	var chm:=MarginContainer.new()
	chm.add_theme_constant_override("margin_left",10)
	chm.add_theme_constant_override("margin_top",5); chm.add_theme_constant_override("margin_bottom",5)
	var ch:=_hb(8); chm.add_child(ch); ctr.add_child(chm)
	_sel_lbl=_l(_t("SELECT_ASSET"),12,CM); ch.add_child(_sel_lbl)
	_chart=ChartControl.new(); _chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_chart.size_flags_vertical=Control.SIZE_EXPAND_FILL; _chart.set_ticker(_sel_ticker); ctr.add_child(_chart)

	# Right (news)
	var right:=_sp(296); _content_columns.add_child(right)
	var rv:=VBoxContainer.new(); rv.size_flags_vertical=Control.SIZE_EXPAND_FILL; right.add_child(rv)
	rv.add_child(_sh(_t("INTEL_FEED")))
	var ns:=ScrollContainer.new(); ns.size_flags_vertical=Control.SIZE_EXPAND_FILL; rv.add_child(ns)
	_news_container=VBoxContainer.new(); _news_container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_news_container.add_theme_constant_override("separation",8); ns.add_child(_news_container)

	# Overlay panels (drawn on top of everything)
	_build_contacts_panel()
	_build_portfolio_panel()
	_build_lb_panel()
	_build_settings_panel()
	_build_spec_panel()
	_build_map_panel()

func _build_contacts_panel() -> void:
	_contacts_panel=_ovp(0.24,0.99,0.97,CA); add_child(_contacts_panel)
	var v:=VBoxContainer.new(); _contacts_panel.add_child(v)
	var mg:=_mg12(v); var hh:=_hb(8); mg.add_child(hh)
	hh.add_child(_l(_t("CONTACTS_TITLE"),13,CA,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f)
	_ba(hh,"✕",_toggle_contacts)
	var cs:=ScrollContainer.new(); cs.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(cs)
	_contacts_list=VBoxContainer.new(); _contacts_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_contacts_list.add_theme_constant_override("separation",10); cs.add_child(_contacts_list)

func _build_portfolio_panel() -> void:
	_port_panel=_ovp(0.24,0.76,0.96,CB); add_child(_port_panel)
	var v:=VBoxContainer.new(); _port_panel.add_child(v)
	var mg:=_mg12(v); var hh:=_hb(8); mg.add_child(hh)
	hh.add_child(_l(_t("PORTFOLIO_ALL"),14,CT,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f); _ba(hh,"✕",_toggle_portfolio)
	var ps:=ScrollContainer.new(); ps.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(ps)
	_port_detail=RichTextLabel.new(); _port_detail.bbcode_enabled=true; _port_detail.fit_content=true
	_port_detail.add_theme_font_size_override("normal_font_size",12)
	_port_detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ps.add_child(_port_detail)

func _build_lb_panel() -> void:
	_lb_panel=_ovp(0.30,0.72,0.97,CO); add_child(_lb_panel)
	var v:=VBoxContainer.new(); _lb_panel.add_child(v)
	var mg:=_mg12(v); var hh:=_hb(8); mg.add_child(hh)
	hh.add_child(_l(_t("WEALTH_RANK"),14,CO,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f); _ba(hh,"✕",_toggle_lb)
	var ps:=ScrollContainer.new(); ps.size_flags_vertical=Control.SIZE_EXPAND_FILL; v.add_child(ps)
	_lb_lbl=RichTextLabel.new(); _lb_lbl.bbcode_enabled=true; _lb_lbl.fit_content=true
	_lb_lbl.add_theme_font_size_override("normal_font_size",12)
	_lb_lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; ps.add_child(_lb_lbl)

func _build_settings_panel() -> void:
	_settings_panel=_ovpc(0.30,0.70,0.14,0.86,CA); add_child(_settings_panel)
	var v:=VBoxContainer.new(); _settings_panel.add_child(v)
	var mg:=_mg12(v); var mv:=VBoxContainer.new(); mv.add_theme_constant_override("separation",12); mg.add_child(mv)
	var hh:=_hb(8); hh.add_child(_l(_t("SETTINGS_TITLE"),15,CT,true))
	var f:=Control.new(); f.size_flags_horizontal=Control.SIZE_EXPAND_FILL; hh.add_child(f); _ba(hh,"✕",_toggle_settings); mv.add_child(hh)
	# Resolution
	mv.add_child(_l(_t("RESOLUTION"),10,CM))
	for res in [[1280,720,"1280×720"],[1440,900,"1440×900"],[1600,900,"1600×900"],[1920,1080,"1920×1080 Full HD"],[2560,1440,"2560×1440 2K"]]:
		mv.add_child(_b(res[2],func(): DisplayServer.window_set_size(Vector2i(res[0],res[1]))))
	# Music volume
	mv.add_child(_l(_t("MUSIC_VOLUME"),10,CM))
	var vr:=_hb(8); vr.add_child(_l(_t("VOLUME_LBL"),12,CM))
	var sl:=HSlider.new(); sl.min_value=0.0; sl.max_value=1.0; sl.value=0.42; sl.step=0.01
	sl.custom_minimum_size=Vector2(160,28); sl.value_changed.connect(func(v2): MusicSystem.set_volume(v2))
	vr.add_child(sl); mv.add_child(vr)
	# Language selector
	mv.add_child(_l(_t("LANGUAGE_LBL"),10,CM))
	var lr:=_hb(8); mv.add_child(lr)
	var en_b:=_b("English", func(): LocaleSystem.set_language("en"))
	var tr_b:=_b("Türkçe",  func(): LocaleSystem.set_language("tr"))
	# Highlight the active language
	if LocaleSystem.current_language == "en":
		en_b.add_theme_color_override("font_color", CG)
	else:
		tr_b.add_theme_color_override("font_color", CG)
	lr.add_child(en_b); lr.add_child(tr_b)

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
	var pl:=_l("Price: —",12,CM); pl.name="sprice"; mv.add_child(pl)
	mv.add_child(_l(_t("SPEC_WARN"),10,Color(0.8,0.6,0.3)))
	var br:=_hb(12); mv.add_child(br)
	var ab:=_b(_t("ACCEPT_PAY"),_on_spec_accept); ab.add_theme_color_override("font_color",CG); br.add_child(ab)
	br.add_child(_b(_t("DECLINE"),func(): _spec_panel.visible=false))

func _build_map_panel() -> void:
	_map_panel=PanelContainer.new()
	_map_panel.set_anchor_and_offset(SIDE_LEFT,0,0); _map_panel.set_anchor_and_offset(SIDE_RIGHT,1,0)
	_map_panel.set_anchor_and_offset(SIDE_TOP,0,50); _map_panel.set_anchor_and_offset(SIDE_BOTTOM,1,-60)
	var sb:=StyleBoxFlat.new(); sb.bg_color=Color(0,0,0,0.0)
	_map_panel.add_theme_stylebox_override("panel",sb)
	_map_panel.visible=false
	_map_panel.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(_map_panel)
	_country_popup=_ovpc(0.34,0.66,0.30,0.72,CB); _country_popup.visible=false; add_child(_country_popup)

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
	v.add_child(_l(_t("REGION_INFO") % [c.get("region",""),c["gdp"],c["pop"]],11,CM))
	v.add_child(_l(_t("PURCHASE_PRICE") % c["price"],13,CO))
	if CountrySystem.is_owned(cid):
		v.add_child(_l(_t("STATUS_OWNED"),12,CG))
		v.add_child(_l(_t("AMB_NOTE"),11,CM))
	else:
		var bb:=_b(_t("PURCHASE_BTN") % c["price"],func(): _on_buy_country(cid))
		if not CountrySystem.can_afford(cid): bb.disabled=true
		v.add_child(bb)
	_country_popup.visible=true

func _on_buy_country(cid: String) -> void:
	if CountrySystem.buy(cid):
		_msg("🌍 Purchased: "+CountrySystem.find_country(cid).get("name",""),CO)
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
	iv.add_child(_l(_t("OFFICE_PROG"),10,CA,true)); _gv(iv,4)
	var dr:=_hb(6)
	for i in 4:
		var d:=ColorRect.new(); d.custom_minimum_size=Vector2(12,12)
		d.color=CA if i<=OfficeSystem.current_level else CM; dr.add_child(d)
	iv.add_child(dr); _gv(iv,4)
	var cur:=OfficeSystem.get_current()
	var oname := LocaleSystem.office_name(OfficeSystem.current_level)
	iv.add_child(_l(oname,11,CT,true)); iv.add_child(_l(cur.get("desc",""),10,CM)); _gv(iv,4)
	if OfficeSystem.can_upgrade():
		var nxt:=OfficeSystem.get_next()
		var nxt_name := LocaleSystem.office_name(OfficeSystem.current_level + 1)
		var ub:=_b(_t("UPGRADE_BTN") % [nxt_name, _fmt(OfficeSystem.get_upgrade_cost())],_on_upgrade)
		ub.add_theme_font_size_override("font_size",11); iv.add_child(ub)
	elif OfficeSystem.current_level<3:
		var nxt:=OfficeSystem.get_next()
		iv.add_child(_l(_t("UNLOCK_AT") % _fmt(nxt.get("unlock",0.0)),10,CM))
	else:
		iv.add_child(_l(_t("MAX_LEVEL"),10,CG))
	return mg

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
	SaveSystem.game_saved.connect(func(): _msg("💾 Saved.",CG))
	SaveSystem.game_loaded.connect(func(): _refresh_all(); _msg("📂 Loaded.",CA))
	SaveSystem.save_failed.connect(func(r): _msg("Error: "+r,CR))
	SpeculatorSystem.speculator_arrived.connect(_on_speculator)
	SpeculatorSystem.tip_resolved.connect(_on_tip_resolved)
	CountrySystem.country_purchased.connect(func(c): _msg("🌍 Purchased: "+c["name"],CO); _refresh_contacts())
	_tick_sel.item_selected.connect(_on_tick_sel)

# ── Event handlers ─────────────────────────────────────────────────────────────
func _on_day(d:String)           -> void: _date_lbl.text=d; _refresh_all()
func _on_cash(v:float)           -> void: _cash_lbl.text="$"+_fmt(v); _update_nw()
func _on_inf(l:int)              -> void: _inf_lbl.text="│  Inf: %d/5"%l
func _on_prices()                -> void: _refresh_tickers(); _chart.queue_redraw()
func _on_news(a:Dictionary)      -> void: _add_news(a)
func _on_fail(r:String)          -> void: _msg(r,CR)
func _on_manip(a:Dictionary)     -> void: _msg("✓  "+a["label"],CO)
func _on_crisis(ev:Dictionary)   -> void: _msg("⚡  CRISIS: "+ev["title"],CO)
func _on_office_up(_l:int)       -> void:
	_refresh_all()
	_msg("⌂ "+LocaleSystem.office_name(OfficeSystem.current_level),CA)

func _on_speculator(offer:Dictionary) -> void:
	_current_offer=offer
	var sp:=_spec_panel
	var path_base:="VBoxContainer/MarginContainer/VBoxContainer/"
	var n := func(nm:String): return sp.get_node_or_null(path_base+nm)
	if n.call("HBoxContainer/portrait"):
		n.call("HBoxContainer/portrait").text = offer.get("portrait","🕵")
		n.call("HBoxContainer/VBoxContainer/sname").text = offer["name"]
		n.call("HBoxContainer/VBoxContainer/stitle").text = offer["title"]
		n.call("sticker").text = "%s  %s" % [offer["action"], offer["ticker"]]
		n.call("sticker").add_theme_color_override("font_color", CG if offer["action"]=="BUY" else CR)
		n.call("sreason").text = offer["reason"]
		n.call("sprice").text  = "Asking: $%s" % _fmt(offer["price"])
	_spec_panel.visible=true

func _on_spec_accept() -> void:
	if _current_offer.is_empty(): _spec_panel.visible=false; return
	if GameState.cash < _current_offer["price"]:
		_msg("Not enough cash.",CR); _spec_panel.visible=false; return
	SpeculatorSystem.accept_tip(_current_offer)
	_msg("Tip purchased: %s %s — resolves in ~1 week." % [_current_offer["action"],_current_offer["ticker"]],CO)
	_spec_panel.visible=false; _current_offer={}

func _on_tip_resolved(tip:Dictionary,correct:bool) -> void:
	if correct: _msg("✓ Tip on %s was CORRECT!" % tip["ticker"],CG)
	else:       _msg("✗ Tip on %s was WRONG." % tip["ticker"],CR)

func _on_tick_sel(idx:int) -> void:
	_sel_ticker=_tick_sel.get_item_text(idx); _chart.set_ticker(_sel_ticker)
	var info:=MarketEngine.get_asset_info(_sel_ticker)
	_sel_lbl.text="%s %s  ·  %s  ·  $%.2f" % [TICON.get(_sel_ticker,"◆"),_sel_ticker,info.get("name",""),MarketEngine.get_price(_sel_ticker)]

func _on_buy()     -> void:
	if Portfolio.buy(_sel_ticker,_qty_in.value): _msg("▲ Bought %.0f × %s" % [_qty_in.value,_sel_ticker],CG)
func _on_sell()    -> void:
	if Portfolio.sell(_sel_ticker,_qty_in.value): _msg("▼ Sold %.0f × %s" % [_qty_in.value,_sel_ticker],CR)
func _on_save()    -> void: SaveSystem.save()
func _on_load()    -> void: SaveSystem.load_game()
func _on_upgrade() -> void: if not OfficeSystem.upgrade(): _msg("Check net worth/cash.",CM)
func _on_pause()   -> void:
	GameState.toggle_pause()
	_pause_btn.text = _t("RESUME") if GameState.paused else _t("PAUSE")

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
	_map_panel.visible=!_map_panel.visible
	_content_columns.visible=!_map_panel.visible
	if not _map_panel.visible:
		_country_popup.visible=false

# ═══════════════════════════════════════════════════════════════════════════════
# REFRESH METHODS
# ═══════════════════════════════════════════════════════════════════════════════
func _refresh_all() -> void:
	_update_nw(); _refresh_tickers(); _refresh_portfolio()
	_off_lbl.text="⌂  "+LocaleSystem.office_name(OfficeSystem.current_level)
	_update_rank()

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
		var il:=Label.new(); il.text=TICON.get(ticker,"◆"); il.add_theme_font_size_override("font_size",11)
		il.add_theme_color_override("font_color",Color.from_string(TCOL.get(ticker,"#888780"),Color.WHITE))
		il.custom_minimum_size=Vector2(16,0); row.add_child(il)
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
	if Portfolio.holdings.is_empty(): _port_list.add_child(_l(_t("NO_POSITIONS"),11,CM)); return
	for t2 in Portfolio.holdings:
		var h=Portfolio.holdings[t2]; var pnl=Portfolio.get_unrealized_pnl(t2)
		var row:=_hb(4)
		var il:=Label.new(); il.text=TICON.get(t2,"◆"); il.add_theme_font_size_override("font_size",11)
		il.add_theme_color_override("font_color",Color.from_string(TCOL.get(t2,"#888780"),Color.WHITE))
		il.custom_minimum_size=Vector2(16,0); row.add_child(il)
		row.add_child(_l("%s"%t2,12,CT)); row.add_child(_l("  ×%.0f"%h["qty"],11,CM))
		row.add_child(_l("  %+.2f"%pnl,12,CG if pnl>=0 else CR,true)); _port_list.add_child(row)

func _refresh_port_detail() -> void:
	if Portfolio.holdings.is_empty(): _port_detail.text="[color=#6e7a99]No open positions.[/color]"; return
	var txt:="[b]  Ticker   Qty       Avg Cost     Cur Price    P&L[/b]\n  ──────────────────────────────────\n"
	var total:=0.0
	for t2 in Portfolio.holdings:
		var h=Portfolio.holdings[t2]; var cur=MarketEngine.get_price(t2)
		var pnl=Portfolio.get_unrealized_pnl(t2); var pct=(cur-h["avg_cost"])/h["avg_cost"]*100.0; total+=pnl
		var col:="[color=#38e085]" if pnl>=0 else "[color=#eb4848]"
		txt+="  [b]%-8s[/b] %-8.0f  $%-11.2f  $%-11.2f  %s%+.2f[/color]  %s%+.1f%%[/color]\n" % [t2,h["qty"],h["avg_cost"],cur,col,pnl,col,pct]
	var tc:="[color=#38e085]" if total>=0 else "[color=#eb4848]"
	txt+="\n  [b]P&L: %s%+.2f[/color]   Cash: $%s   Net: $%s[/b]" % [tc,total,_fmt(GameState.cash),_fmt(GameState.get_net_worth())]
	_port_detail.text=txt

func _refresh_lb() -> void:
	var pr:=WealthLeaderboard.get_player_rank(); var nw_b:=GameState.get_net_worth()/1_000_000_000.0
	var txt:="[b]  #    Name                         Net Worth    Source[/b]\n  ────────────────────────────────────────────\n"
	for e in WealthLeaderboard.get_top_entries(10):
		txt+="  [b]#%-4d[/b] %-30s $%.1fB   %s\n" % [e[0],e[1],e[2],e[3]]
	if pr>10:
		txt+="\n  [color=#888780]  ... (%d entries) ...[/color]\n\n" % (pr-10)
		for e in WealthLeaderboard.get_nearest_entries(7):
			var col:="[color=#FAC775]" if e[0]==pr else ""; var ec:="[/color]" if e[0]==pr else ""
			txt+="  [b]#%-4d[/b] %s%-30s $%.1fB%s\n" % [e[0],col,e[1],e[2],ec]
	txt+="\n  ──────────────────────────────────────────\n"
	if pr<=100: txt+="  [color=#FAC775][b]TOP 100!  Rank #%d  |  $%.3fB[/b][/color]\n" % [pr,nw_b]
	else:
		var nxt:=WealthLeaderboard.BILLIONAIRES[99]
		txt+="  [b]Unranked[/b]  $%.3fB  |  Need $%.3fB more for #100" % [nw_b,nxt[2]-nw_b]
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
		h.add_child(_b(_t("UNLOCK_BTN") % _fmt(ct2["unlock_cost"]),func(): ContactsSystem.unlock_contact(ct2["id"]); _refresh_contacts()))
	v.add_child(_l(ct2["title"],11,CM))
	if ContactsSystem.is_unlocked(ct2["id"]):
		_gv(v,4); v.add_child(_l(ct2.get("bio",""),10,Color(0.48,0.52,0.60))); _gv(v,6)
		for action in ct2["actions"]:
			var ab:=Button.new(); ab.flat=false; ab.add_theme_font_size_override("font_size",12)
			var cd:=ContactsSystem.get_cooldown(action["id"])
			if cd>0: ab.text="⏳ %s [%dd]" % [action["label"],cd]; ab.disabled=true
			else: ab.text="%s  —  $%s" % [action["label"],_fmt(action["cost"])]
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
	v.add_child(_l("🌍  %s — Ambassador" % country["name"],13,CO,true))
	v.add_child(_l("Region: %s" % country.get("region",""),10,CM)); _gv(v,6)
	for action in country.get("amb_actions",[]):
		var ab:=Button.new(); ab.flat=false; ab.add_theme_font_size_override("font_size",12)
		var ckey="amb_"+country["id"]+"_"+action["id"]
		var cd:=ContactsSystem.get_cooldown(ckey)
		if cd>0: ab.text="⏳ %s [%dd]" % [action["label"],cd]; ab.disabled=true
		else: ab.text="%s  —  $%s" % [action["label"],_fmt(action["cost"])]
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

func _sh(t2:String)->Control:
	var mg:=MarginContainer.new()
	mg.add_theme_constant_override("margin_left",10); mg.add_theme_constant_override("margin_top",6); mg.add_theme_constant_override("margin_bottom",2)
	var r:=_hb(6); mg.add_child(r)
	var ln:=ColorRect.new(); ln.color=CA; ln.custom_minimum_size=Vector2(3,14); r.add_child(ln)
	r.add_child(_l(t2,10,CM)); return mg

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
	p.set_anchor_and_offset(SIDE_TOP,0,52); p.set_anchor_and_offset(SIDE_BOTTOM,b,0)
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

func _fmt(n:float)->String:
	if n>=1_000_000_000: return "%.2fB"%(n/1_000_000_000.0)
	elif n>=1_000_000:   return "%.2fM"%(n/1_000_000.0)
	elif n>=1_000:       return "%.1fK"%(n/1_000.0)
	return "%.2f"%n
