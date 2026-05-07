extends Node

# =========================================
# CONSTANTS
# =========================================
const TOTAL_DAYS = 5

# =========================================
# REFERENCES
# =========================================
var canvas:      CanvasLayer        = null
var next_button: PanelContainer     = null
var pause_menu:  Node               = null
var burger_btn:  PanelContainer     = null

# =========================================
# STATE
# =========================================
var _current_day:   int        = 1
var _stat_deltas:   Dictionary = {}
var _current_stats: Dictionary = {}

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_receive_data()
	_build_canvas()
	_build_ui()
	AudioManager.play_sfx("day_end")
	DialogueManager.save_game()

# =========================================
# DATA
# =========================================
func _receive_data() -> void:
	_current_day   = DialogueManager.get_current_day()
	_stat_deltas   = DialogueManager.get_stat_deltas()
	_current_stats = DialogueManager.get_all_stats()

# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = get_viewport().get_visible_rect().size
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
		particle.position = Vector2(
			randf_range(0, get_viewport().get_visible_rect().size.x),
			randf_range(0, get_viewport().get_visible_rect().size.y)
		)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle_layer.add_child(particle)
		
		var duration = randf_range(4, 8)
		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - randf_range(50, 150), duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

func _build_ui() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	var screen_h = get_viewport().get_visible_rect().size.y

	# Main panel - slightly smaller to ensure everything fits
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.05, screen_h * 0.04)
	panel.size = Vector2(screen_w * 0.9, screen_h * 0.92)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)  # Reduced from 12
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# === HEADER SECTION ===
	_build_header(vbox, screen_w)
	
	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 1.5)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# === STAT CARDS (2x2 grid) ===
	var stat_grid = GridContainer.new()
	stat_grid.columns = 2
	stat_grid.add_theme_constant_override("h_separation", 10)
	stat_grid.add_theme_constant_override("v_separation", 8)
	stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stat_grid)

	var stat_defs = [
		["money", "💰", "CAPITAL", GameTheme.get_color("money")],
		["reputation", "⭐", "REPUTATION", GameTheme.get_color("reputation")],
		["morale", "😊", "MORALE", GameTheme.get_color("morale")],
		["stress", "😰", "STRESS", GameTheme.get_color("stress")],
	]
	
	for stat in stat_defs:
		stat_grid.add_child(_build_stat_card(stat[0], stat[1], stat[2], stat[3]))

	# Spacer - smaller
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# === DAY PROGRESS ===
	var progress_container = VBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 4)
	vbox.add_child(progress_container)
	
	var progress_label = Label.new()
	progress_label.text = "DAY PROGRESS"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(progress_label, 14)  # Increased from 8
	progress_container.add_child(progress_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = TOTAL_DAYS
	progress_bar.value = _current_day
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 10)  # Thicker bar
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = GameTheme.get_color("accent")
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(1, 1, 1, 0.1)
	bg_style.corner_radius_top_left = 5
	bg_style.corner_radius_top_right = 5
	bg_style.corner_radius_bottom_left = 5
	bg_style.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_container.add_child(progress_bar)
	
	var day_counter = Label.new()
	day_counter.text = "Day " + str(_current_day) + " of " + str(TOTAL_DAYS)
	day_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_counter.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(day_counter, 14)  # Increased from 8
	progress_container.add_child(day_counter)

	# Spacer - smaller
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer2)

	# === BUTTON ROW ===
	var btn_center = HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_center.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_center)
	
	# Shop button
	var shop_btn = GameTheme.build_button("🛒  SHOP", false, 16)
	shop_btn.custom_minimum_size = Vector2(screen_w * 0.25, 40)
	shop_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(shop_btn, _on_shop_pressed)
	btn_center.add_child(shop_btn)
	
	# Next button
	var is_last_day = (_current_day >= TOTAL_DAYS)
	var next_text = "🏆  FINAL RESULTS" if is_last_day else "▶  NEXT DAY"
	next_button = GameTheme.build_button(next_text, true, 16)
	next_button.custom_minimum_size = Vector2(screen_w * 0.4, 40)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(next_button, _on_next_pressed)
	btn_center.add_child(next_button)

	_build_pause_menu()

func _build_header(vbox: VBoxContainer, screen_w: float) -> void:
	# Day badge
	var day_badge = PanelContainer.new()
	day_badge.custom_minimum_size = Vector2(140, 36)
	day_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	day_badge.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("accent")
	)
	
	var day_text = Label.new()
	day_text.text = "DAY " + str(_current_day) + " COMPLETE"
	day_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	day_text.add_theme_color_override("font_color", GameTheme.get_color("bg"))
	GameTheme.apply_font(day_text, 20)  # Increased from 14
	day_badge.add_child(day_text)
	vbox.add_child(day_badge)
	
	# Congratulatory message
	var message = _get_day_message()
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(msg_label, 15)  # Increased from 10
	vbox.add_child(msg_label)

func _get_day_message() -> String:
	var avg_stat = (_current_stats.get("money", 50) + 
					_current_stats.get("reputation", 50) + 
					_current_stats.get("morale", 50) - 
					_current_stats.get("stress", 50)) / 3.0
	
	match _current_day:
		1:
			if avg_stat >= 60: return "Strong start! Your business foundations are solid."
			elif avg_stat >= 40: return "A decent beginning. Room to grow."
			else: return "Tough first day. Tomorrow brings new opportunities."
		2:
			if avg_stat >= 60: return "Momentum is building! Keep making smart choices."
			elif avg_stat >= 40: return "Steady progress. Focus on what's working."
			else: return "A rough patch. Time to rethink your strategy."
		3:
			if avg_stat >= 60: return "Halfway there! Your business is finding its rhythm."
			elif avg_stat >= 40: return "Holding steady. The right moves could turn things around."
			else: return "Struggling a bit. Seek opportunities to recover."
		4:
			if avg_stat >= 60: return "One more day! Your business is thriving."
			elif avg_stat >= 40: return "The final stretch. Focus on finishing strong."
			else: return "Critical moment. Everything rides on tomorrow."
		_:
			return ""

func _build_stat_card(stat_key: String, icon: String, label: String, bar_color: Color) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)  # Slightly shorter
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	card.add_child(vbox)
	
	# Top row: icon + label + delta
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)
	
	# Icon (asset or emoji)
	var icon_node = _load_or_create_icon(stat_key + "_stat", icon, 20)  # Larger icon
	icon_node.custom_minimum_size = Vector2(28, 28)
	top_row.add_child(icon_node)
	
	var label_label = Label.new()
	label_label.text = label
	label_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(label_label, 14)  # Increased
	top_row.add_child(label_label)
	
	var delta = _stat_deltas.get(stat_key, 0.0)
	var delta_label = Label.new()
	delta_label.text = ("▲ +" if delta >= 0 else "▼ ") + str(abs(int(delta)))
	delta_label.add_theme_color_override("font_color",
		GameTheme.get_color("positive") if delta >= 0 else GameTheme.get_color("negative")
	)
	GameTheme.apply_font(delta_label, 15)  # Increased
	top_row.add_child(delta_label)
	
	# Progress bar
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = _current_stats.get(stat_key, 50.0)
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 8)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg)
	vbox.add_child(bar)
	
	# Value display
	var value_row = HBoxContainer.new()
	value_row.alignment = BoxContainer.ALIGNMENT_CENTER
	value_row.add_theme_constant_override("separation", 4)
	vbox.add_child(value_row)
	
	var value = int(_current_stats.get(stat_key, 50.0))
	var value_label = Label.new()
	value_label.text = str(value) + " / 100"
	value_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(value_label, 15)  # Increased
	value_row.add_child(value_label)
	
	return card

func _load_or_create_icon(asset_name: String, fallback_emoji: String, font_size: int) -> Control:
	var asset_path = GameTheme._current.get("ui_folder", "") + asset_name + ".png"
	if ResourceLoader.exists(asset_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(asset_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(font_size, font_size)
		return tex_rect
	
	var label = Label.new()
	label.text = fallback_emoji
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _build_pause_menu() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	burger_btn = PanelContainer.new()
	burger_btn.position = Vector2(screen_w - 40, 12)
	burger_btn.size = Vector2(32, 28)
	burger_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0.6)
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_color = GameTheme.get_color("accent")
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	burger_btn.add_theme_stylebox_override("panel", btn_style)
	
	var btn_lbl = Label.new()
	btn_lbl.text = "☰"
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_lbl.add_theme_font_size_override("font_size", 14)
	btn_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	burger_btn.add_child(btn_lbl)
	canvas.add_child(burger_btn)
	GameTheme.connect_button(burger_btn, _on_burger_pressed)

	pause_menu = load("res://scenes/pause_menu.tscn").instantiate()
	add_child(pause_menu)

func _on_burger_pressed() -> void:
	pause_menu.toggle()

# =========================================
# CALLBACKS
# =========================================
func _on_next_pressed() -> void:
	if _current_day >= TOTAL_DAYS:
		get_tree().change_scene_to_file("res://scenes/final_result_screen.tscn")
	else:
		DialogueManager.load_next_day()
		get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop_scene.tscn")
