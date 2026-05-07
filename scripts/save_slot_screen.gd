extends Node

# =========================================
# SAVE SLOT SCREEN
# Used for both New Game and Continue flows.
# mode = "new_game" → all slots selectable, leads to business selector
# mode = "continue" → only occupied slots selectable, loads directly
# =========================================

# =========================================
# REFERENCES
# =========================================
var canvas:    CanvasLayer   = null
var screen_w:  float         = 0.0
var screen_h:  float         = 0.0

# =========================================
# STATE
# =========================================
var mode: String = "new_game"   # "new_game" or "continue"

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	SaveManager._load_all_slots()
	_build_ui()

# =========================================
# BUILD
# =========================================
func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	# Gradient background
	var gradient_bg = ColorRect.new()
	gradient_bg.position = Vector2(0, 0)
	gradient_bg.size = Vector2(screen_w, screen_h)
	gradient_bg.material = _create_gradient_material()
	canvas.add_child(gradient_bg)

	# Decorative particles (subtle)
	_add_decorative_particles()

	# Main panel - cleaner, more elegant
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.1, screen_h * 0.08)
	panel.size = Vector2(screen_w * 0.8, screen_h * 0.84)  # was 0.92
	panel.custom_minimum_size = panel.size
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.7)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = GameTheme.get_color("accent")
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 16)    # was 20
	vbox.add_theme_constant_override("margin_right", 16)   # was 20
	vbox.add_theme_constant_override("margin_top", 16)     # was 20
	vbox.add_theme_constant_override("margin_bottom", 16)  # was 20
	panel.add_child(vbox)

	# Decorative top bar
	var top_decoration = HBoxContainer.new()
	top_decoration.alignment = BoxContainer.ALIGNMENT_CENTER
	top_decoration.add_theme_constant_override("separation", 8)
	vbox.add_child(top_decoration)
	
	var left_line = ColorRect.new()
	left_line.color = GameTheme.get_color("accent")
	left_line.custom_minimum_size = Vector2(50, 1)
	top_decoration.add_child(left_line)
	
	var diamond = Label.new()
	diamond.text = "◆"
	diamond.add_theme_font_size_override("font_size", 10)
	diamond.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	top_decoration.add_child(diamond)
	
	var right_line = ColorRect.new()
	right_line.color = GameTheme.get_color("accent")
	right_line.custom_minimum_size = Vector2(50, 1)
	top_decoration.add_child(right_line)

	# Title
	var title_text = "⚡ SAVE SLOT ⚡" if mode == "new_game" else "📂 LOAD SAVE"
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 16)
	vbox.add_child(title)

	# Subtitle
	var sub_text = "Choose a slot to begin your journey" if mode == "new_game" \
				   else "Select a save file to continue"
	var sub = Label.new()
	sub.text = sub_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub, 9)
	vbox.add_child(sub)

	# Divider with icon
	var div_container = HBoxContainer.new()
	div_container.alignment = BoxContainer.ALIGNMENT_CENTER
	div_container.add_theme_constant_override("separation", 8)
	vbox.add_child(div_container)
	
	var left_div = ColorRect.new()
	left_div.color = GameTheme.get_color("accent")
	left_div.custom_minimum_size = Vector2(80, 1)
	left_div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div_container.add_child(left_div)
	
	var div_icon = Label.new()
	div_icon.text = "✦"
	div_icon.add_theme_font_size_override("font_size", 10)
	div_icon.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	div_container.add_child(div_icon)
	
	var right_div = ColorRect.new()
	right_div.color = GameTheme.get_color("accent")
	right_div.custom_minimum_size = Vector2(80, 1)
	right_div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div_container.add_child(right_div)

	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sp)

	# Slot cards
	var slots_container = VBoxContainer.new()
	slots_container.add_theme_constant_override("separation", 16)
	slots_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(slots_container)
	
	var slots = SaveManager.get_all_slots()
	for i in range(SaveManager.SLOT_COUNT):
		slots_container.add_child(_build_slot_card(slots[i]))

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK", false, 14)
	back_btn.custom_minimum_size = Vector2(140, 44)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

func _create_gradient_material() -> ShaderMaterial:
	var shader_code = """
	shader_type canvas_item;
	
	uniform vec4 color_top : source_color = vec4(0.12, 0.10, 0.18, 1.0);
	uniform vec4 color_bottom : source_color = vec4(0.06, 0.05, 0.10, 1.0);
	
	void fragment() {
		float mix_factor = UV.y;
		COLOR = mix(color_top, color_bottom, mix_factor);
	}
	"""
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	return material

func _add_decorative_particles() -> void:
	# Subtle floating particles
	for i in range(20):
		var particle = ColorRect.new()
		var size = randf_range(1, 3)
		particle.size = Vector2(size, size)
		particle.color = Color(
			GameTheme.get_color("accent").r,
			GameTheme.get_color("accent").g,
			GameTheme.get_color("accent").b,
			randf_range(0.05, 0.2)
		)
		particle.position = Vector2(
			randf_range(0, screen_w),
			randf_range(0, screen_h)
		)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(particle)
		
		# Store for animation if desired
		particle.set_meta("speed", randf_range(5, 20))
		particle.set_meta("drift", randf_range(-5, 5))

func _build_slot_card(slot: Dictionary) -> Control:
	var occupied = slot.get("occupied", false)
	var slot_idx = slot.get("slot_index", 0)
	var completed = slot.get("completed", false)
	var grade = slot.get("grade", "")

	var selectable = true
	if mode == "continue" and not occupied:
		selectable = false

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 75)  # Reduced from 100
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = GameTheme.get_color("panel_mid") if selectable \
						  else GameTheme.get_color("panel_dark")
	card_style.border_width_top = 1  # Reduced from 2
	card_style.border_width_bottom = 1
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_color = GameTheme.get_color("accent") if selectable \
							  else GameTheme.get_color("dim")
	card_style.corner_radius_top_left = 10  # Reduced from 12
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.corner_radius_bottom_right = 10
	
	if selectable and not occupied:
		card_style.shadow_size = 6  # Reduced from 8
		card_style.shadow_color = Color(GameTheme.get_color("accent").r, 
										GameTheme.get_color("accent").g,
										GameTheme.get_color("accent").b, 0.3)
	
	card.add_theme_stylebox_override("panel", card_style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP if selectable \
						else Control.MOUSE_FILTER_IGNORE

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)  # Reduced from 14
	hbox.add_theme_constant_override("margin_left", 12)  # Reduced from 16
	hbox.add_theme_constant_override("margin_right", 12) # Reduced from 16
	hbox.add_theme_constant_override("margin_top", 10)   # Reduced from 14
	hbox.add_theme_constant_override("margin_bottom", 10)# Reduced from 14
	card.add_child(hbox)

	# Slot number badge - smaller
	var badge_container = CenterContainer.new()
	badge_container.custom_minimum_size = Vector2(46, 46)
	hbox.add_child(badge_container)
	
	var badge = PanelContainer.new()
	badge.custom_minimum_size = Vector2(40, 40)  # Reduced from 48
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = GameTheme.get_color("accent") if selectable \
						   else GameTheme.get_color("dim")
	badge_style.corner_radius_top_left = 20
	badge_style.corner_radius_top_right = 20
	badge_style.corner_radius_bottom_left = 20
	badge_style.corner_radius_bottom_right = 20
	badge.add_theme_stylebox_override("panel", badge_style)
	badge_container.add_child(badge)
	
	var badge_lbl = Label.new()
	badge_lbl.text = str(slot_idx + 1)
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_lbl.add_theme_color_override("font_color", GameTheme.get_color("bg"))
	GameTheme.apply_font(badge_lbl, 16)  # Reduced from 18
	badge.add_child(badge_lbl)

	# Info column - compact
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)  # Reduced from 6
	hbox.add_child(info_vbox)

	if not occupied:
		# Compact empty state
		var empty_container = HBoxContainer.new()
		empty_container.alignment = BoxContainer.ALIGNMENT_CENTER
		info_vbox.add_child(empty_container)
		
		var empty_icon = Label.new()
		empty_icon.text = "📭"
		GameTheme.apply_font(empty_icon, 18)  # Reduced from 24
		empty_container.add_child(empty_icon)
		
		var empty_lbl = Label.new()
		empty_lbl.text = "EMPTY"
		empty_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("dim") if mode == "new_game"
			else GameTheme.get_color("panel_mid")
		)
		GameTheme.apply_font(empty_lbl, 10)  # Reduced from 12
		empty_container.add_child(empty_lbl)

		if mode == "new_game":
			var new_lbl = Label.new()
			new_lbl.text = "Tap to start →"
			new_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
			GameTheme.apply_font(new_lbl, 8)  # Reduced from 9
			info_vbox.add_child(new_lbl)
	else:
		# Occupied slot - compact layout
		var biz_def = SaveManager.get_business_def(slot.get("business_id", ""))
		var biz_icon = biz_def.get("icon", "🏪")
		var biz_name = slot.get("business_name", "Unknown")
		var current_day = slot.get("current_day", 1)
		
		# Top row: business icon + name
		var biz_row = HBoxContainer.new()
		biz_row.add_theme_constant_override("separation", 6)
		info_vbox.add_child(biz_row)
		
		var icon_node = _load_business_icon(slot.get("business_id", ""), biz_icon)
		icon_node.custom_minimum_size = Vector2(24, 24)  # Reduced from 28
		biz_row.add_child(icon_node)
		
		var biz_name_lbl = Label.new()
		biz_name_lbl.text = biz_name.to_upper()
		biz_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		biz_name_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
		GameTheme.apply_font(biz_name_lbl, 11)  # Reduced from 13
		biz_row.add_child(biz_name_lbl)
		
		# Progress bar row - compact
		var progress_row = HBoxContainer.new()
		progress_row.add_theme_constant_override("separation", 6)
		info_vbox.add_child(progress_row)
		
		var progress_icon = Label.new()
		progress_icon.text = "📊"
		GameTheme.apply_font(progress_icon, 8)  # Reduced from 10
		progress_row.add_child(progress_icon)
		
		var progress_bar = ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = 5
		progress_bar.value = current_day
		progress_bar.show_percentage = false
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.custom_minimum_size = Vector2(0, 6)  # Reduced from 8
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = GameTheme.get_color("accent")
		fill_style.corner_radius_top_left = 3
		fill_style.corner_radius_top_right = 3
		fill_style.corner_radius_bottom_left = 3
		fill_style.corner_radius_bottom_right = 3
		progress_bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(1, 1, 1, 0.1)
		bg_style.corner_radius_top_left = 3
		bg_style.corner_radius_top_right = 3
		bg_style.corner_radius_bottom_left = 3
		bg_style.corner_radius_bottom_right = 3
		progress_bar.add_theme_stylebox_override("background", bg_style)
		progress_row.add_child(progress_bar)
		
		var day_text = Label.new()
		day_text.text = str(current_day) + "/5"
		day_text.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(day_text, 8)  # Reduced from 9
		progress_row.add_child(day_text)
		
		# Timestamp - compact
		var ts_row = HBoxContainer.new()
		ts_row.add_theme_constant_override("separation", 4)
		info_vbox.add_child(ts_row)
		
		var clock_icon = Label.new()
		clock_icon.text = "🕐"
		GameTheme.apply_font(clock_icon, 7)  # Reduced from 8
		ts_row.add_child(clock_icon)
		
		var ts_lbl = Label.new()
		ts_lbl.text = slot.get("timestamp", "Just now")
		ts_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(ts_lbl, 7)  # Reduced from 8
		ts_row.add_child(ts_lbl)
		
		# Completion badge (if completed) - compact
		if completed:
			var grade_panel = PanelContainer.new()
			var grade_style = StyleBoxFlat.new()
			grade_style.bg_color = _get_grade_color(grade)
			grade_style.corner_radius_top_left = 6
			grade_style.corner_radius_top_right = 6
			grade_style.corner_radius_bottom_left = 6
			grade_style.corner_radius_bottom_right = 6
			grade_style.content_margin_left = 6
			grade_style.content_margin_right = 6
			grade_panel.add_theme_stylebox_override("panel", grade_style)
			
			var grade_lbl = Label.new()
			grade_lbl.text = grade
			grade_lbl.add_theme_color_override("font_color", GameTheme.get_color("bg"))
			GameTheme.apply_font(grade_lbl, 9)
			grade_panel.add_child(grade_lbl)
			
			# Position grade badge at the end of biz row
			biz_row.add_child(grade_panel)

	# Right side action indicator - smaller
	if selectable:
		var action_container = CenterContainer.new()
		action_container.custom_minimum_size = Vector2(32, 0)  # Reduced from 40
		hbox.add_child(action_container)
		
		var action_lbl = Label.new()
		if mode == "continue":
			action_lbl.text = "▶"
		elif occupied:
			action_lbl.text = "⟳"
		else:
			action_lbl.text = "✨"
		action_lbl.add_theme_font_size_override("font_size", 16)  # Reduced from 20
		action_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
		action_container.add_child(action_lbl)

	# Hover effects
	if selectable:
		var original_bg = card_style.bg_color
		card.mouse_entered.connect(func():
			card_style.bg_color = GameTheme.get_color("panel_dark")
			card_style.shadow_size = 12
			card.add_theme_stylebox_override("panel", card_style)
			# Scale animation
			var tween = create_tween()
			tween.tween_property(card, "scale", Vector2(1.01, 1.01), 0.1)
		)
		card.mouse_exited.connect(func():
			card_style.bg_color = original_bg
			card_style.shadow_size = 4 if not occupied else 0
			card.add_theme_stylebox_override("panel", card_style)
			var tween = create_tween()
			tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
		)
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
					_on_slot_selected(slot_idx, occupied)
		)

	return card

func _load_business_icon(business_id: String, fallback_emoji: String) -> Control:
	var asset_path = "res://assets/business_icons/" + business_id + ".png"
	if ResourceLoader.exists(asset_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(asset_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		return tex_rect
	
	var emoji_label = Label.new()
	emoji_label.text = fallback_emoji
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.apply_font(emoji_label, 16)
	return emoji_label

func _build_mini_stat_row(stats: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	
	var stat_order = [
		["money", "💰"],
		["reputation", "⭐"],
		["morale", "😊"],
		["stress", "😰"]
	]
	
	for stat in stat_order:
		var stat_container = HBoxContainer.new()
		stat_container.add_theme_constant_override("separation", 2)
		
		var icon = Label.new()
		icon.text = stat[1]
		GameTheme.apply_font(icon, 8)
		stat_container.add_child(icon)
		
		var val = stats.get(stat[0], 50)
		var val_lbl = Label.new()
		val_lbl.text = str(int(val))
		val_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(val_lbl, 8)
		stat_container.add_child(val_lbl)
		
		row.add_child(stat_container)
	
	return row

func _get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color("#ffd700")
		"A": return Color("#c8a84b")
		"B": return Color("#4a7c59")
		"C": return Color("#7c5c8a")
		"D": return Color("#8b3a3a")
	return GameTheme.get_color("dim")

# =========================================
# LOGIC
# =========================================
func _on_slot_selected(slot_index: int, occupied: bool) -> void:
	AudioManager.play_sfx("click")
	SaveManager.set_active_slot(slot_index)

	if mode == "continue":
		if SaveManager.load_slot(slot_index):
			get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")
		return

	if mode == "new_game":
		if occupied:
			_show_overwrite_confirm(slot_index)
		else:
			_go_to_business_selector(slot_index)

func _show_overwrite_confirm(slot_index: int) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.position = Vector2(0, 0)
	overlay.size = Vector2(screen_w, screen_h)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.1, screen_h * 0.25)
	panel.size = Vector2(screen_w * 0.8, screen_h * 0.5)
	panel.custom_minimum_size = panel.size
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = GameTheme.get_color("panel_dark")
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = GameTheme.get_color("accent")
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	vbox.add_theme_constant_override("margin_left", 24)
	vbox.add_theme_constant_override("margin_right", 24)
	vbox.add_theme_constant_override("margin_top", 24)
	vbox.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(vbox)

	var warning_icon = Label.new()
	warning_icon.text = "⚠️"
	warning_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameTheme.apply_font(warning_icon, 32)
	vbox.add_child(warning_icon)

	var warning = Label.new()
	warning.text = "OVERWRITE SAVE?"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	GameTheme.apply_font(warning, 16)
	vbox.add_child(warning)

	var slot = SaveManager.get_slot(slot_index)
	var biz_name = slot.get("business_name", "this save")
	var desc = Label.new()
	desc.text = "This will delete your " + biz_name + " save.\nThis action cannot be undone."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 10)
	vbox.add_child(desc)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(btn_row)

	var confirm_btn = GameTheme.build_button("⚠️  OVERWRITE", true, 12)
	confirm_btn.custom_minimum_size = Vector2(140, 44)
	GameTheme.connect_button(confirm_btn, func():
		overlay.queue_free()
		panel.queue_free()
		_go_to_business_selector(slot_index)
	)
	btn_row.add_child(confirm_btn)

	var cancel_btn = GameTheme.build_button("CANCEL", false, 12)
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	GameTheme.connect_button(cancel_btn, func():
		overlay.queue_free()
		panel.queue_free()
	)
	btn_row.add_child(cancel_btn)

func _go_to_business_selector(slot_index: int) -> void:
	SaveManager.set_active_slot(slot_index)
	get_tree().change_scene_to_file("res://scenes/business_selector.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
