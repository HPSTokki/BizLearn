extends Node

# =========================================
# CARD DECISIONS MINI-GAME
#
# Player sees business scenario cards.
# Two choices per card: tap LEFT or RIGHT button.
# Each choice has a hidden stat consequence.
# Score = total positive outcomes accumulated.
# 6 cards, no timer — purely decision quality.
# =========================================

# =========================================
# CONSTANTS
# =========================================
const CARDS_TOTAL = 6

# Each card: text, left_option, right_option,
# left_value (0.0-1.0), right_value (0.0-1.0)
# value = how "good" the choice is for score
const SCENARIO_DECK = [
	{
		"situation": "A supplier offers 20% off if you pay 3 months upfront.",
		"left_text":  "Pay upfront",
		"right_text": "Decline, keep cash",
		"left_value":  0.5,
		"right_value": 0.8,
		"left_hint":   "Locks up cash flow",
		"right_hint":  "Preserves flexibility",
	},
	{
		"situation": "A key employee asks for a raise after a strong month.",
		"left_text":  "Give the raise",
		"right_text": "Say not yet",
		"left_value":  0.9,
		"right_value": 0.3,
		"left_hint":   "Retains top talent",
		"right_hint":  "Risks losing them",
	},
	{
		"situation": "A negative review goes viral. You know the complaint is false.",
		"left_text":  "Respond publicly",
		"right_text": "Ignore it",
		"left_value":  0.9,
		"right_value": 0.2,
		"left_hint":   "Shows accountability",
		"right_hint":  "Silence looks guilty",
	},
	{
		"situation": "You can double your order quantity at a 15% cost savings.",
		"left_text":  "Double the order",
		"right_text": "Keep current size",
		"left_value":  0.7,
		"right_value": 0.6,
		"left_hint":   "Better margins",
		"right_hint":  "Less storage risk",
	},
	{
		"situation": "A competitor is spreading false rumors about your product.",
		"left_text":  "Address publicly",
		"right_text": "Let results speak",
		"left_value":  0.6,
		"right_value": 0.8,
		"left_hint":   "May escalate conflict",
		"right_hint":  "Quality wins over time",
	},
	{
		"situation": "High season is coming. Hire temp staff now or wait?",
		"left_text":  "Hire now",
		"right_text": "Wait and see",
		"left_value":  0.8,
		"right_value": 0.4,
		"left_hint":   "Ready for the rush",
		"right_hint":  "Risky if overwhelmed",
	},
	{
		"situation": "A customer wants a full refund after using 80% of the product.",
		"left_text":  "Partial refund",
		"right_text": "Full refund",
		"left_value":  0.6,
		"right_value": 0.8,
		"left_hint":   "Firm but fair",
		"right_hint":  "Builds loyalty",
	},
	{
		"situation": "You can cut costs by reducing packaging quality slightly.",
		"left_text":  "Cut costs",
		"right_text": "Keep quality",
		"left_value":  0.3,
		"right_value": 0.9,
		"left_hint":   "Visible to customers",
		"right_hint":  "Protects reputation",
	},
]

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer    = null
var card_panel:   PanelContainer = null
var situation_lbl: Label         = null
var progress_lbl: Label          = null
var score_lbl:    Label          = null
var hint_lbl:     Label          = null

# =========================================
# STATE
# =========================================
var screen_w:      float = 0.0
var screen_h:      float = 0.0
var current_index: int   = 0
var total_score:   float = 0.0
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


# =========================================
# BUILD
# =========================================
func _prepare_deck() -> void:
	deck = SCENARIO_DECK.duplicate()
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
	title.text = "BUSINESS DECISIONS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 24)
	header_row.add_child(title)

	score_lbl = Label.new()
	score_lbl.text = "⭐ 0"
	score_lbl.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(score_lbl, 16)
	header_row.add_child(score_lbl)

	# Progress
	progress_lbl = Label.new()
	progress_lbl.text = "Decision 1 of " + str(CARDS_TOTAL)
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_lbl.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(progress_lbl, 13)
	vbox.add_child(progress_lbl)

	# Instruction
	var instr = Label.new()
	instr.text = "Make the best business decision for each situation."
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(instr, 13)
	vbox.add_child(instr)

	# Divider
	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	# Spacer
	var sp1 = Control.new()
	sp1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sp1)

	# Scenario card
	card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(0, 100)
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)
	vbox.add_child(card_panel)

	var card_inner = VBoxContainer.new()
	card_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_inner.add_theme_constant_override("separation", 8)
	card_inner.add_theme_constant_override("margin_left",   16)
	card_inner.add_theme_constant_override("margin_right",  16)
	card_inner.add_theme_constant_override("margin_top",    14)
	card_inner.add_theme_constant_override("margin_bottom", 14)
	card_panel.add_child(card_inner)

	var situation_header = Label.new()
	situation_header.text = "SITUATION"
	situation_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	situation_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(situation_header, 12)
	card_inner.add_child(situation_header)

	situation_lbl = Label.new()
	situation_lbl.text = ""
	situation_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	situation_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	situation_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	situation_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	situation_lbl.add_theme_color_override("font_color", "#f2f2f2")
	GameTheme.apply_font(situation_lbl, 15)
	card_inner.add_child(situation_lbl)

	# Hint label (shows after choice)
	hint_lbl = Label.new()
	hint_lbl.text = ""
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.custom_minimum_size = Vector2(0, 24)
	hint_lbl.modulate.a = 0.0
	GameTheme.apply_font(hint_lbl, 13)
	vbox.add_child(hint_lbl)

	# Spacer
	var sp2 = Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(sp2)

	# Choice buttons — built dynamically in _show_card
	# Placeholder container
	var choice_vbox = VBoxContainer.new()
	choice_vbox.name = "ChoiceVBox"
	choice_vbox.add_theme_constant_override("separation", 8)
	choice_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(choice_vbox)


func _show_card(index: int) -> void:
	if index >= deck.size():
		_finish()
		return

	var card = deck[index]
	if situation_lbl:
		situation_lbl.text = card["situation"]
	if progress_lbl:
		progress_lbl.text = "Decision " + str(index + 1) + " of " + str(CARDS_TOTAL)

	hint_lbl.text = ""
	hint_lbl.modulate.a = 0.0

	# Rebuild choice buttons
	var choice_vbox = canvas.find_child("ChoiceVBox", true, false)
	if choice_vbox == null:
		return

	for child in choice_vbox.get_children():
		child.queue_free()

	await get_tree().process_frame

	# Left choice
	var left_btn = _build_choice_btn(card["left_text"], false)
	GameTheme.connect_button(left_btn, func(): _on_choice("left", index))
	choice_vbox.add_child(left_btn)

	# Right choice
	var right_btn = _build_choice_btn(card["right_text"], false)
	GameTheme.connect_button(right_btn, func(): _on_choice("right", index))
	choice_vbox.add_child(right_btn)

	# Animate card
	if card_panel:
		card_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)


func _build_choice_btn(text: String, is_primary: bool) -> PanelContainer:
	var btn = GameTheme.build_button("▸  " + text, is_primary)
	btn.custom_minimum_size = Vector2(0, GameTheme.BUTTON_H)
	return btn


# =========================================
# LOGIC
# =========================================
func _on_choice(side: String, card_index: int) -> void:
	if _done:
		return
	if card_index != current_index:
		return

	var card  = deck[card_index]
	var value = card["left_value"] if side == "left" else card["right_value"]
	var hint  = card["left_hint"]  if side == "left" else card["right_hint"]

	total_score += value
	var display_score = int(round(total_score / float(current_index + 1) * 10))
	if score_lbl:
		score_lbl.text = "⭐ " + str(display_score)

	# Show hint
	hint_lbl.text = hint
	hint_lbl.modulate.a = 1.0
	hint_lbl.add_theme_color_override("font_color",
		GameTheme.get_color("positive") if value >= 0.7
		else GameTheme.get_color("negative")
	)

	current_index += 1
	await get_tree().create_timer(0.5).timeout

	if current_index >= deck.size():
		_finish()
	else:
		_show_card(current_index)


func _finish() -> void:
	if _done:
		return
	_done = true

	var score = total_score / float(CARDS_TOTAL)
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
	_build_results_panel(result)


func _build_results_panel(result: Dictionary) -> void:
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
	header.text = "DECISIONS COMPLETE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(header, 12)
	vbox.add_child(header)

	var outcome_lbl = Label.new()
	outcome_lbl.text = result["label"].to_upper()
	outcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_lbl.add_theme_color_override("font_color", Color(result["color"]))
	GameTheme.apply_font(outcome_lbl, 24)
	vbox.add_child(outcome_lbl)

	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	var bonus_header = Label.new()
	bonus_header.text = "BONUSES EARNED"
	bonus_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(bonus_header, 12)
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
		GameTheme.apply_font(b, 14)
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
