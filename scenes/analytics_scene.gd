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
const COLOR_POS        = Color("#4a7c59")
const COLOR_NEG        = Color("#8b3a3a")

const TOTAL_DAYS       = 5

# =========================================
# REFERENCES
# =========================================
var canvas:      CanvasLayer        = null
var next_button: PanelContainer     = null

# =========================================
# STATE
# =========================================
var _current_day:   int        = 1
var _stat_deltas:   Dictionary = {}
var _current_stats: Dictionary = {}

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_receive_data()
	_build_canvas()
	_build_ui()


# =========================================
# DATA
# =========================================
func _receive_data() -> void:
	_current_day   = DialogueManager.get_current_day()
	_stat_deltas   = DialogueManager.get_stat_deltas()
	_current_stats = DialogueManager.get_all_stats()


# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas       = CanvasLayer.new()
	add_child(canvas)

	var bg       = ColorRect.new()
	bg.color     = COLOR_BG
	bg.position  = Vector2(0, 0)
	bg.size      = get_viewport().get_visible_rect().size
	canvas.add_child(bg)


func _build_ui() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	var screen_h = get_viewport().get_visible_rect().size.y

	var panel      = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.1, screen_h * 0.08)
	panel.size     = Vector2(screen_w * 0.8, screen_h * 0.84)
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
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
		)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    16)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    24)
	vbox.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(vbox)

	# Title
	var title                      = Label.new()
	title.text                     = "DAY " + str(_current_day) + " COMPLETE"
	title.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(title)

	# Divider
	var divider             = ColorRect.new()
	divider.color           = COLOR_ACCENT
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

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

	# Next button
	next_button = GameTheme.build_button(
		"SEE FINAL RESULTS" if _current_day >= TOTAL_DAYS else "NEXT DAY  ▸",
		true,
		11
	)
	GameTheme.connect_button(next_button, _on_next_pressed)
	vbox.add_child(next_button)


func _build_stat_row(
	stat_key:  String,
	icon:      String,
	label_txt: String,
	bar_color: Color
) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 36)

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

	var delta       = _stat_deltas.get(stat_key, 0.0)
	var delta_label = Label.new()
	delta_label.text                 = ("+" if delta >= 0 else "") + str(int(delta))
	delta_label.custom_minimum_size  = Vector2(48, 0)
	delta_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	delta_label.add_theme_font_size_override("font_size", 10)
	delta_label.add_theme_color_override(
		"font_color",
		COLOR_POS if delta >= 0 else COLOR_NEG
	)
	row.add_child(delta_label)

	var bar = ProgressBar.new()
	bar.min_value             = 0
	bar.max_value             = 100
	bar.value                 = _current_stats.get(stat_key, 50.0)
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
	val_label.text                 = str(int(_current_stats.get(stat_key, 50.0)))
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
func _on_next_pressed() -> void:
	if _current_day >= TOTAL_DAYS:
		get_tree().change_scene_to_file("res://scenes/final_result_screen.tscn")
	else:
		DialogueManager.load_next_day()
		get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")
