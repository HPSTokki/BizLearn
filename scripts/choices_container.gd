extends VBoxContainer

# =========================================
# SIGNALS
# =========================================
signal choice_selected(choice_index: int)

# =========================================
# CONSTANTS
# =========================================
const CHOICE_BUTTON_H = 52.0
const CHOICE_SEPARATION = 10.0
const CHOICE_WIDTH_PERCENT = 0.85
const BOTTOM_PADDING = 16

# =========================================
# STATE
# =========================================
var _current_choices: Array = []
var _is_hiding: bool = false
var _is_showing: bool = false
var _last_choice_time: float = 0.0
const CHOICE_COOLDOWN: float = 0.3

# =========================================
# LIFECYCLE
# =========================================
func setup() -> void:
	_apply_container_style()
	_connect_signals()
	visible = false

func _apply_container_style() -> void:
	add_theme_constant_override("separation", CHOICE_SEPARATION)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	alignment = BoxContainer.ALIGNMENT_CENTER

func _build_button(text: String, index: int) -> PanelContainer:
	var btn = GameTheme.build_button("▶  " + text, false, 16)
	
	btn.custom_minimum_size = Vector2(0, CHOICE_BUTTON_H)
	
	var lbl = btn.get_child(0) as Label
	if lbl:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.add_theme_constant_override("margin_left", 16)
		lbl.add_theme_constant_override("margin_right", 8)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.01, 1.01), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	GameTheme.connect_button(btn, func(): _on_choice_pressed(index))
	return btn

func _connect_signals() -> void:
	if DialogueManager.choices_updated.is_connected(_on_choices_updated):
		return
	if DialogueManager.dialogue_updated.is_connected(_on_dialogue_updated):
		return
	DialogueManager.choices_updated.connect(_on_choices_updated)
	DialogueManager.dialogue_updated.connect(_on_dialogue_updated)

func show_choices(choices: Array) -> void:
	# CRITICAL GUARD: Check if the current node actually has choices
	var current_node = DialogueManager.get_current_node()
	var current_choices = current_node.get("choices", [])
	
	if current_choices.is_empty():
		print("Current node has no choices - BLOCKING show_choices")
		return
	
	print("=== show_choices called with ", choices.size(), " choices ===")
	_is_showing = false
	_is_hiding = false
	
	print("=== show_choices called with ", choices.size(), " choices ===")
	_current_choices = choices
	_clear_buttons()

	if choices.is_empty():
		return

	var viewport_w = get_viewport().get_visible_rect().size.x
	var viewport_h = get_viewport().get_visible_rect().size.y
	var dialogue_h = GameTheme.DIALOGUEBOX_H
	
	var total_h = (choices.size() * CHOICE_BUTTON_H) + ((choices.size() - 1) * CHOICE_SEPARATION)
	var button_width = viewport_w * CHOICE_WIDTH_PERCENT
	
	var bottom_y = viewport_h - dialogue_h - BOTTOM_PADDING
	position.y = bottom_y - total_h
	position.x = (viewport_w - button_width) / 2
	
	size = Vector2(button_width, total_h)
	custom_minimum_size = Vector2(button_width, total_h)
	
	for i in range(choices.size()):
		var btn = _build_button(choices[i].get("text", ""), i)
		btn.custom_minimum_size = Vector2(button_width, CHOICE_BUTTON_H)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.modulate = Color(1, 1, 1, 0)
		add_child(btn)
		
		var tween = create_tween()
		tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(i * 0.05)

	visible = true
	_is_showing = true
	print("Choices visible set to true")

func hide_choices() -> void:
	if _is_hiding:
		return
	_is_hiding = true
	
	print("=== hide_choices called ===")
	
	if get_child_count() == 0:
		visible = false
		_is_hiding = false
		_is_showing = false
		return
		
	var tween = create_tween()
	for child in get_children():
		tween.tween_property(child, "modulate", Color(1, 1, 1, 0), 0.1)
	
	await tween.finished
	_clear_buttons()
	_current_choices = []
	visible = false
	_is_hiding = false
	_is_showing = false

func _clear_buttons() -> void:
	for child in get_children():
		child.queue_free()

func _on_choice_pressed(index: int) -> void:
	# Throttle rapid choice taps
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_choice_time < CHOICE_COOLDOWN:
		print("Choice cooldown - ignoring tap")
		return
	_last_choice_time = current_time
	
	print("=== CHOICE PRESSED: index ", index, " ===")
	if index < _current_choices.size():
		print("Choice text: ", _current_choices[index].get("text", ""))
	
	AudioManager.play_sfx("click")
	
	GameTheme.vibrate()
	hide_choices()
	emit_signal("choice_selected", index)
	
	print("Calling DialogueManager.advance with index: ", index)
	DialogueManager.advance(index)

func _on_choices_updated(choices: Array) -> void:
	print("=== choices_updated signal received with ", choices.size(), " choices ===")
	
	# Get the current node and its expected choices
	var current_node = DialogueManager.get_current_node()
	var current_node_id = DialogueManager.get_current_node_id()
	var current_choices = current_node.get("choices", [])
	
	print("Current node: ", current_node_id)
	print("Current node has ", current_choices.size(), " choices")
	
	# CRITICAL: If the current node doesn't have choices, ignore ALL signals
	if current_choices.is_empty():
		print("Current node has no choices - ignoring stale signal")
		return
	
	# Also check if the choices array matches what the current node expects
	# This prevents showing choices from previous nodes
	if choices.is_empty():
		print("Ignoring empty choices")
		return
	
	# Force hide any existing choices before showing new ones
	if visible:
		print("Force hiding existing choices")
		hide_choices()
		await get_tree().create_timer(0.1).timeout
	
	show_choices(choices)

func _on_dialogue_updated(_speaker: String, _text: String) -> void:
	print("Dialogue updated: ", _speaker, " - ", _text.substr(0, 30))
	# Only hide if visible
	if visible:
		print("Hiding choices due to dialogue update")
		hide_choices()
