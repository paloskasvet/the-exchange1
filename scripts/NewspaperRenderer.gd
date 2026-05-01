extends Control

# ════════════════════════════════════════════════════════════════════════════════
# NEWSPAPER RENDERER — 1920s CLASSIC BROADSHEET STYLE
# ════════════════════════════════════════════════════════════════════════════════
# Renders the newspaper popup with authentic period design:
# - Masthead with decorative ornaments
# - Multi-column layout (main story + filler columns)
# - Period typography and spacing
# - Vintage paper texture with scanlines

signal close_requested

var _paper_data: Dictionary = {}
var _t: float = 0.0

const PAPER_COLOR = Color(0.94, 0.92, 0.88)     # Aged paper
const TEXT_COLOR = Color(0.08, 0.08, 0.08)      # Dark ink
const ACCENT_COLOR = Color(0.20, 0.10, 0.05)    # Deep brown

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER_RECT)
	custom_minimum_size = Vector2(1000, 1400)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func set_paper(data: Dictionary) -> void:
	_paper_data = data
	queue_redraw()

func _draw() -> void:
	if _paper_data.is_empty():
		return
	
	var W = size.x
	var H = size.y
	
	# Paper background with aged texture
	_draw_paper_bg(W, H)
	
	# Masthead (title block with decorative elements)
	_draw_masthead(W)
	
	# Divider line
	_draw_divider(W, 130)
	
	# Main story area (left 2/3 + right column)
	_draw_main_layout(W, H)
	
	# Bottom footer with page info
	_draw_footer(W, H)

func _draw_paper_bg(W: float, H: float) -> void:
	# Base aged paper color
	draw_rect(Rect2(0, 0, W, H), PAPER_COLOR)
	
	# Subtle wrinkle texture with noise
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 60:
		var x = rng.randf() * W
		var y = rng.randf() * H
		var sz = rng.randf_range(80, 300)
		var alpha = rng.randf_range(0.005, 0.015)
		draw_rect(Rect2(x, y, sz, sz), Color(0.0, 0.0, 0.0, alpha))
	
	# Scanline effect (period printing)
	for y in range(0, int(H), 3):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0.0, 0.0, 0.0, 0.008), 1.0)

func _draw_masthead(W: float) -> void:
	var y_pos = 12.0
	var font = ThemeDB.fallback_font
	var font_sm = ThemeDB.fallback_font
	
	# Top ornament line
	draw_line(Vector2(20, y_pos), Vector2(W - 20, y_pos), ACCENT_COLOR, 2.0)
	y_pos += 8
	
	# Decorative corner elements
	_draw_ornament(Vector2(22, y_pos), 16)
	_draw_ornament(Vector2(W - 38, y_pos), 16)
	
	# Main masthead title
	draw_string(font, Vector2(W / 2, y_pos + 6), "The World Telegraph", 
		HORIZONTAL_ALIGNMENT_CENTER, -1, 36, ACCENT_COLOR)
	y_pos += 42
	
	# Subtitle/tagline
	draw_string(font_sm, Vector2(W / 2, y_pos), 
		"\"ALL THE NEWS THAT MOVES MARKETS\"", 
		HORIZONTAL_ALIGNMENT_CENTER, -1, 11, TEXT_COLOR)
	y_pos += 16
	
	# Publication info row
	var est_str = "EST. 1890"
	var vol_str = "VOL. CXLII  ·  No. %d" % [_get_issue_number()]
	var price_str = "PRICE: TWO CENTS"
	
	draw_string(font_sm, Vector2(26, y_pos), est_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, TEXT_COLOR)
	draw_string(font_sm, Vector2(W / 2, y_pos), vol_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, TEXT_COLOR)
	draw_string(font_sm, Vector2(W - 26, y_pos), price_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, TEXT_COLOR)
	y_pos += 14
	
	# Edition info
	draw_string(font_sm, Vector2(W / 2, y_pos), "LATE CITY EDITION", 
		HORIZONTAL_ALIGNMENT_CENTER, -1, 11, ACCENT_COLOR)
	y_pos += 14
	
	# Date
	draw_string(font_sm, Vector2(W / 2, y_pos), _paper_data.get("date", "Unknown Date"), 
		HORIZONTAL_ALIGNMENT_CENTER, -1, 10, TEXT_COLOR)

func _draw_masthead_divider(W: float, y: float) -> void:
	draw_line(Vector2(20, y), Vector2(W - 20, y), ACCENT_COLOR, 2.0)
	draw_line(Vector2(20, y + 3), Vector2(W - 20, y + 3), ACCENT_COLOR, 0.5)

func _draw_ornament(pos: Vector2, size: float) -> void:
	# Small decorative diamond/star
	var pts = PackedVector2Array([
		pos + Vector2(0, -size/2),
		pos + Vector2(size/2, 0),
		pos + Vector2(0, size/2),
		pos + Vector2(-size/2, 0)
	])
	draw_colored_polygon(pts, ACCENT_COLOR)

func _draw_divider(W: float, y: float) -> void:
	_draw_masthead_divider(W, y)

func _draw_main_layout(W: float, H: float) -> void:
	var margin = 20.0
	var col_width = (W - margin * 2 - 8) / 2.0  # 2 columns
	var y_start = 155.0
	var max_height = H - y_start - 80.0
	
	var articles = _paper_data.get("articles", [])
	if articles.is_empty():
		return
	
	var font = ThemeDB.fallback_font
	
	# LEFT COLUMN (Main story)
	if articles.size() > 0:
		var main_article = articles[0]
		var col_y = _draw_article_column(
			margin, y_start, col_width, max_height,
			main_article, true, font  # is_main = true
		)
	
	# RIGHT COLUMN (Filler stories stacked)
	if articles.size() > 1:
		var right_x = margin + col_width + 8
		var col_y = y_start
		
		for i in range(1, articles.size()):
			col_y = _draw_article_column(
				right_x, col_y, col_width, max_height - (col_y - y_start),
				articles[i], false, font  # is_main = false
			)
			col_y += 12  # Gap between articles

func _draw_article_column(
	x: float, y: float, width: float, max_height: float,
	article: Dictionary, is_main: bool,
	font: Font
) -> float:
	
	var line_height = 4.0 if is_main else 3.0
	var y_pos = y
	
	# HEADLINE (larger for main story)
	var headline_size = 18 if is_main else 13
	var headline = article.get("headline", "")
	
	# Draw headline with word wrapping
	y_pos = _draw_wrapped_text(
		x, y_pos, width,
		headline, headline_size, 1.2,  # 1.2 = line spacing multiplier
		ACCENT_COLOR, true  # bold
	) + 4
	
	# Byline
	var byline = article.get("byline", "")
	y_pos = _draw_wrapped_text(
		x, y_pos, width,
		byline, 9, 1.0,
		TEXT_COLOR, false
	) + 4
	
	# Separator line
	draw_line(Vector2(x, y_pos), Vector2(x + width, y_pos), ACCENT_COLOR, 0.5)
	y_pos += 6
	
	# Article body
	var body = article.get("body", "")
	y_pos = _draw_wrapped_text(
		x, y_pos, width,
		body, 10, 1.4,  # Justified paragraph style
		TEXT_COLOR, false
	)
	
	return y_pos

func _draw_wrapped_text(
	x: float, y: float, width: float,
	text: String, font_size: int, line_spacing: float,
	color: Color, bold: bool
) -> float:
	
	var font = ThemeDB.fallback_font
	var words = text.split(" ")
	var current_line = ""
	var line_y = y
	
	for word in words:
		var test_line = current_line + ("" if current_line.is_empty() else " ") + word
		var test_size = font.get_string_size(test_line, 0, "", font_size)
		
		if test_size.x > width and not current_line.is_empty():
			# Draw current line
			draw_string(font, Vector2(x, line_y), current_line, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			line_y += font_size * line_spacing
			current_line = word
		else:
			current_line = test_line
	
	# Draw final line
	if not current_line.is_empty():
		draw_string(font, Vector2(x, line_y), current_line,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		line_y += font_size * line_spacing
	
	return line_y

func _draw_footer(W: float, H: float) -> void:
	var y = H - 60.0
	var font = ThemeDB.fallback_font
	
	# Footer divider
	_draw_masthead_divider(W, y)
	y += 10
	
	# Small ads / continued stories indicator
	draw_string(font, Vector2(W / 2, y), 
		"— SET DOWN THE PAPER & CONTINUE —",
		HORIZONTAL_ALIGNMENT_CENTER, -1, 9, ACCENT_COLOR)
	y += 14
	
	# Page footer info
	draw_string(font, Vector2(26, y),
		"Continued on Next Page",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT_COLOR)
	
	draw_string(font, Vector2(W - 26, y),
		"All Markets Close at 4 PM EST",
		HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, TEXT_COLOR)

func _get_issue_number() -> int:
	return GameState.day % 52  # Weekly issues

# Input handling - click to close
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_requested.emit()
		get_tree().root.get_child(0).queue_free()  # Close the popup
