extends PanelContainer

# =========================================
# CONSTANTS
# =========================================
const COLOR_PANEL_DARK = Color("#2d2d3f")
const COLOR_ACCENT     = Color("#c8a84b")
const COLOR_PURPLE     = Color("#7c5c8a")
const COLOR_GREEN      = Color("#4a7c59")
const COLOR_RED        = Color("#8b3a3a")
const COLOR_WHITE_LOW  = Color(1, 1, 1, 0.094)

const BAR_SIZE         = Vector2(60, 8)

# =========================================
# REFERENCES
# =========================================
var stat_bars: Dictionary = {}

# =========================================
# LIFECYCLE
# =========================================

func _ready() -> void:
	pass

func setup() -> void:
	_apply_panel_style()
	_build_hud()
	_connect_signals()


# =========================================
# BUILD
# =========================================
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


func _build_hud() -> void:
	# Panel style from Theme
	add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", 2)
	)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment             = BoxContainer.ALIGNMENT_CENTER
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)

	var stat_defs = [
		["money",      "💰", "money"],
		["reputation", "⭐", "reputation"],
		["morale",     "😊", "morale"],
		["stress",     "😰", "stress"],
	]
	for stat in stat_defs:
		hbox.add_child(_build_stat_row(stat[0], stat[1], stat[2]))


func _build_stat_row(
	_display_name: String,
	icon:          String,
	stat_key:      String
) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var label = Label.new()
	label.text = icon
	GameTheme.apply_font(label, 12)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var bar = ProgressBar.new()
	bar.custom_minimum_size = GameTheme.BAR_SIZE
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage     = false
	bar.min_value           = 0.0
	bar.max_value           = 100.0
	bar.value               = 50.0
	bar.add_theme_stylebox_override("fill",       GameTheme.make_bar_fill_style(stat_key))
	bar.add_theme_stylebox_override("background", GameTheme.make_bar_bg_style())
	row.add_child(bar)

	stat_bars[stat_key] = bar
	return row


# =========================================
# SIGNALS
# =========================================
func _connect_signals() -> void:
	if DialogueManager.stats_changed.is_connected(_on_stats_changed):
		return
	DialogueManager.stats_changed.connect(_on_stats_changed)


# =========================================
# PUBLIC
# =========================================
func update_stat(stat_name: String, new_value: float) -> void:
	if not stat_bars.has(stat_name):
		push_warning("StatsHUD: Unknown stat " + stat_name)
		return
	var bar   = stat_bars[stat_name]
	var tween = create_tween()
	tween.tween_property(bar, "value", new_value, 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_QUART)


# =========================================
# CALLBACKS
# =========================================
func _on_stats_changed(stat_name: String, new_value: float) -> void:
	update_stat(stat_name, new_value)
