extends PanelContainer

# =========================================
# SIGNALS
# =========================================
signal dialogue_finished

# =========================================
# REFERENCES
# =========================================
var speaker_name:   Label         = null
var dialogue_text:  RichTextLabel = null
var next_indicator: Label         = null

# =========================================
# STATE
# =========================================
var _is_typing:        bool   = false
var _full_text:        String = ""
var _pulse_tween:      Tween  = null
var _typewriter_tween: Tween  = null
var _initialized:      bool   = false
var _skip_cooldown:    bool   = false

# =========================================
# LIFECYCLE
# =========================================
func setup() -> void:
	if _initialized:
		return
	_initialized = true
	_apply_panel_style()
	_build_dialogue_box()
	_connect_signals()

# =========================================
# BUILD
# =========================================
func _apply_panel_style() -> void:
	add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	custom_minimum_size = Vector2(0, 0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _build_dialogue_box() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left",   12)
	vbox.add_theme_constant_override("margin_right",  12)
	vbox.add_theme_constant_override("margin_top",    8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	add_child(vbox)

	# Speaker name only (no portrait box anymore)
	speaker_name = Label.new()
	speaker_name.text = ""
	speaker_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speaker_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker_name.add_theme_font_size_override("font_size", 14)
	speaker_name.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(speaker_name, 14)
	vbox.add_child(speaker_name)

	# Dialogue text area
	dialogue_text = RichTextLabel.new()
	dialogue_text.bbcode_enabled = true
	dialogue_text.scroll_active = false
	dialogue_text.fit_content = true
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.custom_minimum_size = Vector2(0, 50)
	dialogue_text.add_theme_font_size_override("normal_font_size", 16)
	dialogue_text.add_theme_color_override("default_color", GameTheme.get_color("text"))
	GameTheme.apply_font_rich(dialogue_text, 16)
	vbox.add_child(dialogue_text)

	# Next indicator
	next_indicator = Label.new()
	next_indicator.text = "▼"
	next_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	next_indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_indicator.add_theme_font_size_override("font_size", 8)
	next_indicator.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	next_indicator.visible = false
	next_indicator.modulate.a = 0.0
	vbox.add_child(next_indicator)

# =========================================
# SIGNALS
# =========================================
func _connect_signals() -> void:
	if DialogueManager.dialogue_updated.is_connected(_on_dialogue_updated):
		return
	DialogueManager.dialogue_updated.connect(_on_dialogue_updated)

# =========================================
# PUBLIC
# =========================================
func show_dialogue(speaker: String, text: String) -> void:
	if next_indicator == null or speaker_name == null or dialogue_text == null:
		push_error("DialogueBox: internal nodes not ready")
		return
	
	_is_typing = true
	_full_text = text

	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	next_indicator.visible = false
	next_indicator.modulate.a = 0.0
	speaker_name.text = speaker
	dialogue_text.text = text
	dialogue_text.visible_characters = 0

	if text.length() == 0:
		_on_typewriter_finished()
		return

	_typewriter_tween = create_tween()
	var duration = len(text) * GameTheme.get_text_speed()
	_typewriter_tween.tween_property(
		dialogue_text,
		"visible_characters",
		len(text),
		max(duration, 0.1)
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	_typewriter_tween.finished.connect(_on_typewriter_finished)

func skip_typing() -> void:
	if not _is_typing:
		return
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	dialogue_text.visible_characters = len(_full_text)
	_on_typewriter_finished()

func on_screen_tapped() -> void:
	if _skip_cooldown:
		return
	if _is_typing:
		skip_typing()
		_skip_cooldown = true
		await get_tree().create_timer(0.15).timeout
		_skip_cooldown = false
	else:
		if _skip_cooldown:
			return
		DialogueManager.advance()

# =========================================
# PRIVATE
# =========================================
func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	next_indicator.visible = true
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(next_indicator, "modulate:a", 0.0, 0.6)
	_pulse_tween.tween_property(next_indicator, "modulate:a", 1.0, 0.6)

func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	next_indicator.visible = false
	next_indicator.modulate.a = 0.0

# =========================================
# CALLBACKS
# =========================================
func _on_typewriter_finished() -> void:
	_is_typing = false
	_start_pulse()
	emit_signal("dialogue_finished")

func _on_dialogue_updated(speaker: String, text: String) -> void:
	show_dialogue(speaker, text)
