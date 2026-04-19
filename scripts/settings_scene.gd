extends Node

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0
var content_area: VBoxContainer = null
var active_tab:   int           = 0
var tab_buttons:  Array         = []

# =========================================
# DATA
# =========================================
const TABS = [
	"AUDIO",
	"GAME",
	"ACCESS",
]

# =========================================
# SETTINGS STATE
# =========================================
var settings: Dictionary = {
	# Audio
	"master_volume": 100,
	"music_volume":  80,
	"sfx_volume":    100,
	"vibration":     true,   # mobile only — prep

	# Game
	"text_speed":    1,      # 0 slow 1 normal 2 fast
	"language":      0,      # index into language options
	"notifications": true,   # mobile only — prep

	# Accessibility
	"text_size":     1,      # 0 small 1 normal 2 large
	"high_contrast": false,  # prep — swaps theme palette
	"show_fps":      false,
}

# Audio bus names — wire these in Godot Audio panel
const BUS_MASTER = "Master"
const BUS_MUSIC  = "Music"
const BUS_SFX    = "SFX"

# Text speed values wired to DialogueManager
const TEXT_SPEEDS = [0.06, 0.03, 0.01]  # slow normal fast
const TEXT_SPEED_LABELS = ["SLOW", "NORMAL", "FAST"]

# Language options — expand as needed
const LANGUAGE_OPTIONS = ["EN"]

# Text size multipliers
const TEXT_SIZE_LABELS = ["SMALL", "NORMAL", "LARGE"]
const TEXT_SIZE_SCALE  = [0.8, 1.0, 1.3]

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
	canvas      = CanvasLayer.new()
	add_child(canvas)

	var bg      = ColorRect.new()
	bg.color    = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size     = Vector2(screen_w, screen_h)
	canvas.add_child(bg)


func _build_ui() -> void:
	var panel          = PanelContainer.new()
	panel.position     = Vector2(screen_w * 0.05, screen_h * 0.05)
	panel.size         = Vector2(screen_w * 0.9, screen_h * 0.9)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    0)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(vbox)

	# Title
	var title                  = Label.new()
	title.text                 = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 14)
	vbox.add_child(title)

	# Divider
	var divider               = ColorRect.new()
	divider.color             = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Gap
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap)

	# Tab bar
	vbox.add_child(_build_tab_bar())

	# Tab divider
	var tab_divider               = ColorRect.new()
	tab_divider.color             = GameTheme.get_color("accent")
	tab_divider.custom_minimum_size = Vector2(0, 2)
	tab_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_divider)

	# Gap
	var gap2 = Control.new()
	gap2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap2)

	# Content area
	content_area = VBoxContainer.new()
	content_area.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 4)
	vbox.add_child(content_area)

	# Gap
	var gap3 = Control.new()
	gap3.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap3)

	# Bottom buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment             = BoxContainer.ALIGNMENT_CENTER
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var save_btn = GameTheme.build_button("✓  SAVE", true)
	save_btn.custom_minimum_size = Vector2(screen_w * 0.35, GameTheme.BUTTON_H)
	save_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(save_btn, _on_save_pressed)
	btn_row.add_child(save_btn)

	var back_btn = GameTheme.build_button("◂  BACK", false)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.25, GameTheme.BUTTON_H)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	btn_row.add_child(back_btn)

	_switch_tab(0)


func _build_tab_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for i in range(TABS.size()):
		var tab_btn = _build_tab_button(TABS[i], i)
		tab_buttons.append(tab_btn)
		bar.add_child(tab_btn)

	return bar


func _build_tab_button(label: String, index: int) -> PanelContainer:
	var btn = GameTheme.build_button(label, index == active_tab)
	GameTheme.connect_button(btn, func(): _switch_tab(index))
	return btn


# =========================================
# TAB LOGIC
# =========================================
func _switch_tab(index: int) -> void:
	active_tab = index

	for i in range(tab_buttons.size()):
		var btn       = tab_buttons[i] as PanelContainer
		var is_active = i == active_tab
		btn.add_theme_stylebox_override("panel",
			GameTheme.make_button_style(
				"normal" if not is_active else "pressed", true
			)
		)
		var lbl = btn.get_child(0) as Label
		if lbl:
			lbl.add_theme_color_override("font_color",
				GameTheme.get_color("accent") if is_active
				else GameTheme.get_color("dim")
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
	content_area.add_child(_build_slider_row(
		"Master", "", "master_volume"
	))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_slider_row(
		"Music", "", "music_volume"
	))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_slider_row(
		"SFX", "", "sfx_volume"
	))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_toggle_row(
		"Vibration",
		"Haptic feedback",
		"vibration"
	))


func _build_game_tab() -> void:
	content_area.add_child(_build_section_header("GAMEPLAY"))
	content_area.add_child(_build_option_row(
		"Text Speed",
		"How fast dialogue types out",
		"text_speed",
		TEXT_SPEED_LABELS,
		settings.get("text_speed", 1)
	))
	content_area.add_child(_build_divider_row())
	# MOBILE PREP — notifications
	content_area.add_child(_build_section_header("MOBILE"))
	content_area.add_child(_build_toggle_row(
		"Notifications",
		"Daily reminders to play",
		"notifications"
	))
	content_area.add_child(_build_divider_row())
	# Language — expand options array when ready
	content_area.add_child(_build_section_header("LANGUAGE"))
	content_area.add_child(_build_option_row(
		"Language",
		"Game display language",
		"language",
		LANGUAGE_OPTIONS,
		settings.get("language", 0)
	))


func _build_access_tab() -> void:
	content_area.add_child(_build_section_header("TEXT"))
	content_area.add_child(_build_option_row(
		"Text Size",
		"Scale all game text",
		"text_size",
		TEXT_SIZE_LABELS,
		settings.get("text_size", 1)
	))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_section_header("DISPLAY"))
	content_area.add_child(_build_toggle_row(
		"High Contrast",
		"Increases color contrast for readability",
		"high_contrast"
	))
	content_area.add_child(_build_divider_row())
	content_area.add_child(_build_toggle_row(
		"Show FPS",
		"Display frame rate counter",
		"show_fps"
	))


# =========================================
# ROW BUILDERS
# =========================================
func _build_section_header(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = "— " + text + " —"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(lbl, 9)
	lbl.custom_minimum_size = Vector2(0, 24)
	return lbl


func _build_toggle_row(
	label_txt:   String,
	description: String,
	setting_key: String
) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 36)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	row.add_child(left)

	var lbl = Label.new()
	lbl.text = label_txt.to_upper()
	lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(lbl, 11)
	left.add_child(lbl)

	var desc = Label.new()
	desc.text = description
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 8)
	left.add_child(desc)

	var toggle                 = PanelContainer.new()
	toggle.custom_minimum_size = Vector2(72, 32)
	toggle.mouse_filter        = Control.MOUSE_FILTER_STOP

	var is_on = settings.get(setting_key, false)
	_style_toggle(toggle, is_on)

	var toggle_lbl                  = Label.new()
	toggle_lbl.text                 = "ON" if is_on else "OFF"
	toggle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toggle_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	toggle_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toggle_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	toggle_lbl.add_theme_color_override("font_color",
		GameTheme.get_color("bg") if is_on
		else GameTheme.get_color("dim")
	)
	GameTheme.apply_font(toggle_lbl, 10)
	toggle.add_child(toggle_lbl)

	toggle.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				var new_val = not settings.get(setting_key, false)
				settings[setting_key] = new_val
				_style_toggle(toggle, new_val)
				toggle_lbl.text = "ON" if new_val else "OFF"
				toggle_lbl.add_theme_color_override("font_color",
					GameTheme.get_color("bg") if new_val
					else GameTheme.get_color("dim")
				)
				_apply_setting(setting_key, new_val)
	)

	row.add_child(toggle)
	return row


func _style_toggle(toggle: PanelContainer, is_on: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color                   = GameTheme.get_color("accent") if is_on \
									   else GameTheme.get_color("panel_mid")
	style.border_width_top           = 2
	style.border_width_bottom        = 2
	style.border_width_left          = 2
	style.border_width_right         = 2
	style.border_color               = GameTheme.get_color("accent")
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	toggle.add_theme_stylebox_override("panel", style)


func _build_slider_row(
	label_txt:   String,
	description: String,
	setting_key: String
) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)  # was 4
	container.custom_minimum_size = Vector2(0, 44)  # was 56
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(top_row)

	# Label only — remove description to save space
	var lbl = Label.new()
	lbl.text                 = label_txt.to_upper()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(lbl, 11)
	top_row.add_child(lbl)

	var val_lbl = Label.new()
	val_lbl.text = str(settings.get(setting_key, 100)) + "%"
	val_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(val_lbl, 11)
	top_row.add_child(val_lbl)

	var slider                   = HSlider.new()
	slider.min_value             = 0
	slider.max_value             = 100
	slider.step                  = 5
	slider.value                 = settings.get(setting_key, 100)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size   = Vector2(0, 20)

	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color                   = GameTheme.get_color("panel_mid")
	slider_bg.corner_radius_top_left     = 0
	slider_bg.corner_radius_top_right    = 0
	slider_bg.corner_radius_bottom_left  = 0
	slider_bg.corner_radius_bottom_right = 0
	slider.add_theme_stylebox_override("slider", slider_bg)

	var slider_fill = StyleBoxFlat.new()
	slider_fill.bg_color                   = GameTheme.get_color("accent")
	slider_fill.corner_radius_top_left     = 0
	slider_fill.corner_radius_top_right    = 0
	slider_fill.corner_radius_bottom_left  = 0
	slider_fill.corner_radius_bottom_right = 0
	slider.add_theme_stylebox_override("grabber_area",           slider_fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", slider_fill)
	slider.add_theme_icon_override("grabber",
		_make_grabber_icon(16, GameTheme.get_color("accent"))
	)

	slider.value_changed.connect(func(val: float):
		settings[setting_key] = int(val)
		val_lbl.text = str(int(val)) + "%"
		_apply_setting(setting_key, int(val))
	)
	container.add_child(slider)

	return container


func _make_grabber_icon(size: int, color: Color) -> ImageTexture:
	# Creates a simple square grabber pixel art style
	var img   = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _build_option_row(
	label_txt:   String,
	description: String,
	setting_key: String,
	options:     Array,
	current_idx: int
) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.custom_minimum_size = Vector2(0, 52)

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	container.add_child(top_row)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	top_row.add_child(left)

	var lbl = Label.new()
	lbl.text = label_txt.to_upper()
	lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(lbl, 11)
	left.add_child(lbl)

	var desc = Label.new()
	desc.text = description
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 8)
	left.add_child(desc)

	# Arrow row
	var arrow_row = HBoxContainer.new()
	arrow_row.add_theme_constant_override("separation", 6)
	arrow_row.alignment = BoxContainer.ALIGNMENT_END
	container.add_child(arrow_row)

	var left_btn = GameTheme.build_button("◂", false)
	left_btn.custom_minimum_size = Vector2(44, 36)
	left_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	arrow_row.add_child(left_btn)

	var opt_container = PanelContainer.new()
	opt_container.custom_minimum_size = Vector2(100, 36)
	opt_container.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid")
	)
	arrow_row.add_child(opt_container)

	var opt_lbl                  = Label.new()
	opt_lbl.text                 = options[current_idx]
	opt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	opt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	opt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opt_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	opt_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(opt_lbl, 11)
	opt_container.add_child(opt_lbl)

	var right_btn = GameTheme.build_button("▸", false)
	right_btn.custom_minimum_size  = Vector2(44, 36)
	right_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
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
	var divider               = ColorRect.new()
	divider.color             = GameTheme.get_color("panel_mid")
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
			var bus = AudioServer.get_bus_index(BUS_MASTER)
			if bus >= 0:
				AudioServer.set_bus_volume_db(
					bus, linear_to_db(value / 100.0)
				)
		"music_volume":
			var bus = AudioServer.get_bus_index(BUS_MUSIC)
			if bus >= 0:
				AudioServer.set_bus_volume_db(
					bus, linear_to_db(value / 100.0)
				)
		"sfx_volume":
			var bus = AudioServer.get_bus_index(BUS_SFX)
			if bus >= 0:
				AudioServer.set_bus_volume_db(
					bus, linear_to_db(value / 100.0)
				)
		"vibration":
			# MOBILE PREP
			# Input.vibrate_handheld(50) ← call this on choice press
			# Stored in settings, read by ChoicesContainer later
			pass
		"text_speed":
			# Wire to DialogueManager when ready
			# DialogueManager.set_text_speed(TEXT_SPEEDS[value])
			pass
		"notifications":
			# MOBILE PREP
			# Wire to Android/iOS notification API later
			# Stored in settings for future use
			pass
		"text_size":
			# MOBILE PREP
			# GameTheme.set_text_scale(TEXT_SIZE_SCALE[value])
			# Requires GameTheme text scale system — Phase 3
			pass
		"high_contrast":
			# MOBILE PREP
			# GameTheme.set_high_contrast(value)
			# Requires alternate palette in GameTheme — Phase 3
			pass
		"show_fps":
			# Show/hide FPS label overlay
			# Wire to a persistent FPS overlay node later
			pass
		"language":
			# Wire to localization system later
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
		var json  = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			# Merge loaded settings with defaults
			# so new settings keys always have a value
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
