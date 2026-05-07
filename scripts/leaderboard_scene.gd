extends Node

# =========================================
# LEADERBOARD SCENE - Ultra Compact Double Row
# Shows leaderboard for current business only
# =========================================

var canvas: CanvasLayer = null
var screen_w: float = 0.0
var screen_h: float = 0.0
var leaderboard_grid: GridContainer = null
var current_business_id: String = "laundromat"

func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	current_business_id = SaveManager.get_active_business_id()
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
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.02, screen_h * 0.02)
	panel.size = Vector2(screen_w * 0.96, screen_h * 0.92)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(vbox)

	# Header
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 4)
	vbox.add_child(header_row)
	
	var trophy_icon = Label.new()
	trophy_icon.text = "🏆"
	trophy_icon.add_theme_font_size_override("font_size", 14)
	header_row.add_child(trophy_icon)
	
	var title = Label.new()
	title.text = "LEADERBOARD"
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 28)
	header_row.add_child(title)

	# Business badge
	var business_name = LeaderboardManager.BUSINESS_NAMES.get(current_business_id, "Laundromat")
	var business_icon = LeaderboardManager.BUSINESS_ICONS.get(current_business_id, "🫧")
	
	var biz_badge = PanelContainer.new()
	biz_badge.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("accent")
	)
	biz_badge.custom_minimum_size = Vector2(0, 18)
	biz_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(biz_badge)
	
	var biz_row = HBoxContainer.new()
	biz_row.alignment = BoxContainer.ALIGNMENT_CENTER
	biz_row.add_theme_constant_override("separation", 3)
	biz_badge.add_child(biz_row)
	
	var biz_icon = Label.new()
	biz_icon.text = business_icon
	biz_icon.add_theme_font_size_override("font_size", 9)
	biz_row.add_child(biz_icon)
	
	var biz_name = Label.new()
	biz_name.text = business_name
	biz_name.add_theme_color_override("font_color", GameTheme.get_color("bg"))
	GameTheme.apply_font(biz_name, 18)
	biz_row.add_child(biz_name)

	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# 2-COLUMN GRID for entries
	leaderboard_grid = GridContainer.new()
	leaderboard_grid.columns = 2
	leaderboard_grid.add_theme_constant_override("h_separation", 8)
	leaderboard_grid.add_theme_constant_override("v_separation", 4)
	leaderboard_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(leaderboard_grid)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK", true, 24)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.25, 35)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)
	
	_refresh_leaderboard()

func _refresh_leaderboard() -> void:
	for child in leaderboard_grid.get_children():
		child.queue_free()
	
	var entries = LeaderboardManager.get_leaderboard(current_business_id)
	var top_entries = entries.slice(0, min(12, entries.size()))
	
	for entry in top_entries:
		leaderboard_grid.add_child(_build_leaderboard_card(entry))
	
	if top_entries.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No entries yet"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(empty_label, 18)
		leaderboard_grid.add_child(empty_label)

func _build_leaderboard_card(entry) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 20)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 1)
	)
	
	# Highlight player's own entries
	if entry.is_real:
		var highlight = StyleBoxFlat.new()
		highlight.bg_color = Color(GameTheme.get_color("accent").r, GameTheme.get_color("accent").g, GameTheme.get_color("accent").b, 0.12)
		highlight.border_width_top = 1
		highlight.border_width_bottom = 1
		highlight.border_width_left = 1
		highlight.border_width_right = 1
		highlight.border_color = GameTheme.get_color("accent")
		highlight.corner_radius_top_left = 6
		highlight.corner_radius_top_right = 6
		highlight.corner_radius_bottom_left = 6
		highlight.corner_radius_bottom_right = 6
		card.add_theme_stylebox_override("panel", highlight)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	vbox.add_theme_constant_override("margin_left", 6)
	vbox.add_theme_constant_override("margin_right", 6)
	vbox.add_theme_constant_override("margin_top", 4)
	vbox.add_theme_constant_override("margin_bottom", 4)
	card.add_child(vbox)

	# Row 1: Rank + Name
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 4)
	vbox.add_child(top_row)
	
	# Rank with medal for top 3
	var rank_label = Label.new()
	if entry.rank <= 3:
		var medals = ["🥇", "🥈", "🥉"]
		rank_label.text = medals[entry.rank - 1]
		rank_label.add_theme_font_size_override("font_size", 11)
	else:
		rank_label.text = "#" + str(entry.rank)
		rank_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(rank_label, 15)
	rank_label.custom_minimum_size = Vector2(28, 0)
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(rank_label)
	
	# Player name with star for real player
	var name_label = Label.new()
	var name_display = entry.player_name
	if entry.is_real:
		name_display = "★ " + name_display
	# Truncate long names
	if len(name_display) > 12:
		name_display = name_display.substr(0, 10) + ".."
	name_label.text = name_display
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", 
		GameTheme.get_color("accent") if entry.is_real else GameTheme.get_color("text"))
	GameTheme.apply_font(name_label, 16)
	top_row.add_child(name_label)

	# Row 2: Grade + Score
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 6)
	vbox.add_child(bottom_row)
	
	# Grade badge
	var grade_container = PanelContainer.new()
	grade_container.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("accent")
	)
	var grade_color = _get_grade_color(entry.grade)
	var grade_style = StyleBoxFlat.new()
	grade_style.bg_color = grade_color
	grade_style.corner_radius_top_left = 8
	grade_style.corner_radius_top_right = 8
	grade_style.corner_radius_bottom_left = 8
	grade_style.corner_radius_bottom_right = 8
	grade_style.content_margin_left = 6
	grade_style.content_margin_right = 6
	grade_container.add_theme_stylebox_override("panel", grade_style)
	grade_container.custom_minimum_size = Vector2(28, 10)
	
	var grade_label = Label.new()
	grade_label.text = entry.grade
	grade_label.add_theme_color_override("font_color", GameTheme.get_color("bg"))
	GameTheme.apply_font(grade_label, 16)
	grade_container.add_child(grade_label)
	bottom_row.add_child(grade_container)
	
	# Score
	var score_label = Label.new()
	score_label.text = str(int(entry.score)) + " pts"
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(score_label, 15)
	bottom_row.add_child(score_label)
	
	return card

func _get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color("#ffd700")
		"A": return Color("#c8a84b")
		"B": return Color("#6a9c78")
		"C": return Color("#9b6b9b")
		"D": return Color("#8b5a5a")
	return GameTheme.get_color("accent")

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
