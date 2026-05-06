extends PanelContainer

# =========================================
# STATUS HUD
# Fully theme-aware pill cards
# =========================================

const PILL_H      = 42.0
const PILL_MIN_W  = 80.0
const BAR_W       = 52.0
const BAR_H       = 8.0
const PILL_RADIUS = 12.0
const PILL_GAP    = 8.0

var stat_bars:  Dictionary = {}
var gold_label: Label      = null

func _ready() -> void:
	pass

func setup() -> void:
	_apply_panel_style()
	_build_hud()
	_connect_signals()

func _apply_panel_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	add_theme_stylebox_override("panel", style)

func _build_hud() -> void:
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", PILL_GAP)
	add_child(hbox)
	
	# Gold pill first
	hbox.add_child(_build_gold_pill())
	
	# Stat pills - use theme colors
	var stat_defs = [
		["money",      "💰", "Capital", "money"],
		["reputation", "⭐", "Rep",     "reputation"],
		["morale",     "😊", "Morale",  "morale"],
		["stress",     "😰", "Stress",  "stress"],
	]
	for s in stat_defs:
		hbox.add_child(_build_stat_pill(s[0], s[1], s[2], s[3]))

func _get_pill_style(accent_color_key: String = "accent") -> StyleBox:
	# Try to load pill texture from current theme
	var pill_asset_path = GameTheme._current.get("ui_folder", "") + "pill_bg.png"
	if ResourceLoader.exists(pill_asset_path):
		var style = StyleBoxTexture.new()
		style.texture = load(pill_asset_path)
		style.texture_margin_left = 10
		style.texture_margin_right = 10
		style.texture_margin_top = 8
		style.texture_margin_bottom = 8
		return style
	
	# Fallback to flat style using theme colors
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.65)
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(GameTheme.get_color(accent_color_key), 0.5)
	style.corner_radius_top_left = PILL_RADIUS
	style.corner_radius_top_right = PILL_RADIUS
	style.corner_radius_bottom_left = PILL_RADIUS
	style.corner_radius_bottom_right = PILL_RADIUS
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.shadow_size = 2
	style.shadow_color = Color(0, 0, 0, 0.3)
	return style

func _build_pill_container(accent_color_key: String = "accent") -> PanelContainer:
	var pill = PanelContainer.new()
	pill.custom_minimum_size = Vector2(PILL_MIN_W, PILL_H)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", _get_pill_style(accent_color_key))
	return pill

func _build_gold_pill() -> PanelContainer:
	var pill = _build_pill_container("money")
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 4)
	pill.add_child(hbox)
	
	# Gold icon (asset or emoji)
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(24, 24)
	hbox.add_child(icon_container)
	
	var gold_icon = _load_or_create_icon("gold_icon", "🪙", 18)
	icon_container.add_child(gold_icon)
	
	# Gold value label
	gold_label = Label.new()
	gold_label.text = "0g"
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.add_theme_font_size_override("font_size", 12)
	gold_label.add_theme_color_override("font_color", GameTheme.get_color("money"))
	GameTheme.apply_font(gold_label, 16)
	hbox.add_child(gold_label)
	
	return pill

func _build_stat_pill(stat_key: String, icon: String, display_name: String, color_key: String) -> PanelContainer:
	var pill = _build_pill_container(color_key)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	pill.add_child(vbox)
	
	# Top row: icon + name
	var top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 4)
	vbox.add_child(top_row)
	
	# Stat icon (asset or emoji)
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(20, 20)
	top_row.add_child(icon_container)
	
	var stat_icon = _load_or_create_icon(stat_key + "_icon", icon, 14)
	icon_container.add_child(stat_icon)
	
	# Stat name
	var name_lbl = Label.new()
	name_lbl.text = display_name
	name_lbl.add_theme_font_size_override("font_size", 8)
	name_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(name_lbl, 14)
	top_row.add_child(name_lbl)
	
	# Progress bar - using theme colors
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(BAR_W, BAR_H)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 50.0
	
	# Try to load custom bar texture from theme
	var bar_fill_path = GameTheme._current.get("ui_folder", "") + "bar_fill_" + stat_key + ".png"
	if ResourceLoader.exists(bar_fill_path):
		var fill_style = StyleBoxTexture.new()
		fill_style.texture = load(bar_fill_path)
		fill_style.texture_margin_left = 4
		fill_style.texture_margin_right = 4
		bar.add_theme_stylebox_override("fill", fill_style)
	else:
		# Use theme color for bar fill
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = GameTheme.get_color(color_key)
		fill_style.corner_radius_top_left = 3
		fill_style.corner_radius_top_right = 3
		fill_style.corner_radius_bottom_left = 3
		fill_style.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("fill", fill_style)
	
	# Bar background - try theme texture
	var bar_bg_path = GameTheme._current.get("ui_folder", "") + "bar_bg.png"
	if ResourceLoader.exists(bar_bg_path):
		var bg_style = StyleBoxTexture.new()
		bg_style.texture = load(bar_bg_path)
		bg_style.texture_margin_left = 4
		bg_style.texture_margin_right = 4
		bar.add_theme_stylebox_override("background", bg_style)
	else:
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(1, 1, 1, 0.1)
		bg_style.corner_radius_top_left = 3
		bg_style.corner_radius_top_right = 3
		bg_style.corner_radius_bottom_left = 3
		bg_style.corner_radius_bottom_right = 3
		bar.add_theme_stylebox_override("background", bg_style)
	
	vbox.add_child(bar)
	stat_bars[stat_key] = bar
	
	return pill

func _load_or_create_icon(asset_name: String, fallback_emoji: String, font_size: int) -> Control:
	# Try to load asset from current theme's UI folder
	var asset_path = GameTheme._current.get("ui_folder", "") + asset_name + ".png"
	if ResourceLoader.exists(asset_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(asset_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(font_size, font_size)
		return tex_rect
	
	# Fallback to emoji label
	var label = Label.new()
	label.text = fallback_emoji
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _connect_signals() -> void:
	if not DialogueManager.stats_changed.is_connected(_on_stats_changed):
		DialogueManager.stats_changed.connect(_on_stats_changed)
	if DialogueManager.has_signal("gold_changed"):
		if not DialogueManager.gold_changed.is_connected(_on_gold_changed):
			DialogueManager.gold_changed.connect(_on_gold_changed)
	_sync_all()

func _sync_all() -> void:
	for key in stat_bars.keys():
		stat_bars[key].value = DialogueManager.stats.get(key, 50.0)
	if gold_label:
		gold_label.text = str(DialogueManager.gold) + "g"

func update_stat(stat_name: String, new_value: float) -> void:
	if not stat_bars.has(stat_name):
		return
	
	var old_value = stat_bars[stat_name].value
	if old_value == new_value:
		return  # Skip tween if no change
	
	var tween = create_tween()
	tween.tween_property(stat_bars[stat_name], "value", new_value, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	# Flash effect using theme color - only if tween is valid
	var pill = stat_bars[stat_name].get_parent().get_parent().get_parent()
	if pill and pill is PanelContainer:
		var original_style = pill.get_theme_stylebox("panel")
		if original_style:
			var flash_tween = create_tween()
			flash_tween.tween_method(func(val): 
				var style = original_style.duplicate()
				if style is StyleBoxFlat:
					style.bg_color.a = 0.65 + val * 0.3
					pill.add_theme_stylebox_override("panel", style)
			, 0.0, 1.0, 0.15)
			flash_tween.tween_callback(func():
				pill.add_theme_stylebox_override("panel", original_style)
			)

func update_gold(value: int) -> void:
	if gold_label:
		var old_text = gold_label.text
		var new_text = str(value) + "g"
		if old_text == new_text:
			return  # Skip animation if no change
		
		gold_label.text = new_text
		
		# Pulse animation
		var tween = create_tween()
		tween.tween_property(gold_label, "scale", Vector2(1.15, 1.15), 0.1)
		tween.tween_property(gold_label, "scale", Vector2(1.0, 1.0), 0.1)

func _on_stats_changed(stat_name: String, new_value: float) -> void:
	update_stat(stat_name, new_value)

func _on_gold_changed(new_value: int) -> void:
	update_gold(new_value)
