extends PanelContainer

const COLOR_BG         = Color("#1a1a2e")
const COLOR_PANEL_DARK = Color("#2d2d3f")
const COLOR_PANEL_MID  = Color("#3d3d52")
const COLOR_ACCENT     = Color("#c8a84b")
const COLOR_PURPLE     = Color("#7c5c8a")
const COLOR_GREEN      = Color("#4a7c59")
const COLOR_RED        = Color("#8b3a3a")
const COLOR_TEXT       = Color("#e8e0d0")
const COLOR_DIM        = Color("#8a8a9a")
const COLOR_WHITE_LOW  = Color(1, 1, 1, 0.094)

const HUD_HEIGHT       = 48.0
const HUD_Y            = 44.0
const BAR_SIZE         = Vector2(60, 8)

var stat_bars: Dictionary = {}

# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass

func setup() -> void:
	_apply_panel_style()
	_build_hud()
	_connect_signals()

func _apply_panel_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color            = COLOR_PANEL_DARK
	style.border_width_bottom = 2
	style.border_color        = COLOR_ACCENT
	style.border_width_top    = 0
	style.border_width_left   = 0
	style.border_width_right  = 0
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	add_theme_stylebox_override("panel", style)
	# NO anchors here — DialogueScene owns positioning
	print("StatsHUD style applied | pos: ", position, " | size: ", size)

func _build_hud() -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment             = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	# Define each stat: [display_name, icon, bar_color, stat_key]
	var stat_defs = [
		["Money",      "$", COLOR_ACCENT,  "money"],
		["Reputation", "Rep", COLOR_PURPLE,  "reputation"],
		["Morale",     "Morale", COLOR_GREEN,   "morale"],
		["Stress",     "Stress", COLOR_RED,     "stress"],
	]

	for stat in stat_defs:
		var row = _build_stat_row(stat[0], stat[1], stat[2], stat[3])
		hbox.add_child(row)
	print("StatsHUD children: ")
	for child in get_children():
		print(" - ", child.get_class(), " | pos: ", child.position, " | size: ", child.size)


func _build_stat_row(
	_display_name: String,
	icon: String,
	bar_color: Color,
	stat_key: String
) -> HBoxContainer:

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	# Icon
	var label = Label.new()
	label.text = icon
	label.add_theme_font_size_override("font_size", 12)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	# Bar
	var bar = ProgressBar.new()
	bar.custom_minimum_size  = BAR_SIZE
	bar.size_flags_vertical  = Control.SIZE_SHRINK_CENTER
	bar.show_percentage      = false
	bar.min_value            = 0.0
	bar.max_value            = 100.0
	bar.value                = 50.0

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color                    = bar_color
	fill_style.corner_radius_top_left      = 0
	fill_style.corner_radius_top_right     = 0
	fill_style.corner_radius_bottom_left   = 0
	fill_style.corner_radius_bottom_right  = 0
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color                    = COLOR_WHITE_LOW
	bg_style.corner_radius_top_left      = 0
	bg_style.corner_radius_top_right     = 0
	bg_style.corner_radius_bottom_left   = 0
	bg_style.corner_radius_bottom_right  = 0
	bar.add_theme_stylebox_override("background", bg_style)

	row.add_child(bar)

	# Store reference for update_stat()
	stat_bars[stat_key] = bar

	return row


func _connect_signals() -> void:
	DialogueManager.stats_changed.connect(_on_stats_changed)

func update_stat(stat_name: String, new_value: float) -> void:
	if not stat_bars.has(stat_name):
		push_warning("StatsHUD: Unknown stat " + stat_name)
		return

	var bar = stat_bars[stat_name]
	var tween = create_tween()
	tween.tween_property(bar, "value", new_value, 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUART)

func _on_stats_changed(stat_name: String, new_value: float) -> void:
	update_stat(stat_name, new_value)
