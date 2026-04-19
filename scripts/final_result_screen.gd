extends Node

# =========================================
# CONSTANTS
# =========================================
const COLOR_BG         = Color("#1a1a2e")
const COLOR_PANEL_DARK = Color("#2d2d3f")
const COLOR_PANEL_MID  = Color("#3d3d52")
const COLOR_ACCENT     = Color("#c8a84b")
const COLOR_PURPLE     = Color("#7c5c8a")
const COLOR_GREEN      = Color("#4a7c59")
const COLOR_RED        = Color("#8b3a3a")
const COLOR_TEXT       = Color("#e8e0d0")
const COLOR_DIM        = Color("#8a8a9a")

# Grade colors
const COLOR_S          = Color("#ffd700")
const COLOR_A          = Color("#c8a84b")
const COLOR_B          = Color("#4a7c59")
const COLOR_C          = Color("#7c5c8a")
const COLOR_D          = Color("#8b3a3a")

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer = null

# =========================================
# STATE
# =========================================
var _stats:       Dictionary  = {}
var _grade:       String      = ""
var _grade_label: String      = ""
var _score:       float       = 0.0

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_receive_data()
	_calculate_grade()
	_build_canvas()
	_build_ui()


# =========================================
# DATA
# =========================================
func _receive_data() -> void:
	_stats = DialogueManager.get_all_stats()


func _calculate_grade() -> void:
	var money      = _stats.get("money",      50.0)
	var reputation = _stats.get("reputation", 50.0)
	var morale     = _stats.get("morale",     50.0)
	var stress     = _stats.get("stress",     50.0)

	_score = (money + reputation + morale - stress) / 3.0

	if _score >= 80:
		_grade       = "S"
		_grade_label = "Business Mogul"
	elif _score >= 65:
		_grade       = "A"
		_grade_label = "Thriving Enterprise"
	elif _score >= 50:
		_grade       = "B"
		_grade_label = "Steady Business"
	elif _score >= 35:
		_grade       = "C"
		_grade_label = "Struggling Shop"
	else:
		_grade       = "D"
		_grade_label = "Barely Surviving"


func _get_grade_color() -> Color:
	match _grade:
		"S": return COLOR_S
		"A": return COLOR_A
		"B": return COLOR_B
		"C": return COLOR_C
		"D": return COLOR_D
	return COLOR_TEXT


# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas      = CanvasLayer.new()
	add_child(canvas)

	var bg      = ColorRect.new()
	bg.color    = COLOR_BG
	bg.position = Vector2(0, 0)
	bg.size     = get_viewport().get_visible_rect().size
	canvas.add_child(bg)


func _build_ui() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	var screen_h = get_viewport().get_visible_rect().size.y

	# Main panel
	var panel      = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.1, screen_h * 0.06)
	panel.size     = Vector2(screen_w * 0.8, screen_h * 0.88)
	panel.custom_minimum_size = panel.size

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color                   = COLOR_PANEL_DARK
	panel_style.border_width_top           = 3
	panel_style.border_color               = COLOR_ACCENT
	panel_style.border_width_bottom        = 2
	panel_style.border_width_left          = 2
	panel_style.border_width_right         = 2
	panel_style.corner_radius_top_left     = 0
	panel_style.corner_radius_top_right    = 0
	panel_style.corner_radius_bottom_left  = 0
	panel_style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    12)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(vbox)

	# Title
	var title                  = Label.new()
	title.text                 = "FINAL RESULTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(title)

	# Divider
	var divider               = ColorRect.new()
	divider.color             = COLOR_ACCENT
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Grade section
	var grade_container = VBoxContainer.new()
	grade_container.add_theme_constant_override("separation", 4)
	vbox.add_child(grade_container)

	var grade_header                  = Label.new()
	grade_header.text                 = "BUSINESS GRADE"
	grade_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_header.add_theme_font_size_override("font_size", 8)
	grade_header.add_theme_color_override("font_color", COLOR_DIM)
	grade_container.add_child(grade_header)

	var grade_letter                  = Label.new()
	grade_letter.text                 = _grade
	grade_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_letter.add_theme_font_size_override("font_size", 48)
	grade_letter.add_theme_color_override("font_color", _get_grade_color())
	grade_container.add_child(grade_letter)

	var grade_text                  = Label.new()
	grade_text.text                 = _grade_label.to_upper()
	grade_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_text.add_theme_font_size_override("font_size", 10)
	grade_text.add_theme_color_override("font_color", _get_grade_color())
	grade_container.add_child(grade_text)

	var score_text                  = Label.new()
	score_text.text                 = "Score: " + str(int(_score))
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text.add_theme_font_size_override("font_size", 8)
	score_text.add_theme_color_override("font_color", COLOR_DIM)
	grade_container.add_child(score_text)

	# Divider 2
	var divider2               = ColorRect.new()
	divider2.color             = COLOR_PANEL_MID
	divider2.custom_minimum_size = Vector2(0, 1)
	divider2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider2)

	# Stat rows
	var stat_defs = [
		["money",      "💰", "Money",      COLOR_ACCENT],
		["reputation", "⭐", "Reputation", COLOR_PURPLE],
		["morale",     "😊", "Morale",     COLOR_GREEN],
		["stress",     "😰", "Stress",     COLOR_RED],
	]
	for stat in stat_defs:
		vbox.add_child(_build_stat_row(stat[0], stat[1], stat[2], stat[3]))

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	# Play Again button
	var play_again = GameTheme.build_button("▸  PLAY AGAIN", true, 10)
	GameTheme.connect_button(play_again, _on_play_again_pressed)
	btn_row.add_child(play_again)

	var pa_normal = StyleBoxFlat.new()
	pa_normal.bg_color                   = COLOR_ACCENT
	pa_normal.corner_radius_top_left     = 0
	pa_normal.corner_radius_top_right    = 0
	pa_normal.corner_radius_bottom_left  = 0
	pa_normal.corner_radius_bottom_right = 0
	play_again.add_theme_stylebox_override("normal", pa_normal)

	var pa_hover = StyleBoxFlat.new()
	pa_hover.bg_color                   = COLOR_PANEL_MID
	pa_hover.border_width_top           = 2
	pa_hover.border_width_bottom        = 2
	pa_hover.border_width_left          = 2
	pa_hover.border_width_right         = 2
	pa_hover.border_color               = COLOR_ACCENT
	pa_hover.corner_radius_top_left     = 0
	pa_hover.corner_radius_top_right    = 0
	pa_hover.corner_radius_bottom_left  = 0
	pa_hover.corner_radius_bottom_right = 0
	play_again.add_theme_stylebox_override("hover", pa_hover)

	var pa_pressed = StyleBoxFlat.new()
	pa_pressed.bg_color                   = COLOR_PANEL_DARK
	pa_pressed.border_width_top           = 2
	pa_pressed.border_width_bottom        = 2
	pa_pressed.border_width_left          = 2
	pa_pressed.border_width_right         = 2
	pa_pressed.border_color               = COLOR_ACCENT
	pa_pressed.corner_radius_top_left     = 0
	pa_pressed.corner_radius_top_right    = 0
	pa_pressed.corner_radius_bottom_left  = 0
	pa_pressed.corner_radius_bottom_right = 0
	play_again.add_theme_stylebox_override("pressed", pa_pressed)

	play_again.pressed.connect(_on_play_again_pressed)
	btn_row.add_child(play_again)

	# Main Menu button
	var menu_btn = GameTheme.build_button("MENU", false, 10)
	GameTheme.connect_button(menu_btn, _on_menu_pressed)
	btn_row.add_child(menu_btn)

	var mb_normal = StyleBoxFlat.new()
	mb_normal.bg_color                   = COLOR_BG
	mb_normal.border_width_top           = 2
	mb_normal.border_width_bottom        = 2
	mb_normal.border_width_left          = 2
	mb_normal.border_width_right         = 2
	mb_normal.border_color               = COLOR_ACCENT
	mb_normal.corner_radius_top_left     = 0
	mb_normal.corner_radius_top_right    = 0
	mb_normal.corner_radius_bottom_left  = 0
	mb_normal.corner_radius_bottom_right = 0
	menu_btn.add_theme_stylebox_override("normal", mb_normal)

	var mb_hover = StyleBoxFlat.new()
	mb_hover.bg_color                   = COLOR_PANEL_MID
	mb_hover.border_width_top           = 2
	mb_hover.border_width_bottom        = 2
	mb_hover.border_width_left          = 2
	mb_hover.border_width_right         = 2
	mb_hover.border_color               = COLOR_ACCENT
	mb_hover.corner_radius_top_left     = 0
	mb_hover.corner_radius_top_right    = 0
	mb_hover.corner_radius_bottom_left  = 0
	mb_hover.corner_radius_bottom_right = 0
	menu_btn.add_theme_stylebox_override("hover", mb_hover)

	var mb_pressed = StyleBoxFlat.new()
	mb_pressed.bg_color                   = COLOR_PANEL_DARK
	mb_pressed.border_width_top           = 2
	mb_pressed.border_width_bottom        = 2
	mb_pressed.border_width_left          = 2
	mb_pressed.border_width_right         = 2
	mb_pressed.border_color               = COLOR_ACCENT
	mb_pressed.corner_radius_top_left     = 0
	mb_pressed.corner_radius_top_right    = 0
	mb_pressed.corner_radius_bottom_left  = 0
	mb_pressed.corner_radius_bottom_right = 0
	menu_btn.add_theme_stylebox_override("pressed", mb_pressed)

	menu_btn.pressed.connect(_on_menu_pressed)
	btn_row.add_child(menu_btn)


func _build_stat_row(
	stat_key:  String,
	icon:      String,
	label_txt: String,
	bar_color: Color
) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 32)

	var icon_label = Label.new()
	icon_label.text                = icon
	icon_label.custom_minimum_size = Vector2(28, 0)
	icon_label.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 14)
	row.add_child(icon_label)

	var name_label = Label.new()
	name_label.text                = label_txt.to_upper()
	name_label.custom_minimum_size = Vector2(90, 0)
	name_label.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 8)
	name_label.add_theme_color_override("font_color", COLOR_DIM)
	row.add_child(name_label)

	var bar = ProgressBar.new()
	bar.min_value             = 0
	bar.max_value             = 100
	bar.value                 = _stats.get(stat_key, 50.0)
	bar.show_percentage       = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size   = Vector2(0, 8)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color                   = bar_color
	fill_style.corner_radius_top_left     = 0
	fill_style.corner_radius_top_right    = 0
	fill_style.corner_radius_bottom_left  = 0
	fill_style.corner_radius_bottom_right = 0
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color                   = Color(1, 1, 1, 0.094)
	bg_style.corner_radius_top_left     = 0
	bg_style.corner_radius_top_right    = 0
	bg_style.corner_radius_bottom_left  = 0
	bg_style.corner_radius_bottom_right = 0
	bar.add_theme_stylebox_override("background", bg_style)
	row.add_child(bar)

	var val_label = Label.new()
	val_label.text                 = str(int(_stats.get(stat_key, 50.0)))
	val_label.custom_minimum_size  = Vector2(28, 0)
	val_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_label.add_theme_font_size_override("font_size", 9)
	val_label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(val_label)

	return row


# =========================================
# CALLBACKS
# =========================================
func _on_play_again_pressed() -> void:
	DialogueManager.reset()
	get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")


func _on_menu_pressed() -> void:
	DialogueManager.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
