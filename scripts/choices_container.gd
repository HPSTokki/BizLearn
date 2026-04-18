extends VBoxContainer

# =========================================
# SIGNALS
# =========================================
signal choice_selected(choice_index: int)

# =========================================
# CONSTANTS
# =========================================
const COLOR_BG         = Color("#1a1a2e")
const COLOR_PANEL_DARK = Color("#2d2d3f")
const COLOR_PANEL_MID  = Color("#3d3d52")
const COLOR_ACCENT     = Color("#c8a84b")
const COLOR_TEXT       = Color("#e8e0d0")
const COLOR_DIM        = Color("#8a8a9a")

const DIALOGUEBOX_H     = 160.0
const BUTTON_H          = 38.0
const BUTTON_SEPARATION = 6.0

# =========================================
# STATE
# =========================================
var _current_choices: Array = []

# =========================================
# LIFECYCLE
# =========================================
func setup() -> void:
	_apply_container_style()
	_connect_signals()
	visible = false


# =========================================
# BUILD
# =========================================
func _apply_container_style() -> void:
	add_theme_constant_override("separation", int(BUTTON_SEPARATION))


func _build_button(text: String, index: int) -> Button:
	var btn = Button.new()
	btn.text                  = "▸  " + text
	btn.custom_minimum_size   = Vector2(0, BUTTON_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment             = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 9)

	btn.add_theme_color_override("font_color",         COLOR_DIM)
	btn.add_theme_color_override("font_color_hover",   COLOR_TEXT)
	btn.add_theme_color_override("font_color_pressed", COLOR_TEXT)
	btn.add_theme_color_override("font_color_focus",   COLOR_TEXT)

	var normal = StyleBoxFlat.new()
	normal.bg_color                   = COLOR_BG
	normal.border_width_top           = 2
	normal.border_width_bottom        = 2
	normal.border_width_left          = 2
	normal.border_width_right         = 2
	normal.border_color               = COLOR_PANEL_MID
	normal.corner_radius_top_left     = 0
	normal.corner_radius_top_right    = 0
	normal.corner_radius_bottom_left  = 0
	normal.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color                   = COLOR_PANEL_DARK
	hover.border_width_top           = 2
	hover.border_width_bottom        = 2
	hover.border_width_left          = 2
	hover.border_width_right         = 2
	hover.border_color               = COLOR_ACCENT
	hover.corner_radius_top_left     = 0
	hover.corner_radius_top_right    = 0
	hover.corner_radius_bottom_left  = 0
	hover.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color                   = COLOR_PANEL_MID
	pressed.border_width_top           = 2
	pressed.border_width_bottom        = 2
	pressed.border_width_left          = 2
	pressed.border_width_right         = 2
	pressed.border_color               = COLOR_ACCENT
	pressed.corner_radius_top_left     = 0
	pressed.corner_radius_top_right    = 0
	pressed.corner_radius_bottom_left  = 0
	pressed.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("pressed", pressed)

	var focus = StyleBoxFlat.new()
	focus.bg_color                   = COLOR_PANEL_DARK
	focus.border_width_top           = 2
	focus.border_width_bottom        = 2
	focus.border_width_left          = 2
	focus.border_width_right         = 2
	focus.border_color               = COLOR_ACCENT
	focus.corner_radius_top_left     = 0
	focus.corner_radius_top_right    = 0
	focus.corner_radius_bottom_left  = 0
	focus.corner_radius_bottom_right = 0
	btn.add_theme_stylebox_override("focus", focus)

	btn.pressed.connect(_on_choice_pressed.bind(index))
	return btn


# =========================================
# SIGNALS
# =========================================
func _connect_signals() -> void:
	if DialogueManager.choices_updated.is_connected(_on_choices_updated):
		return
	if DialogueManager.dialogue_updated.is_connected(_on_dialogue_updated):
		return
	DialogueManager.choices_updated.connect(_on_choices_updated)
	DialogueManager.dialogue_updated.connect(_on_dialogue_updated)


# =========================================
# PUBLIC
# =========================================
func show_choices(choices: Array) -> void:
	_current_choices = choices
	_clear_buttons()

	var total_h = (choices.size() * BUTTON_H) + \
				  ((choices.size() - 1) * BUTTON_SEPARATION)

	position.y = get_viewport().get_visible_rect().size.y - DIALOGUEBOX_H - total_h
	size       = Vector2(get_viewport().get_visible_rect().size.x, total_h)

	for i in range(choices.size()):
		add_child(_build_button(choices[i].get("text", ""), i))

	visible = true


func hide_choices() -> void:
	_clear_buttons()
	_current_choices = []
	visible = false


# =========================================
# PRIVATE
# =========================================
func _clear_buttons() -> void:
	for child in get_children():
		child.queue_free()


# =========================================
# CALLBACKS
# =========================================
func _on_choice_pressed(index: int) -> void:
	hide_choices()
	emit_signal("choice_selected", index)
	DialogueManager.advance(index)


func _on_choices_updated(_choices: Array) -> void:
	pass


func _on_dialogue_updated(_speaker: String, _text: String) -> void:
	hide_choices()
