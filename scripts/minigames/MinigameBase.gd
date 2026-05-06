extends Node

# =========================================
# BASE CLASS for all mini-game scenes
# Each mini-game scene script extends this
# =========================================

# =========================================
# REFERENCES
# =========================================
var canvas:        CanvasLayer   = null
var results_panel: PanelContainer = null

var screen_w: float = 0.0
var screen_h: float = 0.0

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_build_base_canvas()
	_on_ready()


# Override in subclass
func _on_ready() -> void:
	pass


# =========================================
# BUILD BASE
# =========================================
func _build_base_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	var bg       = ColorRect.new()
	bg.color     = GameTheme.get_color("bg")
	bg.position  = Vector2(0, 0)
	bg.size      = Vector2(screen_w, screen_h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)


# =========================================
# RESULTS PANEL — called by subclass
# =========================================
func show_results(score: float) -> void:
	MinigameManager.complete_minigame(score)
	var result = {
		"outcome":    MinigameManager._score_to_outcome(score),
		"label":      MinigameManager.OUTCOME_LABELS[MinigameManager._score_to_outcome(score)],
		"color":      MinigameManager.OUTCOME_COLORS[MinigameManager._score_to_outcome(score)],
		"stat_bonus": MinigameManager.OUTCOME_BONUSES[MinigameManager._score_to_outcome(score)],
	}
	_build_results_panel(result)


func _build_results_panel(result: Dictionary) -> void:
	# Overlay
	var overlay       = ColorRect.new()
	overlay.color     = Color(0, 0, 0, 0.75)
	overlay.position  = Vector2(0, 0)
	overlay.size      = Vector2(screen_w, screen_h)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	# Panel
	results_panel          = PanelContainer.new()
	results_panel.position = Vector2(screen_w * 0.1, screen_h * 0.15)
	results_panel.size     = Vector2(screen_w * 0.8, screen_h * 0.7)
	results_panel.custom_minimum_size = results_panel.size
	results_panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(results_panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    12)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    24)
	vbox.add_theme_constant_override("margin_bottom", 24)
	results_panel.add_child(vbox)

	# Header
	var header = Label.new()
	header.text = "MINI-GAME COMPLETE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(header, 8)
	vbox.add_child(header)

	# Outcome label
	var outcome_lbl = Label.new()
	outcome_lbl.text = result["label"].to_upper()
	outcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_lbl.add_theme_color_override("font_color", Color(result["color"]))
	GameTheme.apply_font(outcome_lbl, 20)
	vbox.add_child(outcome_lbl)

	# Divider
	var div = ColorRect.new()
	div.color = GameTheme.get_color("accent")
	div.custom_minimum_size = Vector2(0, 2)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(div)

	# Bonuses section label
	var bonus_header = Label.new()
	bonus_header.text = "BONUSES EARNED"
	bonus_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(bonus_header, 8)
	vbox.add_child(bonus_header)

	# Stat bonus rows
	var bonuses = result["stat_bonus"]
	var stat_icons = {
		"money":      "💰",
		"reputation": "⭐",
		"morale":     "😊",
		"stress":     "😰",
	}
	for stat in bonuses.keys():
		var val = bonuses[stat]
		if val == 0:
			continue
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.custom_minimum_size = Vector2(0, 28)
		vbox.add_child(row)

		var spacer_l = Control.new()
		spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_l)

		var icon_lbl = Label.new()
		icon_lbl.text = stat_icons.get(stat, "?")
		GameTheme.apply_font(icon_lbl, 14)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon_lbl)

		var stat_lbl = Label.new()
		stat_lbl.text = stat.to_upper()
		stat_lbl.custom_minimum_size = Vector2(100, 0)
		stat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stat_lbl.add_theme_color_override("font_color", GameTheme.get_color("text"))
		GameTheme.apply_font(stat_lbl, 10)
		row.add_child(stat_lbl)

		var val_lbl = Label.new()
		val_lbl.text = ("+" if val > 0 else "") + str(val)
		val_lbl.custom_minimum_size = Vector2(48, 0)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val_lbl.add_theme_color_override("font_color",
			GameTheme.get_color("positive") if val > 0 else GameTheme.get_color("negative")
		)
		GameTheme.apply_font(val_lbl, 12)
		row.add_child(val_lbl)

		var spacer_r = Control.new()
		spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer_r)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Continue button
	var continue_btn = GameTheme.build_button("▸  CONTINUE", true)
	continue_btn.custom_minimum_size = Vector2(screen_w * 0.5, GameTheme.BUTTON_H)
	continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(continue_btn, _on_continue_pressed)
	vbox.add_child(continue_btn)

	# Animate panel in
	results_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(results_panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(
		results_panel, "position:y",
		screen_h * 0.15, 0.3
	).from(screen_h * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	overlay.modulate.a = 0.0
	var tween2 = create_tween()
	tween2.tween_property(overlay, "modulate:a", 1.0, 0.3)


func _on_continue_pressed() -> void:
	# Return to dialogue scene — DialogueManager resumes from pending next node
	var next_node = MinigameManager.get_pending_next()
	if next_node != "":
		# Load node directly in DialogueManager
		DialogueManager._load_node(next_node)
	get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")
