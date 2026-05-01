# OfficeBackground.gd — Yeniden Tasarlanmış Ofis Arka Planları
# The Exchange — v2.0
# 4 seviye, her biri ayrı renk paleti, NPC figürler, duvar dekorları, gelişmiş animasyonlar
#
# KURULUM:
#   Bu dosyayı TheExchange/scripts/ klasörüne koy,
#   eski OfficeBackground.gd'nin yerine geçirir.
#   Sahne yapısında herhangi bir değişiklik gerekmez.

extends Panel

const W := 1280.0
const H := 720.0
var _t := 0.0

# Paylaşılan rastgele veri
var _lights := []
var _stars  := []
var _rain   := []

func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rng := RandomNumberGenerator.new()

	# Şehir ışıkları
	rng.seed = 31415
	for i in 240:
		_lights.append({
			"x": rng.randf(), "y": rng.randf_range(0.50, 0.92),
			"w": rng.randf_range(0.003, 0.018), "h": rng.randf_range(0.007, 0.030),
			"r": rng.randf_range(0.4, 1.0), "g": rng.randf_range(0.4, 1.0), "b": rng.randf_range(0.4, 1.0),
			"blink": i % 6 == 0, "phase": rng.randf() * TAU, "spd": rng.randf_range(0.4, 2.8)
		})

	# Yıldızlar
	rng.seed = 27182
	for _i in 120:
		_stars.append({
			"x": rng.randf(), "y": rng.randf_range(0.01, 0.48),
			"r": rng.randf_range(0.4, 1.9), "ph": rng.randf() * TAU, "sp": rng.randf_range(0.2, 1.6)
		})

	# Yağmur damlacıkları
	rng.seed = 65358
	for _i in 60:
		_rain.append({
			"x": rng.randf(), "oy": rng.randf() * H * 1.5,
			"spd": rng.randf_range(50.0, 160.0), "len": rng.randf_range(12.0, 40.0),
			"alpha": rng.randf_range(0.04, 0.14)
		})

	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var lvl := 0
	var os := get_node_or_null("/root/OfficeSystem")
	if os: lvl = os.current_level
	match lvl:
		0: _basement()
		1: _small_office()
		2: _trading_floor()
		3: _penthouse()
		_: _basement()

# ═══════════════════════════════════════════════════════════════════════════════
# SEVİYE 0 — BASEMENT
# Palet: Soğuk yeşil-gri, beton, CRT fosfor
# Atmosfer: Hayatta kalma, karanlık, nemli
# ═══════════════════════════════════════════════════════════════════════════════
func _basement() -> void:
	# Zemin — koyu beton
	_grad_rect(Rect2(0, 0, W, H), Color(0.050, 0.055, 0.044), Color(0.065, 0.070, 0.052))

	# Tavan — açık beton bandı
	draw_rect(Rect2(0, 0, W, H * 0.13), Color(0.075, 0.080, 0.065))

	# Tavan beton doku çizgileri
	var rng := RandomNumberGenerator.new()
	rng.seed = 9901
	for i in 7:
		var yp := H * (0.04 + float(i) * 0.013)
		draw_rect(Rect2(0, yp, W, 2 + rng.randf() * 2), Color(0.040, 0.044, 0.034, 0.8))
		draw_rect(Rect2(0, yp, W, 0.8), Color(0.100, 0.110, 0.080, 0.5))

	# Duvardaki nem lekesi/ıslaklık
	rng.seed = 7712
	for _i in 4:
		var sx := rng.randf_range(0.05, 0.55) * W
		var sy := rng.randf_range(0.15, 0.55) * H
		var leak_pts := PackedVector2Array()
		var cur_x := sx; var cur_y := sy
		for _j in 6:
			cur_y += rng.randf_range(10, 35)
			cur_x += rng.randf_range(-8, 8)
			leak_pts.append(Vector2(cur_x, cur_y))
		if leak_pts.size() > 1:
			draw_polyline(leak_pts, Color(0.10, 0.14, 0.10, 0.25), 2.0)

	# Dikey boru — sol
	draw_rect(Rect2(W * 0.09, 0, 14, H * 0.75), Color(0.100, 0.105, 0.085))
	draw_rect(Rect2(W * 0.09, 0, 3.0, H * 0.75), Color(0.160, 0.165, 0.130))
	# Boru eklemi halkası
	for yj in [H * 0.18, H * 0.42, H * 0.62]:
		draw_rect(Rect2(W * 0.085, yj, 24, 8), Color(0.120, 0.125, 0.100))
		draw_rect(Rect2(W * 0.085, yj, 24, 2), Color(0.180, 0.185, 0.145))

	# Yatay tavan borusu
	draw_rect(Rect2(0, H * 0.092, W * 0.58, 14), Color(0.095, 0.100, 0.080))
	draw_rect(Rect2(0, H * 0.092, W * 0.58, 3.5), Color(0.145, 0.150, 0.115))
	# Boru bağlantı noktaları
	for bx in [W * 0.12, W * 0.28, W * 0.45]:
		draw_circle(Vector2(bx, H * 0.099), 7.5, Color(0.115, 0.120, 0.095))
		draw_circle(Vector2(bx, H * 0.099), 4.0, Color(0.080, 0.085, 0.068))

	# Sol duvar kitaplığı
	draw_rect(Rect2(W * 0.005, H * 0.15, W * 0.075, H * 0.55), Color(0.100, 0.095, 0.075))
	draw_rect(Rect2(W * 0.005, H * 0.15, W * 0.075, 2.5), Color(0.150, 0.140, 0.110))
	# Raf çizgileri
	for si in 3:
		draw_rect(Rect2(W * 0.005, H * (0.28 + float(si) * 0.14), W * 0.075, 2.5), Color(0.130, 0.120, 0.095))
	# Kitaplar
	rng.seed = 3210
	var book_cols := [Color(0.22, 0.08, 0.05), Color(0.05, 0.10, 0.20), Color(0.08, 0.18, 0.06),
		Color(0.18, 0.16, 0.04), Color(0.12, 0.05, 0.18), Color(0.16, 0.12, 0.05)]
	for bi in 14:
		var bw2 := rng.randf_range(8, 13)
		var bh2 := rng.randf_range(20, 34)
		var row2 := bi / 5
		var col2 := bi % 5
		var bx2 := W * 0.008 + float(col2) * 13
		var row_y := [H * 0.275, H * 0.415, H * 0.555][mini(row2, 2)]
		draw_rect(Rect2(bx2, row_y - bh2, bw2, bh2), book_cols[bi % book_cols.size()])
		draw_rect(Rect2(bx2, row_y - bh2, 1.5, bh2), Color(book_cols[bi % book_cols.size()] * 0.6))

	# Küçük, kirli pencere — sağ üst
	_window_basement(W * 0.66, H * 0.12, W * 0.19, H * 0.145)

	# Zemin
	draw_rect(Rect2(0, H * 0.73, W, H - H * 0.73), Color(0.048, 0.050, 0.040))
	draw_rect(Rect2(0, H * 0.73, W, 3.0), Color(0.100, 0.105, 0.082))
	# Zemin çatlağı
	rng.seed = 5544
	var crack := PackedVector2Array([Vector2(W * 0.3, H * 0.73)])
	for _ci in 5:
		crack.append(crack[-1] + Vector2(rng.randf_range(-20, 30), rng.randf_range(2, 12)))
	draw_polyline(crack, Color(0.035, 0.036, 0.029, 0.6), 1.0)

	# Eski ahşap masa
	draw_rect(Rect2(W * 0.20, H * 0.60, W * 0.58, H * 0.135), Color(0.115, 0.090, 0.058))
	draw_rect(Rect2(W * 0.20, H * 0.60, W * 0.58, 3.0), Color(0.175, 0.140, 0.090))
	# Masa ahşap doku
	rng.seed = 6677
	for _wi in 5:
		draw_rect(Rect2(rng.randf_range(W * 0.21, W * 0.72), H * 0.60,
			rng.randf_range(40, 150), 1.0), Color(0.090, 0.070, 0.045, 0.35))
	# Masa ayakları
	for lx2 in [W * 0.22, W * 0.74]:
		draw_rect(Rect2(lx2, H * 0.73, 10, H * 0.065), Color(0.080, 0.062, 0.040))

	# Eski CRT monitör
	_crt_monitor(W * 0.38, H * 0.26, W * 0.18, H * 0.28)

	# Sallanan çıplak ampul
	_bare_bulb(W * 0.30, H * 0.04)

	# Damlayan su animasyonu
	rng.seed = 8833
	for _di in 3:
		var dx := rng.randf_range(W * 0.35, W * 0.70)
		var dphase := rng.randf() * TAU
		var dy := H * 0.13 + fmod(_t * 32.0 + dphase * 20.0, H * 0.56)
		var dalpha := absf(sin(_t * 0.9 + dphase)) * 0.55
		draw_circle(Vector2(dx, dy), 2.2, Color(0.28, 0.40, 0.28, dalpha))

	# Masa üstü objeler
	_papers(W * 0.23, H * 0.717, Color(0.88, 0.84, 0.74), 4)
	_mug(W * 0.60, H * 0.717, Color(0.22, 0.16, 0.10), Color(0.65, 0.55, 0.35))
	_ashtray(W * 0.50, H * 0.722)
	_phone(W * 0.70, H * 0.717, Color(0.35, 0.06, 0.06))

	# Gazete
	_newspaper_on_desk(W * 0.34, H * 0.700)

	# NPC — eğilmiş figür
	_npc_hunched(W * 0.46, H * 0.717)

	_scanlines(0.022)
	_vignette(0.55)

# ═══════════════════════════════════════════════════════════════════════════════
# SEVİYE 1 — SMALL OFFICE
# Palet: Sıcak amber, ahşap, gece şehir ışığı
# Atmosfer: İlk adım, umut, skromlu yükseliş
# ═══════════════════════════════════════════════════════════════════════════════
func _small_office() -> void:
	# Zemin — sıcak koyu duvar
	_grad_rect(Rect2(0, 0, W, H), Color(0.110, 0.092, 0.058), Color(0.076, 0.060, 0.035))

	# Ahşap lambri — alt yarı
	draw_rect(Rect2(0, H * 0.64, W, H * 0.36), Color(0.095, 0.072, 0.040))
	draw_rect(Rect2(0, H * 0.64, W, 3.5), Color(0.175, 0.135, 0.080))
	# Lambri doku çizgileri
	var rng := RandomNumberGenerator.new()
	rng.seed = 4561
	for wi in 14:
		draw_rect(Rect2(0, H * 0.645 + float(wi) * 13, W, 1.2),
			Color(0.072, 0.055, 0.030, 0.4 + rng.randf() * 0.3))

	# Büyük pencere — sağ taraf, gece manzarası
	_window_large(W * 0.44, H * 0.06, W * 0.34, H * 0.59, 1)

	# Sağ duvar kitaplığı
	draw_rect(Rect2(W * 0.845, H * 0.08, W * 0.148, H * 0.53), Color(0.100, 0.075, 0.040))
	draw_rect(Rect2(W * 0.845, H * 0.08, W * 0.148, 2.5), Color(0.155, 0.115, 0.065))
	# Kitaplık rafları
	for rsi in 3:
		draw_rect(Rect2(W * 0.845, H * (0.21 + float(rsi) * 0.14), W * 0.148, 3.0),
			Color(0.130, 0.098, 0.055))
	# Renkli kitaplar
	rng.seed = 6541
	var bcols2 := [Color(0.50, 0.08, 0.08), Color(0.06, 0.18, 0.40), Color(0.10, 0.35, 0.08),
		Color(0.35, 0.22, 0.05), Color(0.20, 0.08, 0.35), Color(0.35, 0.32, 0.05), Color(0.05, 0.28, 0.28)]
	for bi2 in 21:
		var bw3 := rng.randf_range(9, 14)
		var bh3 := rng.randf_range(20, 32)
		var row3 := bi2 / 7
		var col3 := bi2 % 7
		var bx3 := W * 0.848 + float(col3) * (W * 0.148 / 7.2)
		var rowy := [H * 0.205, H * 0.345, H * 0.485][mini(row3, 2)]
		draw_rect(Rect2(bx3, rowy - bh3, bw3, bh3), bcols2[bi2 % bcols2.size()])
		draw_rect(Rect2(bx3, rowy - bh3, 1.5, bh3), bcols2[bi2 % bcols2.size()] * 0.55)
		draw_rect(Rect2(bx3 + bw3 - 1, rowy - bh3, 1, bh3), Color(1, 1, 1, 0.06))

	# Sol duvar — çerçeveli şehir fotoğrafı
	_wall_photo(W * 0.07, H * 0.13, 130, 95)

	# Sol duvar — hisse senedi sertifikası
	_wall_certificate(W * 0.07, H * 0.38, 130, 88)

	# Zemin — ahşap parke görünümü
	draw_rect(Rect2(0, H * 0.73, W, H - H * 0.73), Color(0.088, 0.065, 0.038))
	draw_rect(Rect2(0, H * 0.73, W, 3.5), Color(0.155, 0.118, 0.068))
	# Parke çizgileri
	rng.seed = 3344
	for pi in 6:
		draw_rect(Rect2(rng.randf_range(0, W), H * 0.73, 1.0, H * 0.27),
			Color(0.068, 0.050, 0.028, 0.35))

	# Ahşap masa
	draw_rect(Rect2(W * 0.04, H * 0.60, W * 0.57, H * 0.135), Color(0.175, 0.128, 0.072))
	draw_rect(Rect2(W * 0.04, H * 0.60, W * 0.57, 3.5), Color(0.260, 0.195, 0.112))
	# Masa çekmece çizgisi
	draw_rect(Rect2(W * 0.04, H * 0.666, W * 0.57, 2.0), Color(0.135, 0.098, 0.055))
	draw_rect(Rect2(W * 0.27, H * 0.602, 2.0, H * 0.130), Color(0.135, 0.098, 0.055))

	# İki monitör
	_monitor(W * 0.09, H * 0.20, W * 0.22, H * 0.38, 0)
	_monitor(W * 0.34, H * 0.17, W * 0.20, H * 0.41, 1)

	# Masa lambası — sıcak amber
	_desk_lamp(W * 0.70, H * 0.60, Color(0.80, 0.52, 0.10))

	# Kupa (ödül)
	_trophy(W * 0.73, H * 0.717)

	# Masa üstü objeler
	_mug(W * 0.75, H * 0.717, Color(0.08, 0.12, 0.22), Color(0.50, 0.72, 0.88))
	_papers(W * 0.07, H * 0.717, Color(0.92, 0.88, 0.76), 3)
	_phone(W * 0.21, H * 0.717, Color(0.35, 0.06, 0.06))
	_notepad(W * 0.40, H * 0.720)

	# NPC — ayakta, güvenli duruş
	_npc_standing(W * 0.47, H * 0.717)

	_scanlines(0.015)
	_vignette(0.45)

# ═══════════════════════════════════════════════════════════════════════════════
# SEVİYE 2 — TRADING FLOOR
# Palet: Soğuk mavi-çelik, kurumsal, gece (iddia ve güç)
# Atmosfer: Yoğun, profesyonel, çok ekranlı
# ═══════════════════════════════════════════════════════════════════════════════
func _trading_floor() -> void:
	# Zemin — koyu kurumsal
	_grad_rect(Rect2(0, 0, W, H), Color(0.038, 0.042, 0.062), Color(0.024, 0.028, 0.044))

	# Asma tavan karoları
	draw_rect(Rect2(0, 0, W, H * 0.09), Color(0.046, 0.050, 0.070))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1112
	for ci in 24:
		draw_rect(Rect2(float(ci) * W / 24.0, 0, 1.0, H * 0.09),
			Color(0.030, 0.034, 0.050, 0.5 + rng.randf() * 0.3))

	# LED tavan şeritleri — mavi
	for li in 5:
		var lx2 := W * (0.10 + float(li) * 0.19)
		draw_rect(Rect2(lx2 - 44, H * 0.087, 88, 3.5), Color(0.55, 0.72, 1.0, 0.90))
		# Işık konisi
		var cone := PackedVector2Array([
			Vector2(lx2 - 44, H * 0.091),
			Vector2(lx2 + 44, H * 0.091),
			Vector2(lx2 + 90, H * 0.30),
			Vector2(lx2 - 90, H * 0.30)
		])
		draw_colored_polygon(cone, Color(0.50, 0.68, 1.0, 0.040))

	# Geniş panoramik pencere
	_window_large(W * 0.24, H * 0.04, W * 0.72, H * 0.58, 2)

	# Pencere dikmesi — ince çelik
	for mi in 4:
		draw_rect(Rect2(W * 0.24 + float(mi + 1) * (W * 0.72 / 5.0), H * 0.04, 4.5, H * 0.58),
			Color(0.040, 0.045, 0.065))
	draw_rect(Rect2(W * 0.24, H * 0.04 + H * 0.58 * 0.50, W * 0.72, 4.5),
		Color(0.040, 0.045, 0.065))

	# Zemin — parlak siyah beton
	draw_rect(Rect2(0, H * 0.72, W, H - H * 0.72), Color(0.030, 0.034, 0.050))
	draw_rect(Rect2(0, H * 0.72, W, 3.5), Color(0.080, 0.092, 0.130))
	# Zemin ızgara çizgileri
	for fi in 10:
		draw_rect(Rect2(float(fi) * W / 10.0, H * 0.72, 1.5, H * 0.28),
			Color(0.050, 0.055, 0.078, 0.50))

	# L-şekilli trading masası
	draw_rect(Rect2(W * 0.02, H * 0.60, W * 0.80, H * 0.12), Color(0.048, 0.054, 0.075))
	draw_rect(Rect2(W * 0.02, H * 0.60, W * 0.80, 3.5), Color(0.100, 0.120, 0.180))
	draw_rect(Rect2(W * 0.70, H * 0.60, W * 0.12, H * 0.195), Color(0.040, 0.046, 0.064))
	draw_rect(Rect2(W * 0.70, H * 0.60, W * 0.12, 3.5), Color(0.085, 0.102, 0.155))

	# 4 monitör
	_monitor(W * 0.03, H * 0.20, W * 0.19, H * 0.36, 0)
	_monitor(W * 0.24, H * 0.16, W * 0.19, H * 0.40, 1)
	_monitor(W * 0.45, H * 0.20, W * 0.18, H * 0.36, 2)
	_monitor(W * 0.65, H * 0.23, W * 0.15, H * 0.32, 3)

	# Duvar ekranı — Bloomberg tarzı board
	_bloomberg_board(W * 0.02, H * 0.10, W * 0.20, H * 0.09)

	# Klavye
	draw_rect(Rect2(W * 0.12, H * 0.680, W * 0.22, H * 0.030), Color(0.038, 0.042, 0.060))
	for ki in 18:
		draw_rect(Rect2(W * 0.124 + float(ki) * (W * 0.011), H * 0.683, W * 0.009, H * 0.021),
			Color(0.068, 0.075, 0.105))

	# Ticker bant simülasyonu
	_ticker_tape(W * 0.02, H * 0.621, W * 0.45, H * 0.020)

	# Masa üstü objeler
	_mug(W * 0.86, H * 0.717, Color(0.04, 0.06, 0.12), Color(0.22, 0.48, 0.78))
	_phone(W * 0.22, H * 0.717, Color(0.35, 0.06, 0.06))
	_notepad(W * 0.38, H * 0.722)

	# NPC — oturan iki figür (meslektaşlar)
	_npc_sitting(W * 0.54, H * 0.68, Color(0.06, 0.08, 0.18))
	_npc_sitting(W * 0.72, H * 0.68, Color(0.04, 0.06, 0.14))

	_scanlines(0.012)
	_vignette(0.42)

# ═══════════════════════════════════════════════════════════════════════════════
# SEVİYE 3 — PENTHOUSE
# Palet: Derin lacivert, altın aksan, mermer
# Atmosfer: Zafer, güç, şehir ayaklarının altında
# ═══════════════════════════════════════════════════════════════════════════════
func _penthouse() -> void:
	# Zemin — neredeyse siyah, sıcak alt ton
	_grad_rect(Rect2(0, 0, W, H), Color(0.032, 0.028, 0.038), Color(0.020, 0.018, 0.028))

	# Tavan — gömülü aydınlatma
	draw_rect(Rect2(0, 0, W, H * 0.08), Color(0.042, 0.038, 0.052))
	# Gömülü spot ışıklar
	for li in 6:
		var lx2 := W * (0.07 + float(li) * 0.165)
		var light_g := PackedVector2Array([
			Vector2(lx2 - 80, H * 0.08),
			Vector2(lx2 + 80, H * 0.08),
			Vector2(lx2 + 110, H * 0.28),
			Vector2(lx2 - 110, H * 0.28)
		])
		draw_colored_polygon(light_g, Color(0.86, 0.72, 0.38, 0.045))
		draw_circle(Vector2(lx2, H * 0.076), 6.5, Color(1.0, 0.90, 0.62, 0.92))
		draw_circle(Vector2(lx2, H * 0.076), 12.0, Color(1.0, 0.90, 0.62, 0.20))

	# Tavan-tabandan-cama panoramik pencere
	_window_large(W * 0.02, H * 0.08, W * 0.96, H * 0.62, 3)

	# Pencere dikmesi — minimal ince çelik
	for mi in 5:
		draw_rect(Rect2(W * 0.02 + float(mi + 1) * (W * 0.96 / 6.0), H * 0.08, 3.5, H * 0.62),
			Color(0.038, 0.034, 0.048))
	draw_rect(Rect2(W * 0.02, H * 0.08 + H * 0.62 * 0.50, W * 0.96, 3.5),
		Color(0.038, 0.034, 0.048))
	# Pencere altın aksanı
	draw_rect(Rect2(W * 0.02 - 2, H * 0.08, 2, H * 0.62), Color(0.70, 0.55, 0.18, 0.35))
	draw_rect(Rect2(W * 0.98, H * 0.08, 2, H * 0.62), Color(0.70, 0.55, 0.18, 0.35))

	# Mermer zemin
	draw_rect(Rect2(0, H * 0.72, W, H - H * 0.72), Color(0.060, 0.054, 0.070))
	draw_rect(Rect2(0, H * 0.72, W, 3.5), Color(0.090, 0.082, 0.110))
	# Mermer damarları
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	for _vi in 8:
		var vx1 := rng.randf() * W; var vy1 := H * 0.72
		var vx2 := vx1 + rng.randf_range(-80, 80)
		var vcp1x := rng.randf() * W; var vcp1y := H * 0.80
		var vcp2x := rng.randf() * W; var vcp2y := H * 0.90
		var vpts := PackedVector2Array()
		for vi2 in 16:
			var vf := float(vi2) / 15.0
			var vx := _cubic(vx1, vcp1x, vcp2x, vx2, vf)
			var vy := _cubic(vy1, vcp1y, vcp2y, H, vf)
			vpts.append(Vector2(vx, vy))
		draw_polyline(vpts, Color(0.75, 0.68, 0.90, 0.08 + rng.randf() * 0.06),
			0.8 + rng.randf() * 1.5)

	# Kavisli executive masa
	_penthouse_desk()

	# Kupa dolabı — sol duvar
	_trophy_cabinet(W * 0.005, H * 0.08, W * 0.065, H * 0.52)

	# Duvar sanatı — sağ üst
	_wall_art_abstract(W * 0.82, H * 0.10, 150, 110)

	# 4 monitör — daha küçük, manzara görünür
	var mpos := [
		[W * 0.05, H * 0.24, W * 0.14, H * 0.30],
		[W * 0.27, H * 0.20, W * 0.15, H * 0.34],
		[W * 0.49, H * 0.20, W * 0.15, H * 0.34],
		[W * 0.72, H * 0.24, W * 0.14, H * 0.30],
	]
	for mi2 in mpos.size():
		_monitor(mpos[mi2][0], mpos[mi2][1], mpos[mi2][2], mpos[mi2][3], mi2)

	# Masa üstü objeler
	_whisky(W * 0.88, H * 0.702)
	_phone(W * 0.28, H * 0.707, Color(0.50, 0.40, 0.06))
	_ashtray(W * 0.76, H * 0.720)
	_cigar(W * 0.762, H * 0.714)

	# Kupa
	_trophy(W * 0.92, H * 0.717)
	_trophy(W * 0.95, H * 0.717)

	# NPC — iki executive figür
	_npc_executive(W * 0.52, H * 0.720)
	_npc_advisor(W * 0.63, H * 0.720)

	_scanlines(0.008)
	_vignette(0.38)

# ═══════════════════════════════════════════════════════════════════════════════
# PENCERE ÇİZİCİLERİ
# ═══════════════════════════════════════════════════════════════════════════════

func _window_basement(wx: float, wy: float, ww: float, wh: float) -> void:
	# Gece gökyüzü
	draw_rect(Rect2(wx, wy, ww, wh), Color(0.016, 0.020, 0.030))
	# Yıldızlar
	for s in _stars:
		var br := 0.2 + 0.5 * absf(sin(_t * s["sp"] + s["ph"]))
		draw_circle(Vector2(wx + s["x"] * ww, wy + s["y"] * wh * 0.65), s["r"] * 0.7,
			Color(0.82, 0.86, 0.90, br * 0.55))
	# Sokak ışığı parıltısı — pencere altı
	var street := PackedVector2Array([
		Vector2(wx, wy + wh),
		Vector2(wx + ww, wy + wh),
		Vector2(wx + ww, wy + wh * 0.72),
		Vector2(wx, wy + wh * 0.72)
	])
	draw_colored_polygon(street, Color(0.28, 0.42, 0.22, 0.18))
	# Parmaklik
	for gi in 5:
		draw_rect(Rect2(wx + float(gi) * (ww / 5.0), wy, 3.0, wh), Color(0.040, 0.045, 0.036, 0.92))
	draw_rect(Rect2(wx, wy + wh * 0.50, ww, 3.0), Color(0.040, 0.045, 0.036, 0.92))
	# Çerçeve
	for side in [[wx - 8, wy - 8, ww + 16, 8], [wx - 8, wy + wh, ww + 16, 8],
		[wx - 8, wy - 8, 8, wh + 16], [wx + ww, wy - 8, 8, wh + 16]]:
		draw_rect(Rect2(side[0], side[1], side[2], side[3]), Color(0.075, 0.070, 0.058))
	# Yağmur
	for r in _rain:
		var ry := fmod(r["oy"] + _t * r["spd"], wh * 1.2) + wy - wh * 0.1
		if ry >= wy and ry <= wy + wh:
			draw_line(Vector2(wx + r["x"] * ww, ry),
				Vector2(wx + r["x"] * ww + 1.5, ry + r["len"] * 0.7),
				Color(0.45, 0.62, 0.80, r["alpha"] * 0.6), 1.0)

func _window_large(wx: float, wy: float, ww: float, wh: float, level: int) -> void:
	# Gökyüzü gradyanı
	var sky_top := [
		Color(0.030, 0.040, 0.060), # basement/small
		Color(0.016, 0.022, 0.042), # small office
		Color(0.010, 0.015, 0.030), # trading floor
		Color(0.010, 0.008, 0.016)  # penthouse
	][mini(level, 3)]
	var sky_bot := [
		Color(0.042, 0.035, 0.022),
		Color(0.030, 0.025, 0.018),
		Color(0.022, 0.030, 0.050),
		Color(0.060, 0.025, 0.018)
	][mini(level, 3)]
	_grad_rect(Rect2(wx, wy, ww, wh), sky_top, sky_bot)

	# Yıldızlar
	for s in _stars:
		var br := 0.25 + 0.55 * absf(sin(_t * s["sp"] + s["ph"]))
		draw_circle(Vector2(wx + s["x"] * ww, wy + s["y"] * wh * 0.48), s["r"],
			Color(0.88, 0.90, 1.00, br * 0.68))

	# Ay
	var mr := 20.0 + float(level) * 2.5
	var mx2 := wx + ww * 0.83; var my2 := wy + wh * 0.16
	draw_circle(Vector2(mx2, my2), mr + 7, Color(0.92, 0.88, 0.72, 0.12))
	draw_circle(Vector2(mx2, my2), mr, Color(0.94, 0.92, 0.80, 0.88))
	draw_circle(Vector2(mx2 + 9, my2 - 5), mr - 4, Color(sky_top.r, sky_top.g, sky_top.b, 0.92))

	# Şehir silüeti
	_city_silhouette(wx, wy, ww, wh, level)

	# Şehir ışıkları
	for l in _lights:
		var lx2 := wx + l["x"] * ww
		var ly2 := l["y"] * H
		if lx2 < wx or lx2 > wx + ww or ly2 < wy + wh * 0.48 or ly2 > wy + wh:
			continue
		var a2 := 0.85
		if l["blink"]:
			a2 = 0.35 + 0.65 * absf(sin(_t * l["spd"] + l["phase"]))
		draw_rect(Rect2(lx2, ly2, l["w"] * ww, l["h"] * wh * 0.46),
			Color(l["r"], l["g"], l["b"], a2 * 0.82))

	# Yağmur
	for r in _rain:
		var ry2 := fmod(r["oy"] + _t * r["spd"], wh * 1.3) + wy - wh * 0.1
		if ry2 >= wy and ry2 <= wy + wh:
			draw_line(Vector2(wx + r["x"] * ww, ry2),
				Vector2(wx + r["x"] * ww + 2.0, ry2 + r["len"]),
				Color(0.55, 0.72, 0.95, r["alpha"]), 1.0)

	# Çerçeve
	var fw := 5.0 if level < 3 else 3.0
	var fc := Color(0.040, 0.044, 0.062)
	if level == 1: fc = Color(0.090, 0.068, 0.038)
	draw_rect(Rect2(wx - fw, wy - fw, ww + fw * 2, fw), fc)
	draw_rect(Rect2(wx - fw, wy + wh, ww + fw * 2, fw), fc)
	draw_rect(Rect2(wx - fw, wy - fw, fw, wh + fw * 2), fc)
	draw_rect(Rect2(wx + ww, wy - fw, fw, wh + fw * 2), fc)

	# Pencere yansıması / iç ışık
	draw_line(Vector2(wx + 14, wy + 8), Vector2(wx + ww * 0.20, wy + wh * 0.26),
		Color(1.0, 1.0, 1.0, 0.04), 18.0)

# ═══════════════════════════════════════════════════════════════════════════════
# PAYLAŞILAN ÇİZİM YARDIMCILARI
# ═══════════════════════════════════════════════════════════════════════════════

func _city_silhouette(wx: float, wy: float, ww: float, wh: float, d: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77665 + d * 100
	var sil := PackedVector2Array()
	sil.append(Vector2(wx, wy + wh))
	sil.append(Vector2(wx, wy + wh * 0.60))
	var cx2 := wx
	while cx2 < wx + ww + 60:
		var bw2 := rng.randf_range(18 + d * 5, 55 + d * 12)
		var bh2 := rng.randf_range(wh * 0.06, wh * (0.25 + d * 0.05))
		var by2 := wy + wh - bh2
		sil.append(Vector2(cx2, by2))
		sil.append(Vector2(cx2 + bw2 * 0.3, by2 - rng.randf_range(0, bh2 * 0.18)))
		sil.append(Vector2(cx2 + bw2, by2))
		cx2 += bw2
	sil.append(Vector2(wx + ww, wy + wh * 0.60))
	sil.append(Vector2(wx + ww, wy + wh))
	var sil_col := [
		Color(0.032, 0.038, 0.030),
		Color(0.042, 0.032, 0.020),
		Color(0.018, 0.022, 0.036),
		Color(0.018, 0.015, 0.022)
	][mini(d, 3)]
	draw_colored_polygon(sil, sil_col)

func _crt_monitor(mx: float, my: float, mw: float, mh: float) -> void:
	# Monitör gövdesi — bej plastik
	draw_rect(Rect2(mx - 14, my - 10, mw + 28, mh + 32), Color(0.185, 0.175, 0.150))
	draw_rect(Rect2(mx - 8, my - 5, mw + 16, mh + 20), Color(0.140, 0.130, 0.112))
	# Ekran — yeşil fosfor
	draw_rect(Rect2(mx, my, mw, mh), Color(0.014, 0.055, 0.022))
	# CRT tarama çizgileri
	for si in 10:
		draw_rect(Rect2(mx, my + mh * float(si) / 10.0, mw, mh / 20.0),
			Color(0.035, 0.140, 0.055, 0.08))
	# İçerik — yeşil metin satırları
	var rng := RandomNumberGenerator.new()
	rng.seed = 44556
	for ci in 8:
		var alpha2 := 0.28 + 0.42 * absf(sin(_t * 0.4 + float(ci) * 0.55))
		draw_rect(Rect2(mx + 7, my + mh * (0.10 + float(ci) * 0.11),
			mw * rng.randf_range(0.15, 0.72), 2.5),
			Color(0.14, 0.82, 0.30, alpha2))
	# İmleç yanıp sönmesi
	var cursor_alpha := 0.5 + 0.5 * round(fmod(_t * 1.2, 1.0))
	draw_rect(Rect2(mx + 8, my + mh * 0.88, 8, 3), Color(0.14, 0.82, 0.30, cursor_alpha))
	# CRT kıvrım maskesi
	draw_arc(Vector2(mx + mw / 2, my + mh / 2), mw * 0.54, 0, TAU, 32,
		Color(0, 0, 0, 0.20), 6.0)
	# Taban
	draw_rect(Rect2(mx + mw * 0.34, my + mh + 10, mw * 0.32, 12), Color(0.165, 0.155, 0.135))

func _monitor(mx: float, my: float, mw: float, mh: float, idx: int) -> void:
	# Stand
	draw_rect(Rect2(mx + mw * 0.44, my + mh, mw * 0.12, H * 0.020), Color(0.055, 0.055, 0.075))
	draw_rect(Rect2(mx + mw * 0.32, my + mh + H * 0.020, mw * 0.36, H * 0.009),
		Color(0.042, 0.042, 0.060))
	# Çerçeve
	draw_rect(Rect2(mx - 7, my - 7, mw + 14, mh + 14), Color(0.048, 0.050, 0.070))
	draw_rect(Rect2(mx - 4, my - 4, mw + 8, mh + 8), Color(0.035, 0.038, 0.055))
	# Ekran rengi (indekse göre)
	var screen_cols := [
		Color(0.022, 0.065, 0.145),
		Color(0.018, 0.070, 0.048),
		Color(0.062, 0.025, 0.105),
		Color(0.028, 0.052, 0.118),
		Color(0.018, 0.062, 0.038),
		Color(0.048, 0.032, 0.085)
	]
	var sc2 := screen_cols[idx % screen_cols.size()]
	draw_rect(Rect2(mx, my, mw, mh), sc2)
	# Ekran kenarlık parlaması
	draw_rect(Rect2(mx - 2, my - 2, mw + 4, mh + 4), Color(sc2.r, sc2.g, sc2.b, 0.18))

	# Grafik çizgisi — animasyonlu
	var line_col := Color(0.22, 0.90, 0.52, 0.75) if idx % 2 == 0 else Color(0.92, 0.28, 0.28, 0.75)
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9900 + idx * 77
	for i in 22:
		pts.append(Vector2(
			mx + mw * (0.04 + float(i) / 21.0 * 0.92),
			my + mh * (0.38 + rng.randf_range(-0.16, 0.16) + 0.04 * sin(_t * 0.28 + float(idx) + float(i) * 0.42))
		))
	if pts.size() > 1:
		draw_polyline(pts, line_col, 1.8, true)

	# Grafik dolgusu
	var fill_pts := PackedVector2Array()
	fill_pts.append(Vector2(pts[0].x, my + mh * 0.88))
	for p2 in pts: fill_pts.append(p2)
	fill_pts.append(Vector2(pts[-1].x, my + mh * 0.88))
	draw_colored_polygon(fill_pts, Color(line_col.r, line_col.g, line_col.b, 0.06))

	# Durum çubukları
	var brng2 := RandomNumberGenerator.new()
	brng2.seed = 1234 + idx * 33
	for bi3 in 4:
		draw_rect(Rect2(mx + mw * 0.04, my + mh * (0.64 + float(bi3) * 0.08),
			mw * brng2.randf_range(0.15, 0.75), 2.5),
			Color(line_col.r, line_col.g, line_col.b, 0.14))

	# Güç LED'i
	var led_pulse := 0.55 + 0.45 * sin(_t * 1.8 + float(idx) * 1.4)
	draw_circle(Vector2(mx + mw - 8, my + mh - 7), 2.8,
		Color(line_col.r, line_col.g, line_col.b, led_pulse))

func _desk_lamp(lx: float, by2: float, col: Color) -> void:
	var ly := by2 - H * 0.21
	# Taban
	draw_rect(Rect2(lx - 22, by2 - 5, 44, 7), Color(0.105, 0.088, 0.055))
	# Direk
	draw_rect(Rect2(lx - 2.5, by2 - 5, 5, -(by2 - ly - 46)), Color(0.130, 0.108, 0.068))
	# Kol
	draw_line(Vector2(lx, ly + 46), Vector2(lx - 24, ly), Color(0.130, 0.108, 0.068), 5.0)
	# Şapka
	draw_colored_polygon(PackedVector2Array([
		Vector2(lx - 34, ly), Vector2(lx + 16, ly),
		Vector2(lx + 10, ly + 24), Vector2(lx - 28, ly + 24)
	]), col * Color(0.18, 0.18, 0.18))
	# Ampul
	draw_circle(Vector2(lx - 10, ly + 12), 7.0, Color(1.0, 0.95, 0.72, 0.95))
	draw_circle(Vector2(lx - 10, ly + 12), 14.0, Color(1.0, 0.92, 0.60, 0.18))
	# Işık konisi
	var cone2 := PackedVector2Array([
		Vector2(lx - 28, ly + 24), Vector2(lx + 10, ly + 24),
		Vector2(lx + 70, by2 - 5), Vector2(lx - 88, by2 - 5)
	])
	draw_colored_polygon(cone2, Color(1.0, 0.92, 0.60, 0.038))

func _bare_bulb(bx: float, by2: float) -> void:
	# Tel
	draw_line(Vector2(bx, 0), Vector2(bx, by2), Color(0.10, 0.10, 0.08), 2.0)
	# Titreme efekti
	var flicker := 0.82 + 0.18 * absf(sin(_t * 2.2 + sin(_t * 8.7) * 0.4))
	# Ampul camı
	draw_circle(Vector2(bx, by2), 9.0, Color(0.88, 0.82, 0.58, flicker * 0.85))
	draw_circle(Vector2(bx, by2), 6.0, Color(1.0, 0.97, 0.78, flicker))
	# Işık halesi
	draw_circle(Vector2(bx, by2), 18.0, Color(0.92, 0.85, 0.58, flicker * 0.12))
	# Işık konisi — aşağı
	var cone3 := PackedVector2Array([
		Vector2(bx - 10, by2 + 10), Vector2(bx + 10, by2 + 10),
		Vector2(bx + 160, H * 0.73), Vector2(bx - 160, H * 0.73)
	])
	draw_colored_polygon(cone3, Color(0.92, 0.85, 0.58, flicker * 0.032))

func _bloomberg_board(bx: float, by2: float, bw: float, bh: float) -> void:
	draw_rect(Rect2(bx, by2, bw, bh), Color(0.022, 0.026, 0.040))
	draw_rect(Rect2(bx, by2, bw, 2.5), Color(0.055, 0.068, 0.105))
	# Grid hücreler
	var rng := RandomNumberGenerator.new()
	rng.seed = 5588
	for ri in 3:
		for ci2 in 4:
			var is_up := rng.randf() > 0.45
			var cell_col := Color(0.06, 0.48, 0.14, 0.55) if is_up else Color(0.55, 0.10, 0.10, 0.55)
			var cx3 := bx + 3 + float(ci2) * (bw / 4.0 - 1)
			var cy3 := by2 + 4 + float(ri) * (bh / 3.0 - 1)
			draw_rect(Rect2(cx3, cy3, bw / 4.0 - 3, bh / 3.0 - 3), cell_col)

func _ticker_tape(tx: float, ty: float, tw: float, th: float) -> void:
	draw_rect(Rect2(tx, ty, tw, th), Color(0.028, 0.032, 0.050))
	# Animasyonlu metin simülasyonu (renkli bloklar)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3399
	for ti in 10:
		var tick_x := tx + fmod(float(ti) * 110.0 + _t * 25.0, tw * 1.4) - 20
		if tick_x > tx and tick_x < tx + tw:
			var is_up2 := ti % 3 != 0
			draw_rect(Rect2(tick_x, ty + 3, 85, th - 6),
				Color(0.06, 0.28, 0.10, 0.40) if is_up2 else Color(0.28, 0.06, 0.06, 0.40))

func _papers(px: float, py: float, col: Color, count: int) -> void:
	for i in count:
		var angle := (float(i) - 1.0) * 0.025
		var off_x := float(i) * 2.5
		var off_y := float(i) * -2.0
		draw_rect(Rect2(px + off_x, py + off_y - 22, 115, 24), Color(col.r, col.g, col.b, 0.70 - float(i) * 0.05))
		# Satırlar
		var rng := RandomNumberGenerator.new()
		rng.seed = 8899 + i * 3
		for li in 4:
			draw_rect(Rect2(px + off_x + 8, py + off_y - 18 + float(li) * 5,
				rng.randf_range(35, 90), 1.5), Color(0.30, 0.25, 0.20, 0.22))

func _mug(cx: float, by2: float, body_col: Color, accent_col: Color) -> void:
	var mh2 := 32.0; var mw2 := 28.0; var cy2 := by2 - mh2
	# Gövde
	draw_rect(Rect2(cx - mw2 / 2, cy2, mw2, mh2), body_col)
	draw_rect(Rect2(cx - mw2 / 2 - 1, cy2, mw2 + 2, 4), accent_col)
	# Kulp
	draw_arc(Vector2(cx + mw2 / 2, cy2 + mh2 * 0.48), mh2 * 0.38, -PI * 0.42, PI * 0.42, 14,
		body_col * Color(0.8, 0.8, 0.8), 3.5)
	# Buhar
	for si in 2:
		for sj in 5:
			var ph2 := _t * 1.1 + float(si) * 0.9 + float(sj) * 0.35
			draw_line(
				Vector2(cx - 5.0 + float(si) * 6.0 + sin(ph2) * 3.5, cy2 - 5 - float(sj) * 5),
				Vector2(cx - 5.0 + float(si) * 6.0 + sin(ph2 + 0.4) * 3.5, cy2 - 5 - float(sj + 1) * 5),
				Color(0.80, 0.80, 0.88, maxf(0.0, 0.065 - float(sj) * 0.012)), 1.5
			)

func _phone(cx: float, by2: float, body_col: Color) -> void:
	var bw3 := 44.0; var bh3 := 18.0; var cy3 := by2 - bh3
	# Gövde
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - bw3 * 0.50, by2), Vector2(cx + bw3 * 0.50, by2),
		Vector2(cx + bw3 * 0.44, cy3), Vector2(cx - bw3 * 0.44, cy3)
	]), body_col)
	# Yüzey parlaması
	draw_line(Vector2(cx - bw3 * 0.40, cy3 + 1), Vector2(cx + bw3 * 0.40, cy3 + 1),
		Color(1, 1, 1, 0.12), 1.5)
	# Döner kadran
	draw_circle(Vector2(cx + 9, cy3 + bh3 * 0.52), 8.0, Color(0, 0, 0, 0.38))
	for di in 6:
		var ang2 := float(di) / 6.0 * TAU
		draw_circle(Vector2(cx + 9 + cos(ang2) * 5.5, cy3 + bh3 * 0.52 + sin(ang2) * 5.5),
			1.6, Color(0, 0, 0, 0.52))
	# Ahize yayı
	var hpts := PackedVector2Array()
	for hi in 13:
		var hf := float(hi) / 12.0
		hpts.append(Vector2((cx - bw3 * 0.40) + hf * bw3 * 0.80,
			cy3 - 10 - sin(hf * PI) * 12))
	if hpts.size() > 1:
		draw_polyline(hpts, body_col * Color(0.7, 0.7, 0.7), 6.0, true)

func _ashtray(cx: float, by2: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 20, by2), Vector2(cx + 20, by2),
		Vector2(cx + 14, by2 - 8), Vector2(cx - 14, by2 - 8)
	]), Color(0.095, 0.088, 0.072))
	draw_circle(Vector2(cx, by2 - 5), 10.0, Color(0.130, 0.120, 0.100))
	draw_circle(Vector2(cx, by2 - 5), 6.5, Color(0.065, 0.060, 0.050))
	# Sigara izmariti
	draw_rect(Rect2(cx - 18, by2 - 7, 22, 3.5), Color(0.82, 0.78, 0.60))
	draw_rect(Rect2(cx - 18, by2 - 7, 5, 3.5), Color(0.42, 0.40, 0.30))

func _trophy(cx: float, by2: float) -> void:
	# Kupa gövdesi
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 11, by2 - 32), Vector2(cx + 11, by2 - 32),
		Vector2(cx + 14, by2 - 18), Vector2(cx - 14, by2 - 18)
	]), Color(0.78, 0.62, 0.12))
	# Kulplar
	draw_arc(Vector2(cx - 12, by2 - 25), 5.5, PI * 0.5, PI * 1.5, 8,
		Color(0.68, 0.52, 0.08), 3.0)
	draw_arc(Vector2(cx + 12, by2 - 25), 5.5, -PI * 0.5, PI * 0.5, 8,
		Color(0.68, 0.52, 0.08), 3.0)
	# Gövde üst yuvarlak
	draw_circle(Vector2(cx, by2 - 32), 8.0, Color(0.72, 0.56, 0.10))
	# Sap
	draw_rect(Rect2(cx - 3.5, by2 - 18, 7, 12), Color(0.58, 0.44, 0.08))
	# Taban
	draw_rect(Rect2(cx - 12, by2 - 6, 24, 6), Color(0.50, 0.38, 0.06))
	draw_rect(Rect2(cx - 12, by2 - 6, 24, 2), Color(0.82, 0.68, 0.18))

func _notepad(cx: float, by2: float) -> void:
	draw_rect(Rect2(cx - 42, by2 - 44, 84, 48), Color(0.94, 0.92, 0.84))
	draw_rect(Rect2(cx - 42, by2 - 14, 84, 2), Color(0.82, 0.78, 0.68))
	draw_rect(Rect2(cx - 42, by2 - 44, 6, 48), Color(0.92, 0.25, 0.22))
	# El yazısı simülasyonu
	var rng := RandomNumberGenerator.new()
	rng.seed = 4455
	for li in 5:
		draw_rect(Rect2(cx - 33, by2 - 38 + float(li) * 7, rng.randf_range(40, 68), 1.5),
			Color(0.18, 0.16, 0.14, 0.30))

func _newspaper_on_desk(nx: float, ny: float) -> void:
	draw_rect(Rect2(nx, ny - 22, 95, 26), Color(0.82, 0.78, 0.68))
	draw_rect(Rect2(nx + 4, ny - 18, 87, 2.5), Color(0.18, 0.14, 0.10, 0.55))
	draw_rect(Rect2(nx + 4, ny - 13, 65, 1.5), Color(0.18, 0.14, 0.10, 0.38))
	draw_rect(Rect2(nx + 4, ny - 9, 72, 1.5), Color(0.18, 0.14, 0.10, 0.30))
	draw_rect(Rect2(nx + 4, ny - 5, 58, 1.5), Color(0.18, 0.14, 0.10, 0.25))

func _whisky(cx: float, by2: float) -> void:
	# Bardak
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 15, by2), Vector2(cx + 15, by2),
		Vector2(cx + 11, by2 - 32), Vector2(cx - 11, by2 - 32)
	]), Color(0.72, 0.50, 0.14, 0.28))
	draw_polyline(PackedVector2Array([
		Vector2(cx - 15, by2), Vector2(cx - 11, by2 - 32),
		Vector2(cx + 11, by2 - 32), Vector2(cx + 15, by2)
	]), Color(0.88, 0.72, 0.32, 0.65), 1.5, false)
	# Buz küpü
	draw_rect(Rect2(cx - 6, by2 - 26, 13, 11), Color(0.72, 0.86, 1.0, 0.32))
	draw_rect(Rect2(cx - 6, by2 - 26, 13, 11), Color(0.90, 0.96, 1.0, 0.20), false, 0.5)
	# Sıvı kıpırdaması
	var shimmer2 := 0.18 + 0.08 * sin(_t * 1.3)
	draw_rect(Rect2(cx - 11, by2 - 15, 22, 3), Color(0.82, 0.58, 0.18, shimmer2))

func _cigar(cx: float, by2: float) -> void:
	var pts2 := PackedVector2Array([
		Vector2(cx - 28, by2 - 3), Vector2(cx + 22, by2 - 3),
		Vector2(cx + 22, by2 + 3), Vector2(cx - 28, by2 + 3)
	])
	draw_colored_polygon(pts2, Color(0.28, 0.15, 0.06))
	# Kül
	draw_rect(Rect2(cx - 28, by2 - 3, 9, 6), Color(0.52, 0.50, 0.48))
	# Kor — animasyonlu
	var ember := 0.55 + 0.45 * sin(_t * 2.4)
	draw_circle(Vector2(cx - 28, by2), 3.5, Color(1.0, 0.38, 0.06, ember * 0.85))
	draw_circle(Vector2(cx - 28, by2), 6.0, Color(1.0, 0.20, 0.02, ember * 0.25))
	# Duman
	for dsi in 4:
		var ds_y := by2 - 4 - float(dsi) * 9.0
		var ds_x := cx - 28 + sin(_t * 0.7 + float(dsi) * 1.3) * 5
		draw_circle(Vector2(ds_x, ds_y), 3.5 + float(dsi) * 1.8,
			Color(0.70, 0.70, 0.72, 0.055 - float(dsi) * 0.010))

func _wall_photo(wx3: float, wy3: float, w3: float, h3: float) -> void:
	# Çerçeve
	draw_rect(Rect2(wx3, wy3, w3, h3), Color(0.098, 0.072, 0.038))
	# Mat
	draw_rect(Rect2(wx3 + 5, wy3 + 5, w3 - 10, h3 - 10), Color(0.060, 0.055, 0.048))
	# Fotoğraf içeriği — gece şehri
	draw_rect(Rect2(wx3 + 8, wy3 + 8, w3 - 16, h3 - 16), Color(0.028, 0.038, 0.062))
	_city_silhouette(wx3 + 8, wy3 + 8, w3 - 16, h3 - 16, 1)
	# Fotoğraf ışıkları
	var rng := RandomNumberGenerator.new()
	rng.seed = 1122
	for _fli in 20:
		draw_rect(Rect2(wx3 + 10 + rng.randf() * (w3 - 20),
			wy3 + 10 + (h3 - 20) * (0.55 + rng.randf() * 0.4),
			2 + rng.randf() * 6, 1.5 + rng.randf() * 4), Color(rng.randf(), rng.randf(), rng.randf() * 0.5 + 0.5, 0.55))
	# Çerçeve kenarlığı
	draw_rect(Rect2(wx3, wy3, w3, h3), Color(0.640, 0.520, 0.260, 0.45), false, 1.0)

func _wall_certificate(wx4: float, wy4: float, w4: float, h4: float) -> void:
	draw_rect(Rect2(wx4, wy4, w4, h4), Color(0.098, 0.072, 0.038))
	draw_rect(Rect2(wx4 + 4, wy4 + 4, w4 - 8, h4 - 8), Color(0.88, 0.82, 0.64))
	# Sertifika içeriği
	draw_rect(Rect2(wx4 + 8, wy4 + 8, w4 - 16, 3), Color(0.20, 0.14, 0.06, 0.6))
	var rng := RandomNumberGenerator.new()
	rng.seed = 8877
	for li in 5:
		draw_rect(Rect2(wx4 + 8, wy4 + 16 + float(li) * 10, rng.randf_range(50, w4 - 20), 1.8),
			Color(0.20, 0.14, 0.06, 0.45))
	# Mühür / oval
	draw_circle(Vector2(wx4 + w4 - 22, wy4 + h4 - 20), 12.0, Color(0.20, 0.14, 0.06, 0.15))
	draw_arc(Vector2(wx4 + w4 - 22, wy4 + h4 - 20), 12.0, 0, TAU, 24,
		Color(0.60, 0.42, 0.10, 0.50), 1.5)
	draw_rect(Rect2(wx4, wy4, w4, h4), Color(0.640, 0.520, 0.260, 0.40), false, 1.0)

func _trophy_cabinet(tx: float, ty: float, tw: float, th: float) -> void:
	# Kabine gövdesi
	draw_rect(Rect2(tx, ty, tw, th), Color(0.040, 0.036, 0.050))
	draw_rect(Rect2(tx, ty, tw, th), Color(0.70, 0.55, 0.18, 0.28), false, 1.0)
	# Cam parlaması
	draw_rect(Rect2(tx + 2, ty + 2, 4, th - 4), Color(1, 1, 1, 0.06))
	# Raflar
	for si in 3:
		draw_rect(Rect2(tx, ty + float(si + 1) * (th / 4.0), tw, 2.5),
			Color(0.060, 0.054, 0.074))
		# Her rafta kupa
		_trophy(tx + tw / 2, ty + float(si) * (th / 4.0) + (th / 4.0) - 2)

func _wall_art_abstract(ax: float, ay: float, aw: float, ah: float) -> void:
	# Çerçeve
	draw_rect(Rect2(ax, ay, aw, ah), Color(0.042, 0.038, 0.052))
	draw_rect(Rect2(ax + 4, ay + 4, aw - 8, ah - 8), Color(0.022, 0.020, 0.030))
	# Soyut altın eğri
	var apts := PackedVector2Array()
	for ai in 20:
		var af := float(ai) / 19.0
		apts.append(Vector2(
			ax + 8 + af * (aw - 16),
			ay + 8 + (ah - 16) * (0.5 + 0.4 * sin(af * PI * 2.2))
		))
	if apts.size() > 1:
		draw_polyline(apts, Color(0.78, 0.60, 0.14, 0.75), 2.0, true)
	# İkinci eğri
	var apts2 := PackedVector2Array()
	for ai2 in 16:
		var af2 := float(ai2) / 15.0
		apts2.append(Vector2(
			ax + 8 + af2 * (aw - 16),
			ay + 8 + (ah - 16) * (0.5 + 0.25 * cos(af2 * PI * 3.1 + 0.8))
		))
	if apts2.size() > 1:
		draw_polyline(apts2, Color(0.78, 0.60, 0.14, 0.30), 1.2, true)
	# Daire
	draw_circle(Vector2(ax + aw / 2, ay + ah / 2), minf(aw, ah) * 0.22, Color(0.78, 0.60, 0.14, 0.12))
	draw_arc(Vector2(ax + aw / 2, ay + ah / 2), minf(aw, ah) * 0.22, 0, TAU, 32,
		Color(0.78, 0.60, 0.14, 0.40), 1.0)
	draw_rect(Rect2(ax, ay, aw, ah), Color(0.70, 0.55, 0.18, 0.32), false, 1.0)

func _penthouse_desk() -> void:
	# Kavisli executive masa
	var dp := PackedVector2Array([
		Vector2(W * 0.07, H * 0.72),
		Vector2(W * 0.07, H * 0.618),
		Vector2(W * 0.15, H * 0.600),
		Vector2(W * 0.45, H * 0.588),
		Vector2(W * 0.72, H * 0.592),
		Vector2(W * 0.92, H * 0.608),
		Vector2(W * 0.93, H * 0.72)
	])
	draw_colored_polygon(dp, Color(0.038, 0.034, 0.050))
	# Masa üst kenarı — altın aksanı
	draw_polyline(PackedVector2Array([
		Vector2(W * 0.07, H * 0.618),
		Vector2(W * 0.15, H * 0.600),
		Vector2(W * 0.45, H * 0.588),
		Vector2(W * 0.72, H * 0.592),
		Vector2(W * 0.92, H * 0.608)
	]), Color(0.70, 0.54, 0.16, 0.45), 2.8, false)
	# Masa yüzey parlaması
	draw_polyline(PackedVector2Array([
		Vector2(W * 0.09, H * 0.615),
		Vector2(W * 0.16, H * 0.598),
		Vector2(W * 0.45, H * 0.587)
	]), Color(1, 1, 1, 0.05), 18.0, false)

# ═══════════════════════════════════════════════════════════════════════════════
# NPC FİGÜRLERİ
# ═══════════════════════════════════════════════════════════════════════════════

func _npc_hunched(cx: float, by2: float) -> void:
	# Gölge
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 18, by2 + 2), Vector2(cx + 22, by2 + 2),
		Vector2(cx + 20, by2 + 6), Vector2(cx - 16, by2 + 6)
	]), Color(0, 0, 0, 0.22))
	var sway := sin(_t * 0.4) * 1.5
	# Gövde — öne eğilmiş
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 15, by2 - 28),
		Vector2(cx - 16, by2 - 55),
		Vector2(cx + 6, by2 - 60 + sway),
		Vector2(cx + 13, by2 - 45 + sway),
		Vector2(cx + 13, by2 - 28)
	]), Color(0.085, 0.085, 0.085))
	# Baş — eğik
	draw_circle(Vector2(cx + 6, by2 - 66 + sway), 12.0, Color(0.62, 0.50, 0.36))
	# Saç — dağınık
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 3, by2 - 75 + sway),
		Vector2(cx + 15, by2 - 74 + sway),
		Vector2(cx + 18, by2 - 62 + sway),
		Vector2(cx - 2, by2 - 63 + sway)
	]), Color(0.140, 0.095, 0.050))
	# Kollar — masaya uzanmış
	draw_line(Vector2(cx - 13, by2 - 35), Vector2(cx - 4, by2 - 10), Color(0.085, 0.085, 0.085), 7.0)
	draw_line(Vector2(cx + 11, by2 - 40 + sway), Vector2(cx + 20, by2 - 10), Color(0.085, 0.085, 0.085), 7.0)
	# Eller
	draw_circle(Vector2(cx - 3, by2 - 10), 5.0, Color(0.62, 0.50, 0.36))
	draw_circle(Vector2(cx + 21, by2 - 10), 5.0, Color(0.62, 0.50, 0.36))

func _npc_standing(cx: float, by2: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 16, by2 + 2), Vector2(cx + 16, by2 + 2),
		Vector2(cx + 14, by2 + 6), Vector2(cx - 14, by2 + 6)
	]), Color(0, 0, 0, 0.20))
	var sway := sin(_t * 0.5) * 1.0
	# Bacaklar
	draw_rect(Rect2(cx - 9, by2 - 52, 8, 52), Color(0.060, 0.060, 0.085))
	draw_rect(Rect2(cx + 1, by2 - 52, 8, 52), Color(0.060, 0.060, 0.085))
	# Takım elbise gövdesi
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 15, by2 - 52),
		Vector2(cx + 15, by2 - 52),
		Vector2(cx + 13 + sway, by2 - 98),
		Vector2(cx - 13 + sway, by2 - 98)
	]), Color(0.060, 0.060, 0.085))
	# Gömlek
	draw_rect(Rect2(cx - 5 + sway * 0.5, by2 - 94, 10, 38), Color(0.88, 0.86, 0.92))
	# Kravat
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + sway * 0.5, by2 - 93),
		Vector2(cx - 3.5 + sway * 0.5, by2 - 76),
		Vector2(cx + sway * 0.5, by2 - 58),
		Vector2(cx + 3.5 + sway * 0.5, by2 - 76)
	]), Color(0.58, 0.08, 0.08))
	# Ceket yaka
	draw_line(Vector2(cx - 5 + sway, by2 - 98), Vector2(cx - 2 + sway, by2 - 85), Color(0.042, 0.042, 0.060), 4.0)
	draw_line(Vector2(cx + 5 + sway, by2 - 98), Vector2(cx + 2 + sway, by2 - 85), Color(0.042, 0.042, 0.060), 4.0)
	# Baş
	draw_circle(Vector2(cx + sway, by2 - 109), 12.5, Color(0.68, 0.55, 0.38))
	# Saç
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 11 + sway, by2 - 116),
		Vector2(cx + 11 + sway, by2 - 116),
		Vector2(cx + 13 + sway, by2 - 107),
		Vector2(cx - 13 + sway, by2 - 107)
	]), Color(0.200, 0.130, 0.065))

func _npc_sitting(cx: float, by2: float, suit_col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 14, by2 + 2), Vector2(cx + 14, by2 + 2),
		Vector2(cx + 12, by2 + 5), Vector2(cx - 12, by2 + 5)
	]), Color(0, 0, 0, 0.18))
	var sway := sin(_t * 0.4) * 1.0
	# Üst gövde (masa üstü)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 13, by2),
		Vector2(cx + 13, by2),
		Vector2(cx + 11 + sway, by2 - 45),
		Vector2(cx - 11 + sway, by2 - 45)
	]), suit_col)
	# Gömlek
	draw_rect(Rect2(cx - 3.5 + sway * 0.5, by2 - 41, 7, 30), Color(0.78, 0.78, 0.86))
	# Baş
	draw_circle(Vector2(cx + sway, by2 - 57), 11.5, Color(0.65, 0.50, 0.34))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 11 + sway, by2 - 64),
		Vector2(cx + 11 + sway, by2 - 64),
		Vector2(cx + 12 + sway, by2 - 56),
		Vector2(cx - 12 + sway, by2 - 56)
	]), Color(0.140, 0.095, 0.045))

func _npc_executive(cx: float, by2: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 18, by2 + 2), Vector2(cx + 18, by2 + 2),
		Vector2(cx + 16, by2 + 6), Vector2(cx - 16, by2 + 6)
	]), Color(0, 0, 0, 0.28))
	var sway := sin(_t * 0.35) * 1.2
	# Bacaklar — ince kesim
	draw_rect(Rect2(cx - 10, by2 - 58, 9, 58), Color(0.028, 0.024, 0.038))
	draw_rect(Rect2(cx + 1, by2 - 58, 9, 58), Color(0.028, 0.024, 0.038))
	# Gövde
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 16, by2 - 58),
		Vector2(cx + 16, by2 - 58),
		Vector2(cx + 14 + sway, by2 - 105),
		Vector2(cx - 14 + sway, by2 - 105)
	]), Color(0.032, 0.028, 0.045))
	# Beyaz gömlek
	draw_rect(Rect2(cx - 5 + sway * 0.5, by2 - 101, 10, 42), Color(0.92, 0.92, 0.96))
	# Altın kravat
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + sway * 0.5, by2 - 101),
		Vector2(cx - 4 + sway * 0.5, by2 - 82),
		Vector2(cx + sway * 0.5, by2 - 64),
		Vector2(cx + 4 + sway * 0.5, by2 - 82)
	]), Color(0.72, 0.52, 0.10))
	# Cep mendili
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 9 + sway, by2 - 93),
		Vector2(cx + 15 + sway, by2 - 98),
		Vector2(cx + 16 + sway, by2 - 90)
	]), Color(0.72, 0.52, 0.10))
	# Baş
	draw_circle(Vector2(cx + sway, by2 - 117), 13.5, Color(0.70, 0.56, 0.38))
	# Gümüş saç — deneyimli
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 13 + sway, by2 - 126),
		Vector2(cx + 13 + sway, by2 - 126),
		Vector2(cx + 14 + sway, by2 - 116),
		Vector2(cx - 14 + sway, by2 - 116)
	]), Color(0.72, 0.72, 0.76))

func _npc_advisor(cx: float, by2: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 15, by2 + 2), Vector2(cx + 15, by2 + 2),
		Vector2(cx + 13, by2 + 5), Vector2(cx - 13, by2 + 5)
	]), Color(0, 0, 0, 0.22))
	var sway := sin(_t * 0.45) * 1.0
	# Bacaklar
	draw_rect(Rect2(cx - 9, by2 - 52, 8, 52), Color(0.038, 0.034, 0.050))
	draw_rect(Rect2(cx + 1, by2 - 52, 8, 52), Color(0.038, 0.034, 0.050))
	# Gövde
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 13, by2 - 52),
		Vector2(cx + 13, by2 - 52),
		Vector2(cx + 11 + sway, by2 - 96),
		Vector2(cx - 11 + sway, by2 - 96)
	]), Color(0.042, 0.038, 0.055))
	# Gömlek
	draw_rect(Rect2(cx - 4 + sway * 0.5, by2 - 92, 8, 36), Color(0.84, 0.82, 0.90))
	# Tablet / dosya
	draw_rect(Rect2(cx + 15 + sway, by2 - 82, 26, 34), Color(0.032, 0.028, 0.045))
	draw_rect(Rect2(cx + 17 + sway, by2 - 80, 22, 30), Color(0.055, 0.068, 0.105))
	for ali in 3:
		draw_rect(Rect2(cx + 19 + sway, by2 - 75 + float(ali) * 8, 14, 2),
			Color(0.40, 0.62, 1.0, 0.45))
	# Baş
	draw_circle(Vector2(cx + sway, by2 - 107), 12.0, Color(0.62, 0.48, 0.30))
	# Koyu saç
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 12 + sway, by2 - 116),
		Vector2(cx + 12 + sway, by2 - 116),
		Vector2(cx + 13 + sway, by2 - 107),
		Vector2(cx - 13 + sway, by2 - 107)
	]), Color(0.080, 0.055, 0.030))

# ═══════════════════════════════════════════════════════════════════════════════
# GENEL YARDIMCILAR
# ═══════════════════════════════════════════════════════════════════════════════

func _grad_rect(rect: Rect2, top_col: Color, bot_col: Color) -> void:
	var steps := 12
	for i in steps:
		var t2 := float(i) / float(steps - 1)
		var col := top_col.lerp(bot_col, t2)
		draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * t2 / float(steps),
			rect.size.x, rect.size.y / float(steps) + 1), col)

func _scanlines(strength: float) -> void:
	var y := 0.0
	while y < H:
		draw_line(Vector2(0, y), Vector2(W, y), Color(0, 0, 0, 0.018), 1.0)
		y += 4.0
	var d2 := W * (0.04 + strength * 0.5)
	draw_rect(Rect2(0, 0, d2, H), Color(0, 0, 0, 0.08 + strength * 0.25))
	draw_rect(Rect2(W - d2, 0, d2, H), Color(0, 0, 0, 0.08 + strength * 0.25))
	draw_rect(Rect2(0, 0, W, H * 0.025), Color(0, 0, 0, 0.08))
	draw_rect(Rect2(0, H * 0.975, W, H * 0.025), Color(0, 0, 0, 0.08))

func _vignette(strength: float) -> void:
	# Basit köşe kararması — çokgen yaklaşımı (shader olmadan)
	var margin := W * 0.32
	var steps2 := 8
	for i in steps2:
		var t2 := float(i) / float(steps2)
		var alpha2 := strength * t2 * t2 * 0.22
		draw_rect(Rect2(0, 0, margin * (1.0 - t2), H), Color(0, 0, 0, alpha2))
		draw_rect(Rect2(W - margin * (1.0 - t2), 0, margin * (1.0 - t2), H), Color(0, 0, 0, alpha2))
		var vm := H * 0.22
		draw_rect(Rect2(0, 0, W, vm * (1.0 - t2)), Color(0, 0, 0, alpha2))
		draw_rect(Rect2(0, H - vm * (1.0 - t2), W, vm * (1.0 - t2)), Color(0, 0, 0, alpha2))

func _cubic(p0: float, p1: float, p2: float, p3: float, t2: float) -> float:
	# Cubic Bezier interpolation
	var u := 1.0 - t2
	return u * u * u * p0 + 3 * u * u * t2 * p1 + 3 * u * t2 * t2 * p2 + t2 * t2 * t2 * p3
