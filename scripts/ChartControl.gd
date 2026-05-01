class_name ChartControl
extends Control

var ticker: String = "GIDX"

func set_ticker(t: String) -> void:
	ticker = t
	queue_redraw()

func _draw() -> void:
	var history: Array = MarketEngine.price_history.get(ticker, [])
	if history.size() < 2: return
	var w := size.x; var h := size.y
	var pad := Vector2(54.0, 20.0)

	draw_rect(Rect2(0, 0, w, h), Color(0.025, 0.030, 0.048))

	var min_p = history.min(); var max_p = history.max()
	var margin = (max_p - min_p) * 0.08
	min_p -= margin; max_p += margin
	var range_p = maxf(max_p - min_p, 0.001)

	var font := ThemeDB.fallback_font
	for i in range(6):
		var fy := pad.y + (h - pad.y * 2.0) * i / 5.0
		draw_line(Vector2(pad.x, fy), Vector2(w - 8, fy), Color(0.15, 0.18, 0.24), 0.5)
		var val = max_p - range_p * i / 5.0
		draw_string(font, Vector2(2, fy + 4), "$%.2f" % val, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.42, 0.46, 0.56))

	var pts = PackedVector2Array()
	var step = (w - pad.x - 8.0) / float(history.size() - 1)
	for i in range(history.size()):
		var px = pad.x + step * i
		var py = pad.y + (h - pad.y * 2.0) * (1.0 - (history[i] - min_p) / range_p)
		pts.append(Vector2(px, py))

	var up = history[-1] >= history[0]
	var line_col := Color(0.22, 0.88, 0.52) if up else Color(0.92, 0.28, 0.28)

	var fill_pts := PackedVector2Array()
	fill_pts.append(Vector2(pts[0].x, h))
	for pt in pts: fill_pts.append(pt)
	fill_pts.append(Vector2(pts[-1].x, h))
	draw_colored_polygon(fill_pts, Color(line_col.r, line_col.g, line_col.b, 0.08))
	draw_polyline(pts, line_col, 1.5, true)

	draw_circle(pts[-1], 3.5, line_col)
	draw_string(font, pts[-1] + Vector2(6, 4), "$%.2f" % history[-1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, line_col)

	var info := MarketEngine.get_asset_info(ticker)
	draw_string(font, Vector2(pad.x, 14), "%s  —  %s" % [ticker, info.get("name","")], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.82, 0.84, 0.90))
	var pct := MarketEngine.get_change_pct(ticker)
	draw_string(font, Vector2(w - 110, 14), "%+.2f%% today" % pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, line_col)
