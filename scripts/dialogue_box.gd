extends PanelContainer

# =========================================
# SIGNALS
# =========================================
signal dialogue_finished

# =========================================
# CONSTANTS
# =========================================
const COLOR_PANEL_DARK = Color("#2d2d3f")
const COLOR_ACCENT     = Color("#c8a84b")
const COLOR_TEXT       = Color("#e8e0d0")

const TYPEWRITER_SPEED = 0.03

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
var _skip_cooldown:    bool = false

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
	var style = StyleBoxFlat.new()
	style.bg_color            = COLOR_PANEL_DARK
	style.border_width_top    = 3
	style.border_color        = COLOR_ACCENT
	style.border_width_bottom = 0
	style.border_width_left   = 0
	style.border_width_right  = 0
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	add_theme_stylebox_override("panel", style)


func _build_dialogue_box() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left",   14)
	vbox.add_theme_constant_override("margin_right",  14)
	vbox.add_theme_constant_override("margin_top",    14)
	vbox.add_theme_constant_override("margin_bottom", 14)
	add_child(vbox)

	speaker_name = Label.new()
	speaker_name.text = ""
	speaker_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speaker_name.add_theme_font_size_override("font_size", 8)
	speaker_name.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(speaker_name)

	dialogue_text = RichTextLabel.new()
	dialogue_text.bbcode_enabled        = true
	dialogue_text.scroll_active         = false
	dialogue_text.custom_minimum_size   = Vector2(0, 72)
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_font_size_override("normal_font_size", 11)
	dialogue_text.add_theme_color_override("default_color", COLOR_TEXT)
	vbox.add_child(dialogue_text)

	next_indicator = Label.new()
	next_indicator.text                  = "▼ tap to continue"
	next_indicator.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	next_indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_indicator.add_theme_font_size_override("font_size", 8)
	next_indicator.add_theme_color_override("font_color", COLOR_ACCENT)
	next_indicator.visible               = false
	next_indicator.modulate.a            = 0.0
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

	next_indicator.visible    = false
	next_indicator.modulate.a = 0.0
	speaker_name.text         = speaker.to_upper()
	dialogue_text.text        = text
	dialogue_text.visible_characters = 0

	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(
		dialogue_text,
		"visible_characters",
		len(text),
		len(text) * TYPEWRITER_SPEED
	).set_ease(Tween.EASE_IN_OUT)\
	 .set_trans(Tween.TRANS_LINEAR)
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
		# Brief cooldown so the same tap doesnt
		# immediately advance after skipping
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
	next_indicator.visible    = false
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
