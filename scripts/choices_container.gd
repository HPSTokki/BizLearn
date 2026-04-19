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

const DIALOGUEBOX_H     = 180.0
const BUTTON_H          = 44.0
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
	add_theme_constant_override("separation", int(GameTheme.BUTTON_SEP))


func _build_button(text: String, index: int) -> PanelContainer:
	var btn = GameTheme.build_button("▸  " + text, false)
	var lbl = btn.get_child(0) as Label
	if lbl:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.add_theme_constant_override("margin_left", 12)
	GameTheme.connect_button(btn, func(): _on_choice_pressed(index))
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
