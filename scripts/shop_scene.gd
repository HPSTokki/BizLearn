extends Node

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0
var items_grid:   GridContainer = null
var gold_label:   Label         = null
var pause_menu:   Node          = null
var burger_btn:   PanelContainer = null

# =========================================
# STATE
# =========================================
var from_scene:   String = ""

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	from_scene = "analytics"
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
	
	# Add subtle pattern overlay (optional)
	_add_pattern_overlay()

func _add_pattern_overlay() -> void:
	var pattern = ColorRect.new()
	pattern.color = Color(1, 1, 1, 0.02)
	pattern.position = Vector2(0, 0)
	pattern.size = Vector2(screen_w, screen_h)
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(pattern)

func _build_ui() -> void:
	# Main panel - slightly smaller, more breathing room
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.05, screen_h * 0.05)
	panel.size = Vector2(screen_w * 0.9, screen_h * 0.9)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# === HEADER SECTION ===
	_build_header(vbox)
	
	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)
	
	# Gap
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)
	
	# Subtitle with icon
	var sub_container = HBoxContainer.new()
	sub_container.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_container.add_theme_constant_override("separation", 6)
	vbox.add_child(sub_container)
	
	var info_icon = _load_or_create_icon("info_icon", "ℹ️", 12)
	sub_container.add_child(info_icon)
	
	var sub = Label.new()
	sub.text = "Items purchased apply at the start of the next day"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub, 9)
	sub_container.add_child(sub)
	
	# Gap
	var gap2 = Control.new()
	gap2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap2)

	# === ITEMS SECTION ===
	var items_label = Label.new()
	items_label.text = "— AVAILABLE ITEMS —"
	items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(items_label, 10)
	vbox.add_child(items_label)
	
	# Scroll container for items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_theme_constant_override("scroll_bar_h_separation", 4)
	vbox.add_child(scroll)

	# Items grid
	items_grid = GridContainer.new()
	items_grid.columns = 2
	items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_grid.add_theme_constant_override("h_separation", 12)
	items_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(items_grid)

	_build_item_cards()

	# Gap
	var gap3 = Control.new()
	gap3.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap3)

	# === INVENTORY SECTION ===
	_build_inventory_section(vbox)

	# Gap
	var gap4 = Control.new()
	gap4.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap4)

	# === BACK BUTTON ===
	var back_btn = GameTheme.build_button("◂  BACK TO ANALYTICS", true, 12)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.4, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

	_build_pause_menu()

func _build_header(vbox: VBoxContainer) -> void:
	# Top decorative line
	var top_deco = HBoxContainer.new()
	top_deco.alignment = BoxContainer.ALIGNMENT_CENTER
	top_deco.add_theme_constant_override("separation", 8)
	vbox.add_child(top_deco)
	
	var left_line = ColorRect.new()
	left_line.color = Color(GameTheme.get_color("accent"), 0.5)
	left_line.custom_minimum_size = Vector2(40, 1)
	top_deco.add_child(left_line)
	
	var shop_icon = _load_or_create_icon("shop_icon", "🛒", 14)
	top_deco.add_child(shop_icon)
	
	var right_line = ColorRect.new()
	right_line.color = Color(GameTheme.get_color("accent"), 0.5)
	right_line.custom_minimum_size = Vector2(40, 1)
	top_deco.add_child(right_line)
	
	# Header row: Title + Gold
	var header_row = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 16)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = "GENERAL STORE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 18)
	header_row.add_child(title)

	# Gold display - pill style
	var gold_container = PanelContainer.new()
	gold_container.custom_minimum_size = Vector2(100, 36)
	gold_container.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("money")
	)
	header_row.add_child(gold_container)

	var gold_hbox = HBoxContainer.new()
	gold_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_hbox.add_theme_constant_override("separation", 6)
	gold_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gold_container.add_child(gold_hbox)

	var gold_icon = _load_or_create_icon("gold_icon", "🪙", 16)
	gold_hbox.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.text = str(DialogueManager.get_gold())
	gold_label.add_theme_color_override("font_color", GameTheme.get_color("money"))
	GameTheme.apply_font(gold_label, 16)
	gold_hbox.add_child(gold_label)

func _build_item_cards() -> void:
	for child in items_grid.get_children():
		child.queue_free()

	var available = DialogueManager.get_available_items()

	if available.is_empty():
		var empty_card = _build_empty_state()
		items_grid.add_child(empty_card)
		return

	for item in available:
		items_grid.add_child(_build_item_card(item))

func _build_empty_state() -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 24)
	vbox.add_theme_constant_override("margin_bottom", 24)
	card.add_child(vbox)
	
	var empty_icon = _load_or_create_icon("empty_box_icon", "📦", 32)
	vbox.add_child(empty_icon)
	
	var empty_label = Label.new()
	empty_label.text = "No items available"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(empty_label, 11)
	vbox.add_child(empty_label)
	
	var sub_label = Label.new()
	sub_label.text = "Check back after Day " + str(DialogueManager.get_current_day() + 1)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub_label, 8)
	vbox.add_child(sub_label)
	
	return card

func _build_item_card(item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 130)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	card.add_child(vbox)

	# Top row — icon + name + price
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_row)

	# Item icon (asset or emoji)
	var icon = _load_or_create_icon(item.get("id", ""), item.get("icon", "?"), 24)
	icon.custom_minimum_size = Vector2(32, 32)
	top_row.add_child(icon)

	var name_label = Label.new()
	name_label.text = item.get("name", "").to_upper()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(name_label, 11)
	top_row.add_child(name_label)

	var price_container = PanelContainer.new()
	price_container.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("money")
	)
	
	var price_hbox = HBoxContainer.new()
	price_hbox.add_theme_constant_override("separation", 4)
	price_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	price_container.add_child(price_hbox)
	
	var price_icon = _load_or_create_icon("gold_small", "🪙", 10)
	price_hbox.add_child(price_icon)
	
	var price_label = Label.new()
	price_label.text = str(item.get("price", 0))
	price_label.add_theme_color_override("font_color", GameTheme.get_color("money"))
	GameTheme.apply_font(price_label, 11)
	price_hbox.add_child(price_label)
	
	top_row.add_child(price_container)

	# Description
	var desc = Label.new()
	desc.text = item.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 8)
	vbox.add_child(desc)

	# Effects row (stat badges)
	var effects_row = HBoxContainer.new()
	effects_row.add_theme_constant_override("separation", 8)
	vbox.add_child(effects_row)

	var effects = item.get("effects", {})
	for stat in effects.keys():
		var val = effects[stat]
		var badge = PanelContainer.new()
		badge.add_theme_stylebox_override("panel",
			GameTheme.make_pill_style(stat)
		)
		
		var badge_hbox = HBoxContainer.new()
		badge_hbox.add_theme_constant_override("separation", 4)
		badge_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		badge.add_child(badge_hbox)
		
		var stat_icon = _load_or_create_icon(stat + "_small", _stat_icon(stat), 10)
		badge_hbox.add_child(stat_icon)
		
		var eff_lbl = Label.new()
		eff_lbl.text = ("+" if val >= 0 else "") + str(val)
		eff_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val >= 0
			else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(eff_lbl, 9)
		badge_hbox.add_child(eff_lbl)
		
		effects_row.add_child(badge)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buy button
	var can_afford = DialogueManager.get_gold() >= item.get("price", 0)
	var buy_btn = GameTheme.build_button(
		"BUY NOW" if can_afford else "INSUFFICIENT FUNDS",
		can_afford,
		10
	)
	buy_btn.custom_minimum_size = Vector2(0, 34)
	GameTheme.connect_button(buy_btn, func():
		if DialogueManager.buy_item(item.get("id", "")):
			gold_label.text = str(DialogueManager.get_gold())
			_build_item_cards()
			_refresh_inventory()
			# Optional: play buy sound
			# AudioManager.play_sound("buy")
	)
	vbox.add_child(buy_btn)

	return card

func _build_inventory_section(vbox: VBoxContainer) -> void:
	var inv_header = HBoxContainer.new()
	inv_header.alignment = BoxContainer.ALIGNMENT_CENTER
	inv_header.add_theme_constant_override("separation", 8)
	vbox.add_child(inv_header)
	
	var inv_left = ColorRect.new()
	inv_left.color = Color(GameTheme.get_color("accent"), 0.3)
	inv_left.custom_minimum_size = Vector2(30, 1)
	inv_header.add_child(inv_left)
	
	var inv_title = Label.new()
	inv_title.text = "INVENTORY"
	inv_title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(inv_title, 10)
	inv_header.add_child(inv_title)
	
	var inv_right = ColorRect.new()
	inv_right.color = Color(GameTheme.get_color("accent"), 0.3)
	inv_right.custom_minimum_size = Vector2(30, 1)
	inv_header.add_child(inv_right)

	var inv_row = HBoxContainer.new()
	inv_row.name = "InventoryRow"
	inv_row.alignment = BoxContainer.ALIGNMENT_CENTER
	inv_row.add_theme_constant_override("separation", 8)
	inv_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(inv_row)

	_populate_inventory_row(inv_row)

func _populate_inventory_row(row: HBoxContainer) -> void:
	for child in row.get_children():
		child.queue_free()

	var inventory = DialogueManager.get_inventory()

	if inventory.is_empty():
		var empty_container = HBoxContainer.new()
		empty_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var empty_icon = _load_or_create_icon("empty_inventory", "📭", 16)
		empty_container.add_child(empty_icon)
		
		var empty = Label.new()
		empty.text = "No items in inventory"
		empty.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(empty, 9)
		empty_container.add_child(empty)
		
		row.add_child(empty_container)
		return

	for item_id in inventory:
		var item = DialogueManager._get_item_by_id(item_id)
		if item.is_empty():
			continue

		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(56, 56)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.add_theme_stylebox_override("panel",
			GameTheme.make_pill_style("mid")
		)
		
		# Tooltip on hover (optional)
		slot.mouse_entered.connect(func():
			_show_tooltip(item.get("name", ""))
		)
		slot.mouse_exited.connect(func():
			_hide_tooltip()
		)

		var icon = _load_or_create_icon(item_id, item.get("icon", "?"), 24)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(icon)
		row.add_child(slot)

var tooltip_label: Label = null

func _show_tooltip(text: String) -> void:
	if tooltip_label == null:
		tooltip_label = Label.new()
		tooltip_label.add_theme_stylebox_override("normal",
			GameTheme.make_pill_style("dark")
		)
		tooltip_label.add_theme_font_size_override("font_size", 8)
		tooltip_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
		canvas.add_child(tooltip_label)
	
	tooltip_label.text = text
	tooltip_label.position = get_viewport().get_mouse_position() + Vector2(10, -20)
	tooltip_label.visible = true

func _hide_tooltip() -> void:
	if tooltip_label:
		tooltip_label.visible = false

func _refresh_inventory() -> void:
	var inv_row = canvas.find_child("InventoryRow", true, false)
	if inv_row:
		_populate_inventory_row(inv_row as HBoxContainer)

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

func _stat_icon(stat: String) -> String:
	match stat:
		"money":      return "💰"
		"reputation": return "⭐"
		"morale":     return "😊"
		"stress":     return "😰"
	return "?"

func _build_pause_menu() -> void:
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

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/analytics_scene.tscn")
