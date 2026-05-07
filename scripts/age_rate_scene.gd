extends Node

# =========================================
# SIMPLE AGE GATE - Monogram-Friendly, Centered
# =========================================

var canvas: CanvasLayer = null
var screen_w: float = 0.0
var screen_h: float = 0.0
var age_input: LineEdit = null
var error_label: Label = null

func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_build_ui()

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = Vector2(screen_w, screen_h)
	canvas.add_child(bg)

	# Center container for the whole panel
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(screen_w * 0.7, screen_h * 0.5)
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "AGE VERIFICATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 14)
	vbox.add_child(title)

	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Description
	var desc = Label.new()
	desc.text = "Enter your age to continue"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 10)
	vbox.add_child(desc)

	# Age input - centered
	var input_center = CenterContainer.new()
	input_center.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(input_center)

	age_input = LineEdit.new()
	age_input.placeholder_text = "Age"
	age_input.text = ""
	age_input.max_length = 3
	age_input.custom_minimum_size = Vector2(100, 40)
	age_input.add_theme_font_size_override("font_size", 18)
	age_input.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	age_input.add_theme_stylebox_override("normal",
		GameTheme.make_panel_style("mid", 1)
	)
	age_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_center.add_child(age_input)

	# Number pad
	var number_pad = GridContainer.new()
	number_pad.columns = 3
	number_pad.add_theme_constant_override("h_separation", 6)
	number_pad.add_theme_constant_override("v_separation", 4)
	number_pad.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(number_pad)

	# Number buttons 1-9
	for i in range(1, 10):
		var btn = _build_small_button(str(i))
		GameTheme.connect_button(btn, func(): _append_number(str(i)))
		number_pad.add_child(btn)
	
	# 0 button
	var zero_btn = _build_small_button("0")
	GameTheme.connect_button(zero_btn, func(): _append_number("0"))
	number_pad.add_child(zero_btn)

	# Backspace button
	var back_btn = _build_small_button("⌫")
	GameTheme.connect_button(back_btn, _backspace)
	number_pad.add_child(back_btn)

	# Error label
	error_label = Label.new()
	error_label.text = ""
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	GameTheme.apply_font(error_label, 9)
	error_label.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(error_label)

	# Confirm button
	var confirm_btn = GameTheme.build_button("CONTINUE", true, 12)
	confirm_btn.custom_minimum_size = Vector2(screen_w * 0.4, 38)
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(confirm_btn, _on_confirm)
	vbox.add_child(confirm_btn)

func _build_small_button(text: String) -> PanelContainer:
	var btn = GameTheme.build_button(text, false, 12)
	btn.custom_minimum_size = Vector2(36, 36)
	return btn

func _append_number(num: String) -> void:
	var current = age_input.text
	if current.length() < 3:
		age_input.text = current + num

func _backspace() -> void:
	var current = age_input.text
	if current.length() > 0:
		age_input.text = current.substr(0, current.length() - 1)

func _on_confirm() -> void:
	var age_text = age_input.text.strip_edges()
	
	if age_text.is_empty():
		error_label.text = "Enter your age"
		return
	
	var age = age_text.to_int()
	
	if age <= 0 or age > 120:
		error_label.text = "Enter valid age (1-120)"
		return
	
	_save_age(age)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _save_age(age: int) -> void:
	var config = ConfigFile.new()
	config.load("user://user_data.cfg")
	config.set_value("User", "age", age)
	config.set_value("User", "age_set", true)
	config.set_value("User", "date_set", Time.get_datetime_dict_from_system())
	config.save("user://user_data.cfg")
	
	print("Age saved: ", age)
