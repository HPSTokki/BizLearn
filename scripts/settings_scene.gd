extends Node

# =========================================
# SETTINGS SCENE - Compact & Mobile-Friendly
# =========================================

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0
var content_area: VBoxContainer = null
var tab_buttons:  Array         = []
var active_tab:   int           = 0

# =========================================
# SETTINGS STATE
# =========================================
var settings: Dictionary = {
	"master_volume": 100,
	"music_volume":  80,
	"sfx_volume":    100,
	"vibration":     true,
	"text_speed":    1,
	"language":      0,
	"notifications": true,
	"text_size":     1,
	"high_contrast": false,
	"show_fps":      false,
}

const BUS_MASTER = "Master"
const BUS_MUSIC  = "Music"
const BUS_SFX    = "SFX"

const TEXT_SPEEDS = [0.06, 0.03, 0.01]
const TEXT_SPEED_LABELS = ["SLOW", "NORMAL", "FAST"]
const LANGUAGE_OPTIONS = ["EN"]
const TEXT_SIZE_LABELS = ["SMALL", "NORMAL", "LARGE"]

const TABS = ["AUDIO", "GAME", "ACCESS"]

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_load_settings()
	_apply_all_settings()
	_build_canvas()
	_build_ui()

# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)
	
	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = Vector2(screen_w, screen_h)
	canvas.add_child(bg)
	
	_add_ambient_particles()

func _add_ambient_particles() -> void:
	var particle_layer = CanvasLayer.new()
	particle_layer.layer = 5
	add_child(particle_layer)
	
	for i in range(15):
		var particle = ColorRect.new()
		var size = randf_range(1, 2)
		particle.size = Vector2(size, size)
		particle.color = Color(
			GameTheme.get_color("accent").r,
			GameTheme.get_color("accent").g,
			GameTheme.get_color("accent").b,
			randf_range(0.05, 0.1)
		)
		particle.position = Vector2(randf_range(0, screen_w), randf_range(0, screen_h))
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle_layer.add_child(particle)
		
		var duration = randf_range(4, 8)
		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - randf_range(50, 150), duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.04, screen_h * 0.04)
	panel.size = Vector2(screen_w * 0.92, screen_h * 0.92)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 12)
	vbox.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "⚙️  SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 16)
	vbox.add_child(title)

	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Tab bar
	vbox.add_child(_build_tab_bar())

	var tab_divider = ColorRect.new()
	tab_divider.color = GameTheme.get_color("accent")
	tab_divider.custom_minimum_size = Vector2(0, 1)
	tab_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_divider)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Scrollable content area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	content_area = VBoxContainer.new()
	content_area.add_theme_constant_override("separation", 6)
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_area)

	# Bottom buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var save_btn = GameTheme.build_button("✓  SAVE", true, 12)
	save_btn.custom_minimum_size = Vector2(screen_w * 0.35, 40)
	save_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(save_btn, _on_save_pressed)
	btn_row.add_child(save_btn)

	var back_btn = GameTheme.build_button("◂  BACK", false, 12)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.25, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	btn_row.add_child(back_btn)

	_switch_tab(0)

func _build_tab_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 4)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for i in range(TABS.size()):
		var tab_btn = _build_tab_button(TABS[i], i)
		tab_buttons.append(tab_btn)
		bar.add_child(tab_btn)

	return bar

func _build_tab_button(label: String, index: int) -> PanelContainer:
	var btn = GameTheme.build_button(label, index == active_tab, 11)
	btn.custom_minimum_size = Vector2(80, 34)
	GameTheme.connect_button(btn, func(): _switch_tab(index))
	return btn

func _switch_tab(index: int) -> void:
	active_tab = index

	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as PanelContainer
		var is_active = i == active_tab
		btn.add_theme_stylebox_override("panel",
			GameTheme.make_button_style("normal" if not is_active else "pressed", true)
		)
		var lbl = btn.get_child(0) as Label
		if lbl:
			lbl.add_theme_color_override("font_color",
				GameTheme.get_color("accent") if is_active else GameTheme.get_color("dim")
			)

	for child in content_area.get_children():
		child.queue_free()

	await get_tree().process_frame

	match TABS[index]:
		"AUDIO":  _build_audio_tab()
		"GAME":   _build_game_tab()
		"ACCESS": _build_access_tab()

# =========================================
# TAB CONTENT
# =========================================
func _build_audio_tab() -> void:
	content_area.add_child(_build_slider_row("Master Volume", "master_volume"))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_slider_row("Music Volume", "music_volume"))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_slider_row("SFX Volume", "sfx_volume"))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_toggle_row("Vibration", "vibration"))

func _build_game_tab() -> void:
	content_area.add_child(_build_section_header("GAMEPLAY"))
	content_area.add_child(_build_option_row("Text Speed", "text_speed", TEXT_SPEED_LABELS))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_section_header("MOBILE"))
	content_area.add_child(_build_toggle_row("Notifications", "notifications"))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_section_header("LANGUAGE"))
	content_area.add_child(_build_option_row("Language", "language", LANGUAGE_OPTIONS))

func _build_access_tab() -> void:
	content_area.add_child(_build_section_header("TEXT"))
	content_area.add_child(_build_option_row("Text Size", "text_size", TEXT_SIZE_LABELS))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_section_header("DISPLAY"))
	content_area.add_child(_build_toggle_row("High Contrast", "high_contrast"))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_toggle_row("Show FPS", "show_fps"))

# =========================================
# UI COMPONENTS
# =========================================
func _build_section_header(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = "— " + text + " —"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(lbl, 9)
	lbl.custom_minimum_size = Vector2(0, 22)
	return lbl

func _build_toggle_row(label: String, setting_key: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 40)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	row.add_child(left)

	var lbl = Label.new()
	lbl.text = label.to_upper()
	lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(lbl, 11)
	left.add_child(lbl)

	var toggle = PanelContainer.new()
	toggle.custom_minimum_size = Vector2(64, 30)
	toggle.mouse_filter = Control.MOUSE_FILTER_STOP

	var is_on = settings.get(setting_key, false)
	_style_toggle(toggle, is_on)

	var toggle_lbl = Label.new()
	toggle_lbl.text = "ON" if is_on else "OFF"
	toggle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toggle_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toggle_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toggle_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle_lbl.add_theme_color_override("font_color",
		GameTheme.get_color("bg") if is_on else GameTheme.get_color("dim")
	)
	GameTheme.apply_font(toggle_lbl, 10)
	toggle.add_child(toggle_lbl)

	toggle.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var new_val = not settings.get(setting_key, false)
			settings[setting_key] = new_val
			_style_toggle(toggle, new_val)
			toggle_lbl.text = "ON" if new_val else "OFF"
			toggle_lbl.add_theme_color_override("font_color",
				GameTheme.get_color("bg") if new_val else GameTheme.get_color("dim")
			)
			_apply_setting(setting_key, new_val)
	)

	row.add_child(toggle)
	return row

func _style_toggle(toggle: PanelContainer, is_on: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = GameTheme.get_color("accent") if is_on else GameTheme.get_color("panel_mid")
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = GameTheme.get_color("accent")
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	toggle.add_theme_stylebox_override("panel", style)

func _build_slider_row(label: String, setting_key: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(0, 50)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(top_row)

	var lbl = Label.new()
	lbl.text = label.to_upper()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(lbl, 11)
	top_row.add_child(lbl)

	var val_lbl = Label.new()
	val_lbl.text = str(settings.get(setting_key, 100)) + "%"
	val_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(val_lbl, 12)
	top_row.add_child(val_lbl)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = settings.get(setting_key, 100)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 24)

	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = GameTheme.get_color("panel_mid")
	slider_bg.corner_radius_top_left = 4
	slider_bg.corner_radius_top_right = 4
	slider_bg.corner_radius_bottom_left = 4
	slider_bg.corner_radius_bottom_right = 4
	slider.add_theme_stylebox_override("slider", slider_bg)

	var slider_fill = StyleBoxFlat.new()
	slider_fill.bg_color = GameTheme.get_color("accent")
	slider_fill.corner_radius_top_left = 4
	slider_fill.corner_radius_top_right = 4
	slider_fill.corner_radius_bottom_left = 4
	slider_fill.corner_radius_bottom_right = 4
	slider.add_theme_stylebox_override("grabber_area", slider_fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", slider_fill)
	
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = GameTheme.get_color("accent_dark")
	grabber.corner_radius_top_left = 6
	grabber.corner_radius_top_right = 6
	grabber.corner_radius_bottom_left = 6
	grabber.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber", grabber)

	slider.value_changed.connect(func(val: float):
		settings[setting_key] = int(val)
		val_lbl.text = str(int(val)) + "%"
		_apply_setting(setting_key, int(val))
	)
	container.add_child(slider)

	return container

func _build_option_row(label: String, setting_key: String, options: Array) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(0, 50)

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(top_row)

	var lbl = Label.new()
	lbl.text = label.to_upper()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(lbl, 11)
	top_row.add_child(lbl)

	var current_idx = settings.get(setting_key, 0)
	
	var arrow_row = HBoxContainer.new()
	arrow_row.add_theme_constant_override("separation", 6)
	arrow_row.alignment = BoxContainer.ALIGNMENT_END
	container.add_child(arrow_row)

	var left_btn = GameTheme.build_button("◂", false, 14)
	left_btn.custom_minimum_size = Vector2(40, 34)
	arrow_row.add_child(left_btn)

	var opt_container = PanelContainer.new()
	opt_container.custom_minimum_size = Vector2(90, 34)
	opt_container.add_theme_stylebox_override("panel", GameTheme.make_panel_style("mid"))
	arrow_row.add_child(opt_container)

	var opt_lbl = Label.new()
	opt_lbl.text = options[current_idx]
	opt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	opt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	opt_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(opt_lbl, 11)
	opt_container.add_child(opt_lbl)

	var right_btn = GameTheme.build_button("▸", false, 14)
	right_btn.custom_minimum_size = Vector2(40, 34)
	arrow_row.add_child(right_btn)

	var idx = [current_idx]

	GameTheme.connect_button(left_btn, func():
		idx[0] = wrapi(idx[0] - 1, 0, options.size())
		opt_lbl.text = options[idx[0]]
		settings[setting_key] = idx[0]
		_apply_setting(setting_key, idx[0])
	)
	GameTheme.connect_button(right_btn, func():
		idx[0] = wrapi(idx[0] + 1, 0, options.size())
		opt_lbl.text = options[idx[0]]
		settings[setting_key] = idx[0]
		_apply_setting(setting_key, idx[0])
	)

	return container

func _build_divider_row() -> ColorRect:
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("panel_mid")
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return divider

# =========================================
# SETTINGS APPLICATION
# =========================================
func _apply_all_settings() -> void:
	for key in settings.keys():
		_apply_setting(key, settings[key])

func _apply_setting(key: String, value) -> void:
	match key:
		"master_volume":
			var bus = AudioServer.get_bus_index("Master")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))
		"music_volume":
			var bus = AudioServer.get_bus_index("Music")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))
			# Also update AudioManager if playing music
			if AudioManager:
				AudioManager.set_music_volume(value)
		"sfx_volume":
			var bus = AudioServer.get_bus_index("SFX")
			if bus >= 0:
				AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))
			if AudioManager:
				AudioManager.set_sfx_volume(value)
		"vibration":
			GameTheme.set_vibration(value)
		"text_speed":
			GameTheme.set_text_speed(TEXT_SPEEDS[value])
		_:
			pass

# =========================================
# PERSISTENCE
# =========================================
func _save_settings() -> void:
	var file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()

func _load_settings() -> void:
	if not FileAccess.file_exists("user://settings.cfg"):
		return
	var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			var loaded = json.get_data()
			for key in loaded.keys():
				settings[key] = loaded[key]

# =========================================
# CALLBACKS
# =========================================
func _on_save_pressed() -> void:
	_save_settings()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
