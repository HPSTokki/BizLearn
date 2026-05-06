extends Node

# =========================================
# BUDGET PUZZLE MINI-GAME
#
# Player is shown expense cards and must
# categorize each one by tapping the correct
# budget bucket. Correct = +points, Wrong = -points.
# 8 cards total, timed 25 seconds.
# =========================================

# =========================================
# CONSTANTS
# =========================================
const TIME_LIMIT   = 25.0
const CARDS_TOTAL  = 8

const CATEGORIES = ["Fixed", "Variable", "Investment"]

const CATEGORY_COLORS = {
	"Fixed":      "#c8a84b",
	"Variable":   "#7c5c8a",
	"Investment": "#4a7c59",
}

const CATEGORY_ICONS = {
	"Fixed":      "🏠",
	"Variable":   "📦",
	"Investment": "📈",
}

# expense text → correct category
const EXPENSE_DECK = [
	{ "text": "Monthly Rent",         "category": "Fixed"      },
	{ "text": "Staff Salaries",       "category": "Fixed"      },
	{ "text": "Raw Materials",        "category": "Variable"   },
	{ "text": "New Equipment",        "category": "Investment" },
	{ "text": "Electricity Bill",     "category": "Variable"   },
	{ "text": "Marketing Campaign",   "category": "Investment" },
	{ "text": "Insurance Premium",    "category": "Fixed"      },
	{ "text": "Packaging Supplies",   "category": "Variable"   },
	{ "text": "Staff Training",       "category": "Investment" },
	{ "text": "Internet & Phone",     "category": "Fixed"      },
	{ "text": "Delivery Costs",       "category": "Variable"   },
	{ "text": "Software Upgrade",     "category": "Investment" },
]

# =========================================
# REFERENCES
# =========================================
var canvas:         CanvasLayer     = null
var timer_label:    Label           = null
var score_label:    Label           = null
var card_panel:     PanelContainer  = null
var card_text_lbl:  Label           = null
var progress_label: Label           = null
var feedback_lbl:   Label           = null

# =========================================
# STATE
# =========================================
var screen_w:      float = 0.0
var screen_h:      float = 0.0
var time_left:     float = TIME_LIMIT
var current_index: int   = 0
var correct_count: int   = 0
var deck:          Array = []
var _done:         bool  = false

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_prepare_deck()
	_build_ui()
	_show_card(current_index)


func _process(delta: float) -> void:
	if _done:
		return
	time_left -= delta
	if timer_label:
		timer_label.text = "⏱ " + str(int(ceil(time_left))) + "s"
		if time_left <= 8:
			timer_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	if time_left <= 0:
		_finish()


# =========================================
# BUILD
# =========================================
func _prepare_deck() -> void:
	deck = EXPENSE_DECK.duplicate()
	deck.shuffle()
	deck = deck.slice(0, CARDS_TOTAL)


func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg       = ColorRect.new()
	bg.color     = GameTheme.get_color("bg")
	bg.position  = Vector2(0, 0)
	bg.size      = Vector2(screen_w, screen_h)
	canvas.add_child(bg)

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

	# Header
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = "BUDGET PUZZLE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 14)
	header_row.add_child(title)

	timer_label = Label.new()
	timer_label.text = "⏱ " + str(int(TIME_LIMIT)) + "s"
	timer_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(timer_label, 12)
	header_row.add_child(timer_label)

	# Progress + score row
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	vbox.add_child(info_row)

	progress_label = Label.new()
	progress_label.text = "1 / " + str(CARDS_TOTAL)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(progress_label, 9)
	info_row.add_child(progress_label)

	score_label = Label.new()
	score_label.text = "✓ 0"
	score_label.add_theme_color_override("font_color", GameTheme.get_color("positive"))
	GameTheme.apply_font(score_label, 12)
	info_row.add_child(score_label)

	# Instruction
	var instr = Label.new()
	instr.text = "Sort each expense into the correct budget category."
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

	# Spacer
	var spacer1 = Control.new()
	spacer1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer1)

	# Expense card
	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 80)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 3)
	)
	vbox.add_child(card_panel)

	var card_vbox = VBoxContainer.new()
	card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_vbox.add_theme_constant_override("margin_left",   16)
	card_vbox.add_theme_constant_override("margin_right",  16)
	card_vbox.add_theme_constant_override("margin_top",    12)
	card_vbox.add_theme_constant_override("margin_bottom", 12)
	card_panel.add_child(card_vbox)

	var card_q = Label.new()
	card_q.text = "EXPENSE"
	card_q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_q.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(card_q, 8)
	card_vbox.add_child(card_q)

	card_text_lbl = Label.new()
	card_text_lbl.text = ""
	card_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text_lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(card_text_lbl, 16)
	card_vbox.add_child(card_text_lbl)

	# Feedback label
	feedback_lbl = Label.new()
	feedback_lbl.text = ""
	feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_lbl.custom_minimum_size = Vector2(0, 24)
	GameTheme.apply_font(feedback_lbl, 10)
	vbox.add_child(feedback_lbl)

	# Spacer
	var spacer2 = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	# Category buttons
	for cat in CATEGORIES:
		vbox.add_child(_build_category_btn(cat))


func _build_category_btn(category: String) -> PanelContainer:
	var color = Color(CATEGORY_COLORS[category])
	var icon  = CATEGORY_ICONS[category]

	var style_flat = StyleBoxFlat.new()
	style_flat.bg_color                   = GameTheme.get_color("panel_mid")
	style_flat.border_width_top           = 2
	style_flat.border_width_bottom        = 2
	style_flat.border_width_left          = 2
	style_flat.border_width_right         = 2
	style_flat.border_color               = color
	style_flat.corner_radius_top_left     = 0
	style_flat.corner_radius_top_right    = 0
	style_flat.corner_radius_bottom_left  = 0
	style_flat.corner_radius_bottom_right = 0

	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(0, GameTheme.BUTTON_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("panel", style_flat)

	var lbl = Label.new()
	lbl.text = icon + "  " + category.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", color)
	GameTheme.apply_font(lbl, 12)
	btn.add_child(lbl)

	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_on_category_selected(category)
	)

	return btn


# =========================================
# LOGIC
# =========================================
func _show_card(index: int) -> void:
	if index >= deck.size():
		_finish()
		return
	var card = deck[index]
	if card_text_lbl:
		card_text_lbl.text = card["text"]
	if progress_label:
		progress_label.text = str(index + 1) + " / " + str(CARDS_TOTAL)

	# Animate card
	if card_panel:
		card_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(card_panel, "modulate:a", 1.0, 0.2)


func _on_category_selected(category: String) -> void:
	if _done:
		return
	if current_index >= deck.size():
		return

	var card     = deck[current_index]
	var correct  = card["category"] == category

	if correct:
		correct_count += 1
		score_label.text = "✓ " + str(correct_count)
		_flash_feedback("✓ Correct!", GameTheme.get_color("positive"))
	else:
		_flash_feedback("✗ " + card["category"] + " was correct", GameTheme.get_color("negative"))

	current_index += 1

	if current_index >= deck.size():
		await get_tree().create_timer(0.6).timeout
		_finish()
	else:
		await get_tree().create_timer(0.4).timeout
		_show_card(current_index)


func _flash_feedback(text: String, color: Color) -> void:
	if feedback_lbl == null:
		return
	feedback_lbl.text = text
	feedback_lbl.add_theme_color_override("font_color", color)
	feedback_lbl.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(feedback_lbl, "modulate:a", 0.0, 0.3)


func _finish() -> void:
	if _done:
		return
	_done = true

	var score = float(correct_count) / float(CARDS_TOTAL)
	_show_results(score)


# =========================================
# RESULTS
# =========================================
func _show_results(score: float) -> void:
	MinigameManager.complete_minigame(score)

	var outcome = MinigameManager._score_to_outcome(score)
	var result  = {
		"outcome":    outcome,
		"label":      MinigameManager.OUTCOME_LABELS[outcome],
		"color":      MinigameManager.OUTCOME_COLORS[outcome],
		"stat_bonus": MinigameManager.OUTCOME_BONUSES[outcome],
	}

	_build_results_panel(result, score)


func _build_results_panel(result: Dictionary, score: float) -> void:
	var overlay       = ColorRect.new()
	overlay.color     = Color(0, 0, 0, 0.75)
	overlay.position  = Vector2(0, 0)
	overlay.size      = Vector2(screen_w, screen_h)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var panel          = PanelContainer.new()
	panel.position     = Vector2(screen_w * 0.1, screen_h * 0.12)
	panel.size         = Vector2(screen_w * 0.8, screen_h * 0.76)
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
	header.text = "BUDGET PUZZLE COMPLETE"
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

	var score_lbl = Label.new()
	score_lbl.text = str(correct_count) + " / " + str(CARDS_TOTAL) + " correct"
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(score_lbl, 10)
	vbox.add_child(score_lbl)

	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	# Bonuses
	var bonus_header = Label.new()
	bonus_header.text = "BONUSES EARNED"
	bonus_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(bonus_header, 8)
	vbox.add_child(bonus_header)

	var bonus_row = HBoxContainer.new()
	bonus_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bonus_row.add_theme_constant_override("separation", 14)
	vbox.add_child(bonus_row)

	var stat_icons = { "money": "💰", "reputation": "⭐", "morale": "😊", "stress": "😰" }
	for stat in result["stat_bonus"].keys():
		var val = result["stat_bonus"][stat]
		if val == 0:
			continue
		var b = Label.new()
		b.text = stat_icons.get(stat, "") + " " + ("+" if val > 0 else "") + str(val)
		b.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val > 0 else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(b, 12)
		bonus_row.add_child(b)

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
