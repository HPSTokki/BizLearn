extends Node

# =========================================
# RESOURCE ALLOCATION MINI-GAME
# 2-column grid layout - no spilling!
# =========================================

const TOTAL_BUDGET = 100
const TIME_LIMIT   = 30.0

const OPTIMAL = {
	"Marketing":   30,
	"Operations":  25,
	"Staff":       30,
	"Inventory":   15,
}

const AREA_ICONS = {
	"Marketing":  "📢",
	"Operations": "⚙️",
	"Staff":      "👥",
	"Inventory":  "📦",
}

const AREA_COLORS = {
	"Marketing":  "#c8a84b",
	"Operations": "#7c5c8a",
	"Staff":      "#4a7c59",
	"Inventory":  "#3a5f8b",
}

var canvas:      CanvasLayer = null
var timer_label: Label       = null
var remaining_label: Label   = null
var area_rows:   Dictionary  = {}

var screen_w:    float = 0.0
var screen_h:    float = 0.0
var time_left:   float = TIME_LIMIT
var allocations: Dictionary = {
	"Marketing":  25,
	"Operations": 25,
	"Staff":      25,
	"Inventory":  25,
}
var _done: bool = false

func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_build_ui()

func _process(delta: float) -> void:
	if _done:
		return
	time_left -= delta
	if timer_label:
		timer_label.text = "⏱ " + str(int(ceil(time_left))) + "s"
		if time_left <= 8:
			timer_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	if time_left <= 0:
		_submit()

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = Vector2(screen_w, screen_h)
	canvas.add_child(bg)

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
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 10)
	vbox.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(vbox)

	# Header
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = "BUDGET ALLOCATION"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 26)
	header_row.add_child(title)

	timer_label = Label.new()
	timer_label.text = "⏱ " + str(int(TIME_LIMIT)) + "s"
	timer_label.add_theme_color_override("font_color", "#f2f2f2")
	GameTheme.apply_font(timer_label, 18)
	header_row.add_child(timer_label)

	var instr = Label.new()
	instr.text = "Allocate 100 points"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(instr, 16)
	vbox.add_child(instr)

	# Remaining budget pill
	var remaining_container = PanelContainer.new()
	remaining_container.add_theme_stylebox_override("panel",
		GameTheme.make_pill_style("accent")
	)
	remaining_container.custom_minimum_size = Vector2(0, 32)
	remaining_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(remaining_container)

	var remaining_row = HBoxContainer.new()
	remaining_row.alignment = BoxContainer.ALIGNMENT_CENTER
	remaining_row.add_theme_constant_override("separation", 6)
	remaining_container.add_child(remaining_row)

	var remaining_static = Label.new()
	remaining_static.text = "REMAINING:"
	remaining_static.add_theme_color_override("font_color", GameTheme.get_color("bg"))
	GameTheme.apply_font(remaining_static, 16)
	remaining_row.add_child(remaining_static)

	remaining_label = Label.new()
	remaining_label.text = "100"
	remaining_label.add_theme_color_override("font_color", GameTheme.get_color("bg"))
	GameTheme.apply_font(remaining_label, 18)
	remaining_row.add_child(remaining_label)

	# 2-COLUMN GRID for allocation rows
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	var areas = ["Marketing", "Operations", "Staff", "Inventory"]
	for area in areas:
		grid.add_child(_build_area_card(area))

	# Simple bar preview
	var bar_preview = HBoxContainer.new()
	bar_preview.add_theme_constant_override("separation", 2)
	bar_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_preview.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(bar_preview)

	for area in areas:
		var bar = ColorRect.new()
		bar.color = Color(AREA_COLORS[area])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_preview.add_child(bar)
		area_rows[area]["bar"] = bar
	_update_bars()

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var submit_btn = GameTheme.build_button("✓  SUBMIT", true, 14)
	submit_btn.custom_minimum_size = Vector2(0, 44)
	GameTheme.connect_button(submit_btn, _submit)
	submit_btn.add_theme_color_override("font_color", "#333333")
	vbox.add_child(submit_btn)

func _build_area_card(area: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
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

	# Icon + Name row
	var name_row = HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 6)
	vbox.add_child(name_row)

	var icon_lbl = Label.new()
	icon_lbl.text = AREA_ICONS[area]
	GameTheme.apply_font(icon_lbl, 18)
	name_row.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.text = area
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", "#f2f2f2")
	GameTheme.apply_font(name_lbl, 15)
	name_row.add_child(name_lbl)

	# Value controls row
	var control_row = HBoxContainer.new()
	control_row.alignment = BoxContainer.ALIGNMENT_CENTER
	control_row.add_theme_constant_override("separation", 8)
	vbox.add_child(control_row)

	var minus_btn = GameTheme.build_button("−", false, 16)
	minus_btn.custom_minimum_size = Vector2(40, 36)
	GameTheme.connect_button(minus_btn, func(): _adjust(area, -5))
	control_row.add_child(minus_btn)

	var val_lbl = Label.new()
	val_lbl.text = str(allocations[area])
	val_lbl.custom_minimum_size = Vector2(45, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.add_theme_color_override("font_color", Color(AREA_COLORS[area]))
	GameTheme.apply_font(val_lbl, 22)
	control_row.add_child(val_lbl)

	var plus_btn = GameTheme.build_button("+", false, 16)
	plus_btn.custom_minimum_size = Vector2(40, 36)
	GameTheme.connect_button(plus_btn, func(): _adjust(area, 5))
	control_row.add_child(plus_btn)

	area_rows[area] = {"value_label": val_lbl}
	return card

func _adjust(area: String, delta: int) -> void:
	var remaining = _get_remaining()
	var new_val = allocations[area] + delta

	if new_val < 0:
		return
	if delta > 0 and remaining < delta:
		return

	allocations[area] = new_val
	if area_rows.has(area):
		area_rows[area]["value_label"].text = str(new_val)

	_update_remaining()
	_update_bars()

func _get_remaining() -> int:
	var used = 0
	for area in allocations.keys():
		used += allocations[area]
	return TOTAL_BUDGET - used

func _update_remaining() -> void:
	var rem = _get_remaining()
	if remaining_label:
		remaining_label.text = str(rem)
		var color = GameTheme.get_color("positive") if rem == 0 else GameTheme.get_color("accent") if rem > 0 else GameTheme.get_color("negative")
		remaining_label.add_theme_color_override("font_color", color)

func _update_bars() -> void:
	for area in allocations.keys():
		if area_rows.has(area) and area_rows[area].has("bar"):
			var val = allocations[area]
			var ratio = float(val) / TOTAL_BUDGET
			area_rows[area]["bar"].custom_minimum_size = Vector2(max(2, ratio * 100), 12)

func _submit() -> void:
	if _done:
		return
	_done = true

	var total_error = 0.0
	for area in OPTIMAL.keys():
		var diff = abs(allocations[area] - OPTIMAL[area])
		total_error += float(diff) / float(OPTIMAL[area])
	var avg_error = total_error / float(OPTIMAL.size())
	var score = clamp(1.0 - avg_error, 0.0, 1.0)
	_show_results(score)

func _show_results(score: float) -> void:
	MinigameManager.complete_minigame(score)
	var outcome = MinigameManager._score_to_outcome(score)
	var result = {
		"outcome": outcome,
		"label": MinigameManager.OUTCOME_LABELS[outcome],
		"color": MinigameManager.OUTCOME_COLORS[outcome],
		"stat_bonus": MinigameManager.OUTCOME_BONUSES[outcome],
	}
	_build_results_panel(result)

func _build_results_panel(result: Dictionary) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.position = Vector2(0, 0)
	overlay.size = Vector2(screen_w, screen_h)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.05, screen_h * 0.1)
	panel.size = Vector2(screen_w * 0.9, screen_h * 0.8)
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

	var outcome_lbl = Label.new()
	outcome_lbl.text = result["label"].to_upper()
	outcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_lbl.add_theme_color_override("font_color", Color(result["color"]))
	GameTheme.apply_font(outcome_lbl, 24)
	vbox.add_child(outcome_lbl)

	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	# 2-column results grid
	var results_grid = GridContainer.new()
	results_grid.columns = 2
	results_grid.add_theme_constant_override("h_separation", 12)
	results_grid.add_theme_constant_override("v_separation", 8)
	results_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(results_grid)

	for area in OPTIMAL.keys():
		var row_container = HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 6)
		
		var icon = Label.new()
		icon.text = AREA_ICONS[area]
		GameTheme.apply_font(icon, 16)
		row_container.add_child(icon)

		var name_l = Label.new()
		name_l.text = area
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(name_l, 18)
		row_container.add_child(name_l)

		var yours = allocations[area]
		var opt = OPTIMAL[area]

		var yours_l = Label.new()
		yours_l.text = str(yours) + "/" + str(opt)
		yours_l.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if abs(yours - opt) <= 5 else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(yours_l, 16)
		row_container.add_child(yours_l)
		
		results_grid.add_child(row_container)

	var bonus_row = HBoxContainer.new()
	bonus_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bonus_row.add_theme_constant_override("separation", 10)
	vbox.add_child(bonus_row)

	var stat_icons = { "money": "💰", "reputation": "⭐", "morale": "😊", "stress": "😰" }
	for stat in result["stat_bonus"].keys():
		var val = result["stat_bonus"][stat]
		if val == 0:
			continue
		var b_lbl = Label.new()
		b_lbl.text = stat_icons.get(stat, "") + ("+" if val > 0 else "") + str(val)
		b_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val > 0 else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(b_lbl, 16)
		bonus_row.add_child(b_lbl)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var cont_btn = GameTheme.build_button("▸  CONTINUE", true, 14)
	cont_btn.custom_minimum_size = Vector2(screen_w * 0.5, 44)
	cont_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(cont_btn, _on_continue)
	vbox.add_child(cont_btn)

	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func _on_continue() -> void:
	MinigameManager.return_to_dialogue(MinigameManager.get_pending_next())
