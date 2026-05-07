extends Node

# =========================================
# BUDGET PUZZLE MINI-GAME
# 2-column layout, large fonts, compact controls
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

var canvas:         CanvasLayer     = null
var timer_label:    Label           = null
var score_label:    Label           = null
var card_text_lbl:  Label           = null
var progress_label: Label           = null
var feedback_lbl:   Label           = null

var screen_w:      float = 0.0
var screen_h:      float = 0.0
var time_left:     float = TIME_LIMIT
var current_index: int   = 0
var correct_count: int   = 0
var deck:          Array = []
var _done:         bool  = false

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

func _prepare_deck() -> void:
	deck = EXPENSE_DECK.duplicate()
	deck.shuffle()
	deck = deck.slice(0, CARDS_TOTAL)

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
	title.text = "BUDGET PUZZLE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 16)
	header_row.add_child(title)

	timer_label = Label.new()
	timer_label.text = "⏱ " + str(int(TIME_LIMIT)) + "s"
	timer_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(timer_label, 14)
	header_row.add_child(timer_label)

	# Progress row
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	vbox.add_child(info_row)

	progress_label = Label.new()
	progress_label.text = "1 / " + str(CARDS_TOTAL)
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(progress_label, 11)
	info_row.add_child(progress_label)

	score_label = Label.new()
	score_label.text = "✓ 0"
	score_label.add_theme_color_override("font_color", GameTheme.get_color("positive"))
	GameTheme.apply_font(score_label, 13)
	info_row.add_child(score_label)

	# Expense card
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 80)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)
	vbox.add_child(card_panel)

	var card_vbox = VBoxContainer.new()
	card_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_vbox.add_theme_constant_override("separation", 6)
	card_vbox.add_theme_constant_override("margin_left", 12)
	card_vbox.add_theme_constant_override("margin_right", 12)
	card_vbox.add_theme_constant_override("margin_top", 10)
	card_vbox.add_theme_constant_override("margin_bottom", 10)
	card_panel.add_child(card_vbox)

	var expense_header = Label.new()
	expense_header.text = "EXPENSE"
	expense_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expense_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(expense_header, 9)
	card_vbox.add_child(expense_header)

	card_text_lbl = Label.new()
	card_text_lbl.text = ""
	card_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text_lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(card_text_lbl, 16)
	card_vbox.add_child(card_text_lbl)

	# Feedback line
	feedback_lbl = Label.new()
	feedback_lbl.text = ""
	feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_lbl.custom_minimum_size = Vector2(0, 28)
	feedback_lbl.modulate.a = 0.0
	GameTheme.apply_font(feedback_lbl, 11)
	vbox.add_child(feedback_lbl)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# 2-COLUMN CATEGORY BUTTONS
	var category_grid = GridContainer.new()
	category_grid.columns = 2
	category_grid.add_theme_constant_override("h_separation", 10)
	category_grid.add_theme_constant_override("v_separation", 8)
	category_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(category_grid)

	for cat in CATEGORIES:
		category_grid.add_child(_build_category_btn(cat))

	var submit_spacer = Control.new()
	submit_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(submit_spacer)

func _build_category_btn(category: String) -> PanelContainer:
	var color = Color(CATEGORY_COLORS[category])
	var icon = CATEGORY_ICONS[category]

	var style = StyleBoxFlat.new()
	style.bg_color = GameTheme.get_color("panel_mid")
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	var btn = PanelContainer.new()
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("panel", style)

	var lbl = Label.new()
	lbl.text = icon + "  " + category.to_upper()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", color)
	GameTheme.apply_font(lbl, 14)
	btn.add_child(lbl)

	btn.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_on_category_selected(category)
	)
	return btn

func _show_card(index: int) -> void:
	if index >= deck.size():
		_finish()
		return
	var card = deck[index]
	if card_text_lbl:
		card_text_lbl.text = card["text"]
	if progress_label:
		progress_label.text = str(index + 1) + " / " + str(CARDS_TOTAL)

func _on_category_selected(category: String) -> void:
	if _done:
		return
	if current_index >= deck.size():
		return

	var card = deck[current_index]
	var correct = card["category"] == category

	if correct:
		correct_count += 1
		score_label.text = "✓ " + str(correct_count)
		_flash_feedback("✓ Correct!", GameTheme.get_color("positive"))
	else:
		_flash_feedback("✗ " + card["category"], GameTheme.get_color("negative"))

	current_index += 1

	if current_index >= deck.size():
		await get_tree().create_timer(0.5).timeout
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
	vbox.add_theme_constant_override("separation", 10)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 16)
	vbox.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(vbox)

	var outcome_lbl = Label.new()
	outcome_lbl.text = result["label"].to_upper()
	outcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_lbl.add_theme_color_override("font_color", Color(result["color"]))
	GameTheme.apply_font(outcome_lbl, 22)
	vbox.add_child(outcome_lbl)

	var score_lbl = Label.new()
	score_lbl.text = str(correct_count) + " / " + str(CARDS_TOTAL) + " correct"
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(score_lbl, 12)
	vbox.add_child(score_lbl)

	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	var bonus_header = Label.new()
	bonus_header.text = "BONUSES"
	bonus_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(bonus_header, 10)
	vbox.add_child(bonus_header)

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
		b_lbl.text = stat_icons.get(stat, "") + ("+" if val > 0 else "") + str(val)
		b_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val > 0 else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(b_lbl, 13)
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
