extends Node

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0
var items_grid:   GridContainer = null
var gold_label:   Label         = null

# =========================================
# STATE
# =========================================
var from_scene:   String = ""  # tracks where to return to

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w   = get_viewport().get_visible_rect().size.x
	screen_h   = get_viewport().get_visible_rect().size.y
	from_scene = "analytics"  # default
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
	panel.position     = Vector2(screen_w * 0.04, screen_h * 0.04)
	panel.size         = Vector2(screen_w * 0.92, screen_h * 0.92)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    0)
	vbox.add_theme_constant_override("margin_left",   20)
	vbox.add_theme_constant_override("margin_right",  20)
	vbox.add_theme_constant_override("margin_top",    16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# Header row
	var header_row = HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text                 = "SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 14)
	header_row.add_child(title)

	# Gold display
	var gold_container = PanelContainer.new()
	gold_container.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid")
	)
	header_row.add_child(gold_container)

	var gold_hbox = HBoxContainer.new()
	gold_hbox.add_theme_constant_override("separation", 6)
	gold_container.add_child(gold_hbox)

	var gold_icon = Label.new()
	gold_icon.text = "🪙"
	GameTheme.apply_font(gold_icon, 14)
	gold_hbox.add_child(gold_icon)

	gold_label = Label.new()
	gold_label.text = str(DialogueManager.get_gold())
	gold_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(gold_label, 14)
	gold_hbox.add_child(gold_label)

	# Divider
	var divider               = ColorRect.new()
	divider.color             = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Gap
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	# Subtitle
	var sub = Label.new()
	sub.text = "Items apply at the start of the next day"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(sub, 8)
	vbox.add_child(sub)

	# Gap
	var gap2 = Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap2)

	# Scroll container for items
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	# Items grid
	items_grid = GridContainer.new()
	items_grid.columns = 2
	items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_grid.add_theme_constant_override("h_separation", 10)
	items_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(items_grid)

	_build_item_cards()

	# Gap
	var gap3 = Control.new()
	gap3.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap3)

	# Inventory section
	_build_inventory_section(vbox)

	# Gap
	var gap4 = Control.new()
	gap4.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap4)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK", true)
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)


func _build_item_cards() -> void:
	# Clear existing
	for child in items_grid.get_children():
		child.queue_free()

	var available = DialogueManager.get_available_items()

	if available.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No items available for Day " + \
						   str(DialogueManager.get_current_day()) + \
						   "\nCheck back after completing more days!"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(empty_label, 9)
		items_grid.add_child(empty_label)
		return

	for item in available:
		items_grid.add_child(_build_item_card(item))


func _build_item_card(item: Dictionary) -> PanelContainer:
	var card          = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    4)
	vbox.add_theme_constant_override("margin_left",   10)
	vbox.add_theme_constant_override("margin_right",  10)
	vbox.add_theme_constant_override("margin_top",    8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(vbox)

	# Top row — icon + name + price
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var icon = Label.new()
	icon.text = item.get("icon", "?")
	GameTheme.apply_font(icon, 16)
	top_row.add_child(icon)

	var name_label = Label.new()
	name_label.text                 = item.get("name", "").to_upper()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(name_label, 9)
	top_row.add_child(name_label)

	var price_label = Label.new()
	price_label.text = "🪙 " + str(item.get("price", 0))
	price_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(price_label, 9)
	top_row.add_child(price_label)

	# Description
	var desc = Label.new()
	desc.text          = item.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(desc, 7)
	vbox.add_child(desc)

	# Effects row
	var effects_row = HBoxContainer.new()
	effects_row.add_theme_constant_override("separation", 6)
	vbox.add_child(effects_row)

	var effects = item.get("effects", {})
	for stat in effects.keys():
		var val     = effects[stat]
		var eff_lbl = Label.new()
		eff_lbl.text = _stat_icon(stat) + \
					   ("+" if val >= 0 else "") + str(val)
		eff_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val >= 0
			else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(eff_lbl, 8)
		effects_row.add_child(eff_lbl)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Buy button
	var can_afford  = DialogueManager.get_gold() >= item.get("price", 0)
	var buy_btn     = GameTheme.build_button(
		"BUY" if can_afford else "NOT ENOUGH 🪙",
		can_afford
	)
	buy_btn.custom_minimum_size = Vector2(0, 32)
	GameTheme.connect_button(buy_btn, func():
		if DialogueManager.buy_item(item.get("id", "")):
			gold_label.text = str(DialogueManager.get_gold())
			_build_item_cards()
			_refresh_inventory()
	)
	vbox.add_child(buy_btn)

	return card


func _build_inventory_section(vbox: VBoxContainer) -> void:
	var inv_header = Label.new()
	inv_header.text = "— INVENTORY —"
	inv_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_header.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(inv_header, 9)
	vbox.add_child(inv_header)

	var inv_row = HBoxContainer.new()
	inv_row.name = "InventoryRow"
	inv_row.add_theme_constant_override("separation", 8)
	inv_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(inv_row)

	_populate_inventory_row(inv_row)


func _populate_inventory_row(row: HBoxContainer) -> void:
	for child in row.get_children():
		child.queue_free()

	var inventory = DialogueManager.get_inventory()

	if inventory.is_empty():
		var empty = Label.new()
		empty.text = "No items in inventory"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(empty, 8)
		row.add_child(empty)
		return

	for item_id in inventory:
		var item = DialogueManager._get_item_by_id(item_id)
		if item.is_empty():
			continue

		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.add_theme_stylebox_override("panel",
			GameTheme.make_panel_style("mid", 2)
		)

		var icon = Label.new()
		icon.text                 = item.get("icon", "?")
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		GameTheme.apply_font(icon, 18)
		slot.add_child(icon)
		row.add_child(slot)


func _refresh_inventory() -> void:
	var inv_row = canvas.find_child("InventoryRow", true, false)
	if inv_row:
		_populate_inventory_row(inv_row as HBoxContainer)


func _stat_icon(stat: String) -> String:
	match stat:
		"money":      return "💰"
		"reputation": return "⭐"
		"morale":     return "😊"
		"stress":     return "😰"
	return "?"


# =========================================
# CALLBACKS
# =========================================
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/analytics_scene.tscn")
