extends Node

# =========================================
# RESOURCE ALLOCATION MINI-GAME
#
# Player distributes a fixed budget (100 pts)
# across 4 business areas using +/- buttons.
# Goal: hit target allocations within margin.
# Score = how close to optimal split.
# =========================================

# =========================================
# CONSTANTS
# =========================================
const TOTAL_BUDGET = 100
const TIME_LIMIT   = 30.0   # seconds

# Optimal allocation (sums to 100)
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

# =========================================
# REFERENCES
# =========================================
var canvas:      CanvasLayer = null
var timer_label: Label       = null
var budget_label: Label      = null
var remaining_label: Label   = null
var submit_btn:  PanelContainer = null
var area_rows:   Dictionary  = {}   # area_name → { value_label, minus_btn, plus_btn }

# =========================================
# STATE
# =========================================
var screen_w:    float      = 0.0
var screen_h:    float      = 0.0
var time_left:   float      = TIME_LIMIT
var allocations: Dictionary = {
	"Marketing":  25,
	"Operations":  25,
	"Staff":       25,
	"Inventory":   25,
}
var _done: bool = false

# =========================================
# LIFECYCLE
# =========================================
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
		if time_left <= 10:
			timer_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	if time_left <= 0:
		_submit()


# =========================================
# BUILD
# =========================================
func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg       = ColorRect.new()
	bg.color     = GameTheme.get_color("bg")
	bg.position  = Vector2(0, 0)
	bg.size      = Vector2(screen_w, screen_h)
	canvas.add_child(bg)

	# Main panel
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
	vbox.add_theme_constant_override("separation",    10)
	vbox.add_theme_constant_override("margin_left",   20)
	vbox.add_theme_constant_override("margin_right",  20)
	vbox.add_theme_constant_override("margin_top",    16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	# Header row
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = "BUDGET ALLOCATION"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 14)
	header_row.add_child(title)

	timer_label = Label.new()
	timer_label.text = "⏱ " + str(int(TIME_LIMIT)) + "s"
	timer_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(timer_label, 12)
	header_row.add_child(timer_label)

	# Instruction
	var instr = Label.new()
	instr.text = "Allocate your 100pt budget wisely across all departments."
	instr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instr.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(instr, 9)
	vbox.add_child(instr)

	# Divider
	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	# Budget remaining
	var budget_row = HBoxContainer.new()
	budget_row.add_theme_constant_override("separation", 8)
	vbox.add_child(budget_row)

	var budget_lbl_static = Label.new()
	budget_lbl_static.text = "REMAINING:"
	budget_lbl_static.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(budget_lbl_static, 9)
	budget_row.add_child(budget_lbl_static)

	remaining_label = Label.new()
	remaining_label.text = "0 pts"
	remaining_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(remaining_label, 12)
	budget_row.add_child(remaining_label)

	_update_remaining()

	# Area rows
	for area in ["Marketing", "Operations", "Staff", "Inventory"]:
		vbox.add_child(_build_area_row(area))

	# Visual bar
	vbox.add_child(_build_allocation_bars())

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Submit
	submit_btn = GameTheme.build_button("✓  SUBMIT ALLOCATION", true)
	GameTheme.connect_button(submit_btn, _submit)
	vbox.add_child(submit_btn)


func _build_area_row(area: String) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 52)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_theme_constant_override("margin_left",  10)
	hbox.add_theme_constant_override("margin_right", 10)
	hbox.add_theme_constant_override("margin_top",    6)
	hbox.add_theme_constant_override("margin_bottom", 6)
	card.add_child(hbox)

	# Icon + name
	var icon_lbl = Label.new()
	icon_lbl.text = AREA_ICONS[area]
	GameTheme.apply_font(icon_lbl, 14)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.text = area.to_upper()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(name_lbl, 10)
	hbox.add_child(name_lbl)

	# Minus button
	var minus_btn = GameTheme.build_button("−", false)
	minus_btn.custom_minimum_size = Vector2(40, 36)
	minus_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	GameTheme.connect_button(minus_btn, func(): _adjust(area, -5))
	hbox.add_child(minus_btn)

	# Value label
	var val_lbl = Label.new()
	val_lbl.text = str(allocations[area])
	val_lbl.custom_minimum_size = Vector2(40, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.add_theme_color_override("font_color", Color(AREA_COLORS[area]))
	GameTheme.apply_font(val_lbl, 14)
	hbox.add_child(val_lbl)

	# Plus button
	var plus_btn = GameTheme.build_button("+", false)
	plus_btn.custom_minimum_size = Vector2(40, 36)
	plus_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	GameTheme.connect_button(plus_btn, func(): _adjust(area, 5))
	hbox.add_child(plus_btn)

	area_rows[area] = {
		"value_label": val_lbl,
		"card":        card,
	}
	return card


var bars_container: HBoxContainer = null

func _build_allocation_bars() -> HBoxContainer:
	bars_container = HBoxContainer.new()
	bars_container.custom_minimum_size = Vector2(0, 20)
	bars_container.add_theme_constant_override("separation", 2)
	bars_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refresh_bars()
	return bars_container


func _refresh_bars() -> void:
	if bars_container == null:
		return
	for child in bars_container.get_children():
		child.queue_free()

	for area in ["Marketing", "Operations", "Staff", "Inventory"]:
		var val   = allocations[area]
		var bar   = ColorRect.new()
		bar.color = Color(AREA_COLORS[area])
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ratio = float(val) / float(TOTAL_BUDGET)
		bar.custom_minimum_size = Vector2(ratio * 20, 20)   # width hint
		bars_container.add_child(bar)


# =========================================
# LOGIC
# =========================================
func _adjust(area: String, delta: int) -> void:
	var remaining = _get_remaining()
	var new_val   = allocations[area] + delta

	if new_val < 0:
		return
	if delta > 0 and remaining < delta:
		return

	allocations[area] = new_val

	# Update label
	var row = area_rows[area]
	row["value_label"].text = str(new_val)

	_update_remaining()
	_refresh_bars()


func _get_remaining() -> int:
	var used = 0
	for area in allocations.keys():
		used += allocations[area]
	return TOTAL_BUDGET - used


func _update_remaining() -> void:
	var rem = _get_remaining()
	if remaining_label:
		remaining_label.text = str(rem) + " pts"
		if rem == 0:
			remaining_label.add_theme_color_override("font_color", GameTheme.get_color("positive"))
		elif rem < 0:
			remaining_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
		else:
			remaining_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))


func _submit() -> void:
	if _done:
		return
	_done = true

	# Score = average closeness across all areas
	var total_error = 0.0
	for area in OPTIMAL.keys():
		var diff  = abs(allocations[area] - OPTIMAL[area])
		total_error += float(diff) / float(OPTIMAL[area])
	var avg_error = total_error / float(OPTIMAL.size())
	var score     = clamp(1.0 - avg_error, 0.0, 1.0)

	_show_results(score)


func _show_results(score: float) -> void:
	MinigameManager.complete_minigame(score)

	var outcome  = MinigameManager._score_to_outcome(score)
	var result   = {
		"outcome":    outcome,
		"label":      MinigameManager.OUTCOME_LABELS[outcome],
		"color":      MinigameManager.OUTCOME_COLORS[outcome],
		"stat_bonus": MinigameManager.OUTCOME_BONUSES[outcome],
	}

	_build_results_panel(result)


func _build_results_panel(result: Dictionary) -> void:
	var overlay       = ColorRect.new()
	overlay.color     = Color(0, 0, 0, 0.75)
	overlay.position  = Vector2(0, 0)
	overlay.size      = Vector2(screen_w, screen_h)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var panel          = PanelContainer.new()
	panel.position     = Vector2(screen_w * 0.1, screen_h * 0.15)
	panel.size         = Vector2(screen_w * 0.8, screen_h * 0.7)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    24)
	vbox.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(vbox)

	var header = Label.new()
	header.text = "ALLOCATION COMPLETE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(header, 8)
	vbox.add_child(header)

	var outcome_lbl = Label.new()
	outcome_lbl.text = result["label"].to_upper()
	outcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_lbl.add_theme_color_override("font_color", Color(result["color"]))
	GameTheme.apply_font(outcome_lbl, 20)
	vbox.add_child(outcome_lbl)

	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	# Show your allocation vs optimal
	var compare_header = Label.new()
	compare_header.text = "YOUR ALLOCATION vs OPTIMAL"
	compare_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	compare_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(compare_header, 8)
	vbox.add_child(compare_header)

	for area in OPTIMAL.keys():
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.custom_minimum_size = Vector2(0, 24)
		vbox.add_child(row)

		var spacer_l = Control.new()
		spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_l)

		var icon = Label.new()
		icon.text = AREA_ICONS[area]
		GameTheme.apply_font(icon, 12)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)

		var name_l = Label.new()
		name_l.text = area
		name_l.custom_minimum_size = Vector2(90, 0)
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_l.add_theme_color_override("font_color", GameTheme.get_color("text"))
		GameTheme.apply_font(name_l, 9)
		row.add_child(name_l)

		var yours = allocations[area]
		var opt   = OPTIMAL[area]
		var diff  = yours - opt

		var yours_l = Label.new()
		yours_l.text = "You: " + str(yours)
		yours_l.custom_minimum_size = Vector2(60, 0)
		yours_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		yours_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		yours_l.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if abs(diff) <= 5
			else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(yours_l, 9)
		row.add_child(yours_l)

		var opt_l = Label.new()
		opt_l.text = "Best: " + str(opt)
		opt_l.custom_minimum_size = Vector2(60, 0)
		opt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		opt_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		opt_l.add_theme_color_override("font_color", GameTheme.get_color("dim"))
		GameTheme.apply_font(opt_l, 9)
		row.add_child(opt_l)

		var spacer_r = Control.new()
		spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_r)

	# Bonuses
	var bonus_row = HBoxContainer.new()
	bonus_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bonus_row.add_theme_constant_override("separation", 12)
	vbox.add_child(bonus_row)

	var stat_icons = { "money": "💰", "reputation": "⭐", "morale": "😊", "stress": "😰" }
	for stat in result["stat_bonus"].keys():
		var val = result["stat_bonus"][stat]
		if val == 0:
			continue
		var b_lbl = Label.new()
		b_lbl.text = stat_icons.get(stat, "") + " " + ("+" if val > 0 else "") + str(val)
		b_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val > 0 else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(b_lbl, 11)
		bonus_row.add_child(b_lbl)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var cont_btn = GameTheme.build_button("▸  CONTINUE", true)
	cont_btn.custom_minimum_size = Vector2(screen_w * 0.5, GameTheme.BUTTON_H)
	cont_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(cont_btn, _on_continue)
	vbox.add_child(cont_btn)

	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)


func _on_continue() -> void:
	MinigameManager.return_to_dialogue(MinigameManager.get_pending_next())
