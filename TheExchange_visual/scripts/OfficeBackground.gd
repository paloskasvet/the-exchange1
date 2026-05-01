class_name OfficeBackground
extends Control

var _t: float = 0.0

# City light particles
var _city_lights: Array = []
var _scanline_offset: float = 0.0

func _ready() -> void:
	randomize()
	_spawn_city_lights()
	set_process(true)

func _spawn_city_lights() -> void:
	_city_lights.clear()
	for _i in range(120):
		_city_lights.append({
			"x":     randf(),
			"y":     randf_range(0.55, 0.88),
			"w":     randf_range(0.004, 0.018),
			"h":     randf_range(0.01,  0.06),
			"col":   _rand_city_color(),
			"blink": randf() > 0.85,
			"phase": randf() * TAU,
			"speed": randf_range(0.5, 2.5),
		})

func _rand_city_color() -> Color:
	var roll = randi() % 5
	match roll:
		0: return Color(1.0,  0.85, 0.4,  randf_range(0.5, 0.9))   # warm gold
		1: return Color(0.5,  0.75, 1.0,  randf_range(0.5, 0.8))   # cool blue
		2: return Color(0.9,  0.95, 1.0,  randf_range(0.4, 0.7))   # white
		3: return Color(1.0,  0.4,  0.35, randf_range(0.3, 0.6))   # red signal
		_: return Color(0.65, 1.0,  0.65, randf_range(0.3, 0.6))   # green

func _process(delta: float) -> void:
	_t += delta
	_scanline_offset = fmod(_t * 60.0, size.y)
	queue_redraw()

func _draw() -> void:
	var W = size.x
	var H = size.y

	# ── 1. Deep space background ─────────────────────────────────────────────
	draw_rect(Rect2(0, 0, W, H), Color(0.03, 0.035, 0.05))

	# ── 2. Window frame (occupies right 55% of screen) ───────────────────────
	var wx  = W * 0.32
	var wy  = H * 0.06
	var ww  = W * 0.66
	var wh  = H * 0.62
	_draw_window(wx, wy, ww, wh, W, H)

	# ── 3. Desk surface ───────────────────────────────────────────────────────
	_draw_desk(W, H)

	# ── 4. Monitor bezels ─────────────────────────────────────────────────────
	_draw_monitors(W, H)

	# ── 5. Desk lamp ─────────────────────────────────────────────────────────
	_draw_lamp(W, H)

	# ── 6. Coffee mug ────────────────────────────────────────────────────────
	_draw_mug(W, H)

	# ── 7. Papers / documents ────────────────────────────────────────────────
	_draw_papers(W, H)

	# ── 8. Subtle scanlines over everything ───────────────────────────────────
	_draw_scanlines(W, H)

# ─────────────────────────────────────────────────────────────────────────────

func _draw_window(wx: float, wy: float, ww: float, wh: float, W: float, H: float) -> void:
	# Night sky gradient (manual banding)
	for i in range(12):
		var t_  = float(i) / 12.0
		var y_  = wy + wh * t_
		var bh_ = wh / 12.0 + 1.0
		var sky_col = Color(
			lerp(0.04, 0.08, t_),
			lerp(0.05, 0.04, t_),
			lerp(0.12, 0.06, t_)
		)
		draw_rect(Rect2(wx, y_, ww, bh_), sky_col)

	# Stars
	var rng = RandomNumberGenerator.new(); rng.seed = 42
	for _i in range(80):
		var sx  = wx + rng.randf() * ww
		var sy  = wy + rng.randf() * wh * 0.45
		var br  = 0.4 + 0.5 * abs(sin(_t * rng.randf_range(0.3, 1.5) + rng.randf() * TAU))
		draw_circle(Vector2(sx, sy), rng.randf_range(0.5, 1.4), Color(1, 1, 1, br * 0.7))

	# Moon
	var mx = wx + ww * 0.82
	var my = wy + wh * 0.14
	draw_circle(Vector2(mx, my), 22, Color(0.96, 0.94, 0.82, 0.90))
	draw_circle(Vector2(mx + 8, my - 4), 18, Color(0.04, 0.05, 0.10, 0.85))

	# Distant city silhouette
	var silhouette_pts: PackedVector2Array = []
	silhouette_pts.append(Vector2(wx, wy + wh))
	silhouette_pts.append(Vector2(wx, wy + wh * 0.68))
	var rng2 = RandomNumberGenerator.new(); rng2.seed = 99
	var cx = wx
	while cx < wx + ww:
		var bw = rng2.randf_range(18, 55)
		var bh = rng2.randf_range(wh * 0.08, wh * 0.32)
		var by = wy + wh - bh
		silhouette_pts.append(Vector2(cx, by))
		silhouette_pts.append(Vector2(cx + bw, by))
		cx += bw
	silhouette_pts.append(Vector2(wx + ww, wy + wh * 0.68))
	silhouette_pts.append(Vector2(wx + ww, wy + wh))
	draw_colored_polygon(silhouette_pts, Color(0.06, 0.07, 0.10))

	# City lights on buildings
	for light in _city_lights:
		var lx = wx + light["x"] * ww
		var ly = light["y"] * H
		if ly < wy or ly > wy + wh: continue
		var alpha = light["col"].a
		if light["blink"]:
			alpha *= 0.5 + 0.5 * sin(_t * light["speed"] + light["phase"])
		var c = light["col"]; c.a = alpha
		draw_rect(Rect2(lx, ly, light["w"] * W, light["h"] * H * 0.25), c)

	# Reflection / rain streaks on glass
	for i in range(18):
		var rng3 = RandomNumberGenerator.new(); rng3.seed = i * 7
		var rx   = wx + rng3.randf() * ww
		var ry_start = wy + fmod(_t * rng3.randf_range(40, 120) + rng3.randf() * wh, wh)
		var ry_end   = ry_start + rng3.randf_range(20, 60)
		draw_line(Vector2(rx, ry_start), Vector2(rx + 1, min(ry_end, wy + wh)),
			Color(0.5, 0.7, 1.0, 0.06), 1.0)

	# Window frame / crossbars
	var frame_col = Color(0.10, 0.12, 0.18)
	draw_rect(Rect2(wx - 6,  wy - 6,  ww + 12, 6),   frame_col)
	draw_rect(Rect2(wx - 6,  wy + wh, ww + 12, 6),   frame_col)
	draw_rect(Rect2(wx - 6,  wy - 6,  6, wh + 12),   frame_col)
	draw_rect(Rect2(wx + ww, wy - 6,  6, wh + 12),   frame_col)
	# Crossbar
	draw_rect(Rect2(wx, wy + wh * 0.48, ww, 5), frame_col)
	draw_rect(Rect2(wx + ww * 0.5, wy, 5, wh),  frame_col)

	# Glass glare
	draw_line(Vector2(wx + 12, wy + 8), Vector2(wx + ww * 0.18, wy + wh * 0.25),
		Color(1, 1, 1, 0.04), 14)

func _draw_desk(W: float, H: float) -> void:
	# Main desk surface
	var desk_y = H * 0.72
	draw_rect(Rect2(0, desk_y, W, H - desk_y), Color(0.09, 0.075, 0.06))
	# Desk edge highlight
	draw_rect(Rect2(0, desk_y, W, 3), Color(0.22, 0.18, 0.13))
	# Desk edge shadow
	draw_rect(Rect2(0, desk_y + 3, W, 6), Color(0.04, 0.035, 0.03))
	# Surface sheen
	draw_line(Vector2(0, desk_y + 2), Vector2(W, desk_y + 2), Color(1, 0.9, 0.7, 0.06), 1.5)

func _draw_monitors(W: float, H: float) -> void:
	# Left monitor
	_draw_single_monitor(W * 0.04, H * 0.22, W * 0.24, H * 0.46, W, H, 0)
	# Right monitor (angled slightly)
	_draw_single_monitor(W * 0.31, H * 0.18, W * 0.27, H * 0.50, W, H, 1)

func _draw_single_monitor(mx: float, my: float, mw: float, mh: float,
		W: float, H: float, idx: int) -> void:
	# Stand
	var stand_x = mx + mw * 0.44
	var stand_y = my + mh
	draw_rect(Rect2(stand_x, stand_y, mw * 0.12, H * 0.025), Color(0.12, 0.12, 0.14))
	draw_rect(Rect2(stand_x - mw * 0.08, stand_y + H * 0.025, mw * 0.28, H * 0.012),
		Color(0.10, 0.10, 0.12))

	# Bezel
	draw_rect(Rect2(mx - 6, my - 6, mw + 12, mh + 12), Color(0.10, 0.10, 0.13))
	draw_rect(Rect2(mx - 8, my - 8, mw + 16, mh + 16), Color(0.14, 0.14, 0.17))

	# Screen glow (color depends on index)
	var glow_col = Color(0.08, 0.22, 0.38, 0.25) if idx == 0 else Color(0.05, 0.18, 0.08, 0.20)
	draw_rect(Rect2(mx, my, mw, mh), glow_col)

	# Screen content suggestion (horizontal lines)
	for i in range(8):
		var ly  = my + mh * (0.12 + float(i) * 0.1)
		var lw  = mw * randf_range(0.3, 0.85)
		var col = Color(0.25, 0.55, 0.95, 0.12) if idx == 0 else Color(0.25, 0.70, 0.40, 0.12)
		draw_rect(Rect2(mx + mw * 0.06, ly, lw, 2), col)

	# Power LED
	draw_circle(Vector2(mx + mw - 10, my + mh - 8), 2.5,
		Color(0.25, 0.85, 0.45, 0.7 + 0.3 * sin(_t * 1.5 + idx)))

func _draw_lamp(W: float, H: float) -> void:
	var lx = W * 0.89
	var ly = H * 0.52
	# Base
	draw_rect(Rect2(lx - 18, H * 0.73, 36, 6), Color(0.15, 0.14, 0.13))
	# Arm
	draw_line(Vector2(lx, H * 0.73), Vector2(lx - 20, ly + 40), Color(0.18, 0.16, 0.14), 4)
	draw_line(Vector2(lx - 20, ly + 40), Vector2(lx - 10, ly), Color(0.18, 0.16, 0.14), 4)
	# Shade
	var shade_pts = PackedVector2Array([
		Vector2(lx - 32, ly),
		Vector2(lx + 14,  ly),
		Vector2(lx + 8,   ly + 20),
		Vector2(lx - 26,  ly + 20),
	])
	draw_colored_polygon(shade_pts, Color(0.22, 0.19, 0.14))
	# Light cone
	var cone_pts = PackedVector2Array([
		Vector2(lx - 30, ly + 20),
		Vector2(lx + 12,  ly + 20),
		Vector2(lx + 55,  H * 0.73),
		Vector2(lx - 75,  H * 0.73),
	])
	draw_colored_polygon(cone_pts, Color(1.0, 0.92, 0.65, 0.04))
	# Bulb
	draw_circle(Vector2(lx - 9, ly + 10), 5, Color(1.0, 0.95, 0.7, 0.9))

func _draw_mug(W: float, H: float) -> void:
	var cx = W * 0.82
	var cy = H * 0.71
	var mw = W * 0.028
	var mh = H * 0.045
	# Mug body
	draw_rect(Rect2(cx - mw, cy - mh, mw * 2, mh), Color(0.18, 0.16, 0.15))
	# Handle
	draw_arc(Vector2(cx + mw, cy - mh * 0.5), mh * 0.38, -PI * 0.4, PI * 0.4, 12,
		Color(0.16, 0.14, 0.13), 2.5)
	# Steam
	for i in range(3):
		var sx   = cx - mw * 0.5 + i * mw * 0.5
		var base = cy - mh - 4
		var amp  = 4.0
		var ph   = _t * 1.2 + i * 0.8
		for j in range(6):
			var y1 = base - j * 4
			var y2 = base - (j + 1) * 4
			draw_line(
				Vector2(sx + sin(ph + j * 0.5) * amp, y1),
				Vector2(sx + sin(ph + (j+1) * 0.5) * amp, y2),
				Color(0.8, 0.8, 0.85, 0.06 - j * 0.008), 1.5)

func _draw_papers(W: float, H: float) -> void:
	var py = H * 0.73
	# Paper stack 1
	for i in range(3):
		draw_rect(Rect2(W * 0.06 + i * 2, py - i * 2, W * 0.09, H * 0.03),
			Color(0.88, 0.87, 0.83, 0.65))
	# Some faint lines on top paper
	for j in range(4):
		draw_rect(Rect2(W * 0.07, py - 6 + j * 5, W * 0.06, 1),
			Color(0.5, 0.5, 0.5, 0.25))

	# Small sticky note
	draw_rect(Rect2(W * 0.17, py - 4, W * 0.045, H * 0.022), Color(1.0, 0.92, 0.4, 0.75))
	draw_rect(Rect2(W * 0.172, py - 2, W * 0.03, 1), Color(0.5, 0.45, 0.1, 0.4))
	draw_rect(Rect2(W * 0.172, py + 2, W * 0.025, 1), Color(0.5, 0.45, 0.1, 0.4))

func _draw_scanlines(W: float, H: float) -> void:
	var i = 0.0
	while i < H:
		draw_line(Vector2(0, i), Vector2(W, i), Color(0, 0, 0, 0.035), 1.0)
		i += 3.0
	# Very subtle vignette corners (4 corner rects)
	draw_rect(Rect2(0,     0,     W * 0.12, H),       Color(0, 0, 0, 0.18))
	draw_rect(Rect2(W * 0.88, 0,  W * 0.12, H),       Color(0, 0, 0, 0.18))
	draw_rect(Rect2(0,     0,     W,        H * 0.06), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(0,     H * 0.94, W,    H * 0.06), Color(0, 0, 0, 0.12))
