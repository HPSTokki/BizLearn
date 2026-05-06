extends Node

# =========================================
# BUSINESS SELECTOR
# Swipeable carousel of available businesses.
# =========================================

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0

# Carousel references
var cards_root:   Control       = null
var dot_row:      HBoxContainer = null
var left_arrow:   PanelContainer = null
var right_arrow:  PanelContainer = null
var select_btn:   PanelContainer = null
var lock_notice:  Label         = null

# =========================================
# STATE
# =========================================
var businesses:     Array = []
var current_index:  int   = 0
var _dragging:      bool  = false
var _drag_start_x:  float = 0.0
var _card_offset_x: float = 0.0
var _slot_index:    int   = 0

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w    = get_viewport().get_visible_rect().size.x
	screen_h    = get_viewport().get_visible_rect().size.y
	_slot_index = SaveManager.get_active_slot()
	businesses  = SaveManager.get_businesses_for_slot(_slot_index)
	_build_ui()
	_update_carousel()

# =========================================
# BUILD
# =========================================
func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	# Gradient background instead of solid color
	var gradient_bg = ColorRect.new()
	gradient_bg.position = Vector2(0, 0)
	gradient_bg.size = Vector2(screen_w, screen_h)
	
	var gradient_style = StyleBoxFlat.new()
	gradient_style.bg_color = GameTheme.get_color("bg")
	gradient_style.bg_color = Color(
		GameTheme.get_color("bg").r,
		GameTheme.get_color("bg").g,
		GameTheme.get_color("bg").b,
		1.0
	)
	# Add subtle gradient effect
	gradient_bg.material = _create_gradient_material()
	canvas.add_child(gradient_bg)

	# Main panel - cleaner look
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.03, screen_h * 0.03)
	panel.size = Vector2(screen_w * 0.94, screen_h * 0.94)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# Decorative top bar
	var top_decoration = HBoxContainer.new()
	top_decoration.alignment = BoxContainer.ALIGNMENT_CENTER
	top_decoration.add_theme_constant_override("separation", 4)
	vbox.add_child(top_decoration)
	
	var left_line = ColorRect.new()
	left_line.color = GameTheme.get_color("accent")
	left_line.custom_minimum_size = Vector2(40, 1)
	top_decoration.add_child(left_line)
	
	var star_icon = Label.new()
	star_icon.text = "✦"
	star_icon.add_theme_font_size_override("font_size", 12)
	star_icon.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	top_decoration.add_child(star_icon)
	
	var right_line = ColorRect.new()
	right_line.color = GameTheme.get_color("accent")
	right_line.custom_minimum_size = Vector2(40, 1)
	top_decoration.add_child(right_line)

	# Header
	var title = Label.new()
	title.text = "CHOOSE YOUR BUSINESS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 16)
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "Slot " + str(_slot_index + 1) + "  —  Swipe to browse"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub, 9)
	vbox.add_child(sub)

	# Divider
	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	var sp1 = Control.new()
	sp1.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(sp1)

	# Carousel area
	var carousel_row = HBoxContainer.new()
	carousel_row.add_theme_constant_override("separation", 8)
	carousel_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carousel_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(carousel_row)

	# Left arrow with hover effect
	left_arrow = _build_arrow_button("◂", true)
	carousel_row.add_child(left_arrow)

	# Card viewport
	var clip = Control.new()
	clip.clip_contents = true
	clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	carousel_row.add_child(clip)

	cards_root = Control.new()
	cards_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip.add_child(cards_root)

	# Build all business cards
	for i in range(businesses.size()):
		var card = _build_business_card(businesses[i], i)
		cards_root.add_child(card)

	# Right arrow
	right_arrow = _build_arrow_button("▸", false)
	carousel_row.add_child(right_arrow)

	# Dot indicators with animation
	dot_row = HBoxContainer.new()
	dot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dot_row.add_theme_constant_override("separation", 12)
	vbox.add_child(dot_row)
	_rebuild_dots()

	lock_notice = Label.new()
	lock_notice.text = ""
	lock_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_notice.custom_minimum_size = Vector2(0, 24)
	lock_notice.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	GameTheme.apply_font(lock_notice, 9)
	vbox.add_child(lock_notice)

	# Select button with pulsing animation when unlocked
	select_btn = GameTheme.build_button("✨  START HERE  ✨", true, 16)
	GameTheme.connect_button(select_btn, _on_select_pressed)
	vbox.add_child(select_btn)

	var back_btn = GameTheme.build_button("◂  BACK", false, 12)
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

	clip.gui_input.connect(_on_clip_input)

func _build_arrow_button(arrow_text: String, is_left: bool) -> PanelContainer:
	var btn = GameTheme.build_button(arrow_text, false, 24)
	btn.custom_minimum_size = Vector2(56, 56)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Make arrow button circular
	var style = StyleBoxFlat.new()
	style.bg_color = GameTheme.get_color("panel_dark")
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = GameTheme.get_color("accent")
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	btn.add_theme_stylebox_override("panel", style)
	
	# Center the label
	var lbl = btn.get_child(0) as Label
	if lbl:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	GameTheme.connect_button(btn, func(): _navigate(-1 if is_left else 1))
	return btn

func _build_business_card(biz: Dictionary, index: int) -> Control:
	var locked = biz.get("locked", false)
	var best_run = biz.get("best_run", {})
	var business_id = biz.get("id", "")

	var card = PanelContainer.new()
	card.name = "Card_" + str(index)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Card style with shadow effect
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = GameTheme.get_color("panel_mid")
	card_style.border_width_top = 2
	card_style.border_width_bottom = 2
	card_style.border_width_left = 2
	card_style.border_width_right = 2
	card_style.border_color = GameTheme.get_color("accent") if not locked else GameTheme.get_color("dim")
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	# Add shadow
	card_style.shadow_size = 4
	card_style.shadow_offset = Vector2(2, 2)
	card_style.shadow_color = Color(0, 0, 0, 0.5)
	card.add_theme_stylebox_override("panel", card_style)

	var inner = VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 8)
	inner.add_theme_constant_override("margin_left", 20)
	inner.add_theme_constant_override("margin_right", 20)
	inner.add_theme_constant_override("margin_top", 20)
	inner.add_theme_constant_override("margin_bottom", 20)
	card.add_child(inner)

	# Lock overlay
	if locked:
		var lock_overlay = ColorRect.new()
		lock_overlay.color = Color(0, 0, 0, 0.7)
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_overlay)
		
		var lock_lbl = Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		GameTheme.apply_font(lock_lbl, 48)
		lock_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
		card.add_child(lock_lbl)

	# Business Icon (with asset support + fallback)
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(80, 80)
	inner.add_child(icon_container)
	
	var asset_path = "res://assets/business_icons/" + business_id + ".png"
	var icon_node = _load_business_icon(asset_path, biz.get("icon", "🏪"))
	icon_container.add_child(icon_node)

	# Business name
	var name_lbl = Label.new()
	name_lbl.text = biz.get("name", "").to_upper()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color",
		GameTheme.get_color("accent") if not locked else GameTheme.get_color("dim")
	)
	GameTheme.apply_font(name_lbl, 18)
	inner.add_child(name_lbl)

	# Tagline
	var tagline = Label.new()
	tagline.text = biz.get("tagline", "")
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(tagline, 10)
	inner.add_child(tagline)

	# Difficulty stars with visual flair
	var diff = biz.get("difficulty", 1)
	var stars_container = HBoxContainer.new()
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_container.add_theme_constant_override("separation", 4)
	inner.add_child(stars_container)
	
	for i in range(5):
		var star = Label.new()
		star.text = "★" if i < diff else "☆"
		star.add_theme_font_size_override("font_size", 14)
		star.add_theme_color_override("font_color", 
			GameTheme.get_color("accent") if i < diff else GameTheme.get_color("dim")
		)
		stars_container.add_child(star)

	var div = ColorRect.new()
	div.color = GameTheme.get_color("panel_dark")
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(div)

	# Best run stats
	if not best_run.is_empty() and not locked:
		var best_container = VBoxContainer.new()
		best_container.add_theme_constant_override("separation", 4)
		inner.add_child(best_container)
		
		var best_header = Label.new()
		best_header.text = "🏆 BEST RUN"
		best_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		best_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(best_header, 8)
		best_container.add_child(best_header)

		var grade_lbl = Label.new()
		grade_lbl.text = "Grade " + best_run.get("grade", "—")
		grade_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grade_lbl.add_theme_color_override("font_color", _get_grade_color(best_run.get("grade", "D")))
		GameTheme.apply_font(grade_lbl, 20)
		best_container.add_child(grade_lbl)

		var best_stats = best_run.get("stats", {})
		if not best_stats.is_empty():
			best_container.add_child(_build_mini_stat_bars(best_stats))
	elif not locked:
		var no_run = Label.new()
		no_run.text = "✨ No runs yet — be the first! ✨"
		no_run.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_run.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(no_run, 9)
		inner.add_child(no_run)
	else:
		var req = biz.get("unlock_requires", {})
		if not req.is_empty():
			var req_biz_def = SaveManager.get_business_def(req.get("business_id", ""))
			var req_name = req_biz_def.get("name", "previous business")
			var req_grade = req.get("min_grade", "B")
			var unlock_lbl = Label.new()
			unlock_lbl.text = "🔓 Complete " + req_name + "\nwith Grade " + req_grade + " or above"
			unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unlock_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			unlock_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
			GameTheme.apply_font(unlock_lbl, 9)
			inner.add_child(unlock_lbl)

	return card

func _load_business_icon(asset_path: String, fallback_emoji: String) -> Control:
	if ResourceLoader.exists(asset_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(asset_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.size = Vector2(64, 64)
		return tex_rect
	
	# Fallback emoji
	var emoji_label = Label.new()
	emoji_label.text = fallback_emoji
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GameTheme.apply_font(emoji_label, 48)
	return emoji_label

func _get_grade_color(grade: String) -> Color:
	match grade:
		"S": return Color("#ffd700")
		"A": return Color("#c8a84b")
		"B": return Color("#4a7c59")
		"C": return Color("#7c5c8a")
		"D": return Color("#8b3a3a")
	return GameTheme.get_color("dim")

func _build_mini_stat_bars(stats: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)

	var stat_defs = [
		["money", "💰", GameTheme.get_color("money")],
		["reputation", "⭐", GameTheme.get_color("reputation")],
		["morale", "😊", GameTheme.get_color("morale")],
		["stress", "😰", GameTheme.get_color("stress")],
	]
	for sd in stat_defs:
		var col = VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)

		var icon = Label.new()
		icon.text = sd[1]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GameTheme.apply_font(icon, 10)
		col.add_child(icon)

		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = stats.get(sd[0], 50.0)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(32, 6)

		var fill = StyleBoxFlat.new()
		fill.bg_color = sd[2]
		fill.corner_radius_top_left = 3
		fill.corner_radius_top_right = 3
		fill.corner_radius_bottom_left = 3
		fill.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("fill", fill)

		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(1, 1, 1, 0.1)
		bg.corner_radius_top_left = 3
		bg.corner_radius_top_right = 3
		bg.corner_radius_bottom_left = 3
		bg.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("background", bg)
		col.add_child(bar)

		row.add_child(col)
	return row

func _create_gradient_material() -> ShaderMaterial:
	var shader_code = """
	shader_type canvas_item;
	
	uniform vec4 color_top : source_color = vec4(0.1, 0.08, 0.15, 1.0);
	uniform vec4 color_bottom : source_color = vec4(0.05, 0.04, 0.08, 1.0);
	
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

# Carousel logic (keep existing)
func _navigate(direction: int) -> void:
	var new_index = current_index + direction
	new_index = clamp(new_index, 0, businesses.size() - 1)
	if new_index == current_index:
		return
	current_index = new_index
	_update_carousel()

func _update_carousel() -> void:
	if cards_root == null:
		return

	for i in range(cards_root.get_child_count()):
		var card = cards_root.get_child(i)
		var target_x = (i - current_index) * cards_root.size.x
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUART)
		tween.tween_property(card, "position:x", target_x, 0.3)

	_rebuild_dots()
	_update_buttons()
	
	# Animate select button if unlocked
	var biz = businesses[current_index]
	if not biz.get("locked", false):
		var pulse = create_tween()
		pulse.set_loops()
		pulse.tween_property(select_btn, "scale", Vector2(1.02, 1.02), 0.5)
		pulse.tween_property(select_btn, "scale", Vector2(1.0, 1.0), 0.5)

func _rebuild_dots() -> void:
	if dot_row == null:
		return
	for child in dot_row.get_children():
		child.queue_free()

	for i in range(businesses.size()):
		var dot = PanelContainer.new()
		dot.custom_minimum_size = Vector2(8, 8)
		var dot_style = StyleBoxFlat.new()
		if i == current_index:
			dot_style.bg_color = GameTheme.get_color("accent")
			dot_style.corner_radius_top_left = 4
			dot_style.corner_radius_top_right = 4
			dot_style.corner_radius_bottom_left = 4
			dot_style.corner_radius_bottom_right = 4
			dot.custom_minimum_size = Vector2(12, 12)
		else:
			dot_style.bg_color = GameTheme.get_color("dim")
			dot_style.corner_radius_top_left = 4
			dot_style.corner_radius_top_right = 4
			dot_style.corner_radius_bottom_left = 4
			dot_style.corner_radius_bottom_right = 4
		dot.add_theme_stylebox_override("panel", dot_style)
		dot_row.add_child(dot)

func _update_buttons() -> void:
	var biz = businesses[current_index]
	var locked = biz.get("locked", false)

	if left_arrow:
		left_arrow.modulate.a = 0.4 if current_index == 0 else 1.0
	if right_arrow:
		right_arrow.modulate.a = 0.4 if current_index >= businesses.size() - 1 else 1.0

	if select_btn:
		var lbl = select_btn.get_child(0) as Label
		if locked:
			if lbl:
				lbl.text = "🔒  LOCKED"
			select_btn.modulate.a = 0.6
		else:
			if lbl:
				lbl.text = "✨  START HERE  ✨"
			select_btn.modulate.a = 1.0

	if lock_notice:
		if locked:
			var req = biz.get("unlock_requires", {})
			var req_biz = SaveManager.get_business_def(req.get("business_id", ""))
			lock_notice.text = "🔓 " + req_biz.get("name", "Previous business") + \
							   " Grade " + req.get("min_grade", "B") + " required"
		else:
			lock_notice.text = ""

func _on_clip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_start_x = event.position.x
			else:
				if _dragging:
					_dragging = false
					var delta = event.position.x - _drag_start_x
					if abs(delta) > 40:
						_navigate(-1 if delta < 0 else 1)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_drag_start_x = event.position.x
		else:
			if _dragging:
				_dragging = false
				var delta = event.position.x - _drag_start_x
				if abs(delta) > 40:
					_navigate(-1 if delta < 0 else 1)

func _process(_delta: float) -> void:
	if cards_root == null:
		return
	var clip = cards_root.get_parent()
	if clip == null:
		return
	var clip_size = clip.size
	if clip_size.x <= 0:
		return
	for i in range(cards_root.get_child_count()):
		var card = cards_root.get_child(i)
		card.size = clip_size
		if card.size.x > 0 and not _dragging:
			card.position.x = (i - current_index) * clip_size.x

func _on_select_pressed() -> void:
	var biz = businesses[current_index]
	if biz.get("locked", false):
		return

	var business_id = biz.get("id", "laundromat")
	var theme_id = biz.get("theme", business_id)
	GameTheme.set_theme(theme_id)

	print("Selected business: ", business_id)
	print("Theme set to: ", theme_id)

	SaveManager.start_new_game(SaveManager.get_active_slot(), business_id)
	get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/save_slot_screen.tscn")
