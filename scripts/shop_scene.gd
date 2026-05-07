extends Node

# =========================================
# SHOP SCENE - Compact & Item-Focused
# =========================================

var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0
var items_grid:   GridContainer = null
var gold_label:   Label         = null
var pause_menu:   Node          = null
var burger_btn:   PanelContainer = null
var scroll:       ScrollContainer = null

var from_scene:   String = ""

func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	from_scene = "analytics"
	_build_canvas()
	_build_ui()

func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = Vector2(screen_w, screen_h)
	canvas.add_child(bg)

func _build_ui() -> void:
	# Main panel - larger to give more space for items
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.02, screen_h * 0.02)
	panel.size = Vector2(screen_w * 0.96, screen_h * 0.96)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(vbox)

	# === COMPACT HEADER ===
	_build_compact_header(vbox)
	
	# Divider - thin
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Subtitle - compact
	var sub = Label.new()
	sub.text = "Items apply next day"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub, 8)
	vbox.add_child(sub)

	# === ITEMS GRID (MOST SPACE) ===
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	items_grid = GridContainer.new()
	items_grid.columns = 2
	items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_grid.add_theme_constant_override("h_separation", 8)
	items_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(items_grid)

	_build_item_cards()

	# === INVENTORY - COMPACT ===
	_build_compact_inventory(vbox)

	# === BACK BUTTON ===
	var back_btn = GameTheme.build_button("◂  BACK", true, 11)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.35, 36)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

	_build_pause_menu()

func _build_compact_header(vbox: VBoxContainer) -> void:
	# Simple header with title and gold
	var header_row = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 10)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = "🛒  SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 16)
	header_row.add_child(title)

	# Gold display - compact pill
	var gold_container = PanelContainer.new()
	gold_container.custom_minimum_size = Vector2(80, 30)
	gold_container.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("money")
	)
	header_row.add_child(gold_container)

	var gold_hbox = HBoxContainer.new()
	gold_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	gold_hbox.add_theme_constant_override("separation", 4)
	gold_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gold_container.add_child(gold_hbox)

	var gold_icon = _load_or_create_icon("gold_small", "🪙", 12)
	gold_hbox.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.text = str(DialogueManager.get_gold())
	gold_label.add_theme_color_override("font_color", GameTheme.get_color("money"))
	GameTheme.apply_font(gold_label, 14)
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
		items_grid.add_child(_build_compact_item_card(item))

func _build_empty_state() -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	card.add_child(vbox)
	
	var empty_icon = _load_or_create_icon("empty_box_icon", "📦", 28)
	vbox.add_child(empty_icon)
	
	var empty_label = Label.new()
	empty_label.text = "No items"
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(empty_label, 10)
	vbox.add_child(empty_label)
	
	return card

func _build_compact_item_card(item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 1)
	)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left", 8)
	vbox.add_theme_constant_override("margin_right", 8)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(vbox)

	# Row 1: Icon + Name + Price
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_row)

	var icon = _load_or_create_icon(item.get("id", ""), item.get("icon", "?"), 20)
	icon.custom_minimum_size = Vector2(28, 28)
	top_row.add_child(icon)

	var name_label = Label.new()
	name_label.text = item.get("name", "")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(name_label, 10)
	top_row.add_child(name_label)

	# Price pill
	var price_container = PanelContainer.new()
	price_container.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("money")
	)
	
	var price_hbox = HBoxContainer.new()
	price_hbox.add_theme_constant_override("separation", 3)
	price_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	price_container.add_child(price_hbox)
	
	var price_icon = _load_or_create_icon("gold_small", "🪙", 8)
	price_hbox.add_child(price_icon)
	
	var price_label = Label.new()
	price_label.text = str(item.get("price", 0))
	price_label.add_theme_color_override("font_color", GameTheme.get_color("money"))
	GameTheme.apply_font(price_label, 10)
	price_hbox.add_child(price_label)
	
	top_row.add_child(price_container)

	# Row 2: Description (single line)
	var desc = Label.new()
	desc.text = item.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 7)
	vbox.add_child(desc)

	# Row 3: Effects (horizontal badges) + Buy button
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 6)
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_row)

	# Effects badges
	var effects = item.get("effects", {})
	var effects_row = HBoxContainer.new()
	effects_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_row.add_theme_constant_override("separation", 4)
	bottom_row.add_child(effects_row)

	for stat in effects.keys():
		var val = effects[stat]
		var badge = PanelContainer.new()
		badge.add_theme_stylebox_override("panel",
			GameTheme.make_pill_style(stat)
		)
		
		var badge_hbox = HBoxContainer.new()
		badge_hbox.add_theme_constant_override("separation", 3)
		badge_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		badge.add_child(badge_hbox)
		
		var stat_icon = _load_or_create_icon(stat + "_small", _stat_icon(stat), 8)
		badge_hbox.add_child(stat_icon)
		
		var eff_lbl = Label.new()
		eff_lbl.text = ("+" if val >= 0 else "") + str(val)
		eff_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val >= 0
			else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(eff_lbl, 8)
		badge_hbox.add_child(eff_lbl)
		
		effects_row.add_child(badge)

	# Buy button - small
	var can_afford = DialogueManager.get_gold() >= item.get("price", 0)
	var buy_btn = GameTheme.build_button(
		"BUY" if can_afford else "—",
		can_afford,
		9
	)
	buy_btn.custom_minimum_size = Vector2(50, 28)
	GameTheme.connect_button(buy_btn, func():
		if DialogueManager.buy_item(item.get("id", "")):
			gold_label.text = str(DialogueManager.get_gold())
			_build_item_cards()
			_refresh_inventory()
			AudioManager.play_sfx("purchase")
	)
	bottom_row.add_child(buy_btn)

	return card

func _build_compact_inventory(vbox: VBoxContainer) -> void:
	var inv_row = HBoxContainer.new()
	inv_row.name = "InventoryRow"
	inv_row.alignment = BoxContainer.ALIGNMENT_CENTER
	inv_row.add_theme_constant_override("separation", 6)
	inv_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(inv_row)

	_populate_inventory_row(inv_row)

func _populate_inventory_row(row: HBoxContainer) -> void:
	for child in row.get_children():
		child.queue_free()

	var inventory = DialogueManager.get_inventory()

	if inventory.is_empty():
		var empty = Label.new()
		empty.text = "Inventory empty"
		empty.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(empty, 8)
		row.add_child(empty)
		return

	for item_id in inventory:
		var item = DialogueManager._get_item_by_id(item_id)
		if item.is_empty():
			continue

		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.add_theme_stylebox_override("panel",
			GameTheme.make_pill_style("mid")
		)
		
		slot.mouse_entered.connect(func():
			_show_tooltip(item.get("name", ""))
		)
		slot.mouse_exited.connect(func():
			_hide_tooltip()
		)

		var icon = _load_or_create_icon(item_id, item.get("icon", "?"), 18)
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
		tooltip_label.add_theme_font_size_override("font_size", 7)
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
	burger_btn.position = Vector2(screen_w - 36, 8)
	burger_btn.size = Vector2(28, 24)
	burger_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0.6)
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_color = GameTheme.get_color("accent")
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	burger_btn.add_theme_stylebox_override("panel", btn_style)
	
	var btn_lbl = Label.new()
	btn_lbl.text = "☰"
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_lbl.add_theme_font_size_override("font_size", 12)
	btn_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	burger_btn.add_child(btn_lbl)
	canvas.add_child(burger_btn)
	GameTheme.connect_button(burger_btn, _on_burger_pressed)

	pause_menu = load("res://scenes/pause_menu.tscn").instantiate()
	add_child(pause_menu)

func _on_burger_pressed() -> void:
	pause_menu.toggle()

func _on_back_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/analytics_scene.tscn")
