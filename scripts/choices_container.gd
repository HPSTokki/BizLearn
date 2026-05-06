extends VBoxContainer

# =========================================
# SIGNALS
# =========================================
signal choice_selected(choice_index: int)

# =========================================
# CONSTANTS
# =========================================
const CHOICE_BUTTON_H = 52.0  # Increased from 44
const CHOICE_SEPARATION = 10.0  # Increased from 8
const CHOICE_WIDTH_PERCENT = 0.75  # 75% of screen width

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
	add_theme_constant_override("separation", CHOICE_SEPARATION)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Center the container
	alignment = BoxContainer.ALIGNMENT_CENTER  # Center children

func _build_button(text: String, index: int) -> PanelContainer:
	# Use secondary button style - LARGER font
	var btn = GameTheme.build_button("▶  " + text, false, 16)  # Increased from 14
	
	# Customize button appearance
	btn.custom_minimum_size = Vector2(0, CHOICE_BUTTON_H)
	
	# Left-align text with more padding
	var lbl = btn.get_child(0) as Label
	if lbl:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.add_theme_constant_override("margin_left", 16)
		lbl.add_theme_constant_override("margin_right", 8)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap long text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Add hover scale effect
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.1)
	)
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
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

	# Skip if no choices
	if choices.is_empty():
		return

	var viewport_w = get_viewport().get_visible_rect().size.x
	var viewport_h = get_viewport().get_visible_rect().size.y
	var dialogue_h = GameTheme.DIALOGUEBOX_H
	
	# Calculate total height
	var total_h = (choices.size() * CHOICE_BUTTON_H) + \
				  ((choices.size() - 1) * CHOICE_SEPARATION) + 16
	
	# Set width to 75% of screen, centered
	var button_width = viewport_w * CHOICE_WIDTH_PERCENT
	
	# Position above dialogue box
	position.y = viewport_h - dialogue_h - total_h - 12
	position.x = (viewport_w - button_width) / 2  # Center horizontally
	
	size = Vector2(button_width, total_h)
	custom_minimum_size = Vector2(button_width, total_h)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Add choices with staggered fade-in
	for i in range(choices.size()):
		var btn = _build_button(choices[i].get("text", ""), i)
		btn.custom_minimum_size = Vector2(button_width, CHOICE_BUTTON_H)  # Match container width
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.modulate = Color(1, 1, 1, 0)
		add_child(btn)
		
		# Staggered appear animation
		var tween = create_tween()
		tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.15).set_delay(i * 0.05)

	visible = true

func hide_choices() -> void:
	if get_child_count() == 0:
		visible = false
		return
		
	# Fade out animation before clearing
	var tween = create_tween()
	for child in get_children():
		tween.tween_property(child, "modulate", Color(1, 1, 1, 0), 0.1)
	
	await tween.finished
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
	GameTheme.vibrate()
	hide_choices()
	emit_signal("choice_selected", index)
	DialogueManager.advance(index)

func _on_choices_updated(_choices: Array) -> void:
	pass

func _on_dialogue_updated(_speaker: String, _text: String) -> void:
	hide_choices()
