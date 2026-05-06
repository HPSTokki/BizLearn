extends Node

# =========================================
# LEADERBOARD SCENE
# Shows pseudo-leaderboard with real + fake entries
# =========================================

var canvas: CanvasLayer = null
var screen_w: float = 0.0
var screen_h: float = 0.0
var leaderboard_container: VBoxContainer = null
var current_filter: String = ""

func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_build_canvas()
	_build_ui()

func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)
	
	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = Vector2(screen_w, screen_h)
	canvas.add_child(bg)

func _build_ui() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	var screen_h = get_viewport().get_visible_rect().size.y

	# Main panel
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.05, screen_h * 0.05)
	panel.size = Vector2(screen_w * 0.9, screen_h * 0.9)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# Header
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)
	
	var trophy_icon = Label.new()
	trophy_icon.text = "🏆"
	trophy_icon.add_theme_font_size_override("font_size", 24)
	header_row.add_child(trophy_icon)
	
	var title = Label.new()
	title.text = "GLOBAL LEADERBOARD"
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 16)
	header_row.add_child(title)
	
	var refresh_icon = Label.new()
	refresh_icon.text = "🔄"
	refresh_icon.add_theme_font_size_override("font_size", 16)
	refresh_icon.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	header_row.add_child(refresh_icon)

	# Subtitle
	var sub = Label.new()
	sub.text = "Top businesses worldwide — updated daily"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub, 8)
	vbox.add_child(sub)

	# Filter buttons
	var filter_row = HBoxContainer.new()
	filter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	filter_row.add_theme_constant_override("separation", 8)
	vbox.add_child(filter_row)
	
	var businesses = [
		{"id": "", "name": "ALL", "icon": "🌍"},
		{"id": "laundromat", "name": "LAUNDROMAT", "icon": "🫧"},
		{"id": "coffee_shop", "name": "COFFEE SHOP", "icon": "☕"},
		{"id": "flower_shop", "name": "FLOWER SHOP", "icon": "🌸"},
		{"id": "tech_startup", "name": "TECH STARTUP", "icon": "💻"},
	]
	
	for biz in businesses:
		var filter_btn = GameTheme.build_button(biz.icon + " " + biz.name, false, 9)
		filter_btn.custom_minimum_size = Vector2(90, 32)
		GameTheme.connect_button(filter_btn, func(): _set_filter(biz.id))
		filter_row.add_child(filter_btn)

	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Column headers
	var headers = HBoxContainer.new()
	headers.add_theme_constant_override("separation", 8)
	vbox.add_child(headers)
	
	var rank_h = _make_header_label("RANK", 50)
	var name_h = _make_header_label("PLAYER", 130)
	var grade_h = _make_header_label("GRADE", 60)
	var business_h = _make_header_label("BUSINESS", 100)
	var score_h = _make_header_label("SCORE", 50)
	
	headers.add_child(rank_h)
	headers.add_child(name_h)
	headers.add_child(grade_h)
	headers.add_child(business_h)
	headers.add_child(score_h)

	# Scroll container for entries
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	leaderboard_container = VBoxContainer.new()
	leaderboard_container.add_theme_constant_override("separation", 4)
	leaderboard_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(leaderboard_container)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK", false)
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)
	
	# Load initial leaderboard
	_refresh_leaderboard()

func _make_header_label(text: String, width: float) -> Label:
	var label = Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 24)
	label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(label, 8)
	return label

func _set_filter(business_id: String) -> void:
	current_filter = business_id
	_refresh_leaderboard()

func _refresh_leaderboard() -> void:
	# Clear existing
	for child in leaderboard_container.get_children():
		child.queue_free()
	
	var entries = LeaderboardManager.get_leaderboard(current_filter)
	
	for entry in entries:
		leaderboard_container.add_child(_build_leaderboard_row(entry))

func _build_leaderboard_row(entry) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 40)
	
	# Highlight player's own entries
	if entry.is_real:
		row.add_theme_stylebox_override("panel",
			GameTheme.make_pill_style("accent")
		)
	else:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		row.add_theme_stylebox_override("panel", style)
	
	# Rank
	var rank_label = Label.new()
	rank_label.text = "#" + str(entry.rank)
	rank_label.custom_minimum_size = Vector2(50, 0)
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if entry.rank <= 3:
		rank_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	else:
		rank_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(rank_label, 10)
	row.add_child(rank_label)
	
	# Player name
	var name_label = Label.new()
	var name_display = entry.player_name
	if entry.is_real:
		name_display = "★ " + name_display + " ★"
	name_label.text = name_display
	name_label.custom_minimum_size = Vector2(130, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", 
		GameTheme.get_color("accent") if entry.is_real else GameTheme.get_color("text"))
	GameTheme.apply_font(name_label, 10)
	row.add_child(name_label)
	
	# Grade
	var grade_label = Label.new()
	grade_label.text = entry.grade
	grade_label.custom_minimum_size = Vector2(60, 0)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grade_label.add_theme_color_override("font_color", _get_grade_color(entry.grade))
	GameTheme.apply_font(grade_label, 14)
	row.add_child(grade_label)
	
	# Business
	var business_label = Label.new()
	var icon = LeaderboardManager.BUSINESS_ICONS.get(entry.business_id, "🏪")
	business_label.text = icon + " " + entry.business_name
	business_label.custom_minimum_size = Vector2(100, 0)
	business_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	business_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(business_label, 9)
	row.add_child(business_label)
	
	# Score
	var score_label = Label.new()
	score_label.text = str(int(entry.score))
	score_label.custom_minimum_size = Vector2(50, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(score_label, 10)
	row.add_child(score_label)
	
	return row

func _get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color("#ffd700")
		"A": return Color("#c8a84b")
		"B": return Color("#6a9c78")
		"C": return Color("#9b6b9b")
		"D": return Color("#8b5a5a")
	return GameTheme.get_color("dim")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
