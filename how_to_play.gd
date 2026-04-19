extends Node

# =========================================
# REFERENCES
# =========================================
var canvas:   CanvasLayer = null
var screen_w: float       = 0.0
var screen_h: float       = 0.0

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
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
	panel.position     = Vector2(screen_w * 0.05, screen_h * 0.05)
	panel.size         = Vector2(screen_w * 0.9, screen_h * 0.9)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation",    12)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(vbox)

	# Title
	var title                  = Label.new()
	title.text                 = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	vbox.add_child(title)

	# Divider
	var divider               = ColorRect.new()
	divider.color             = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Sections
	var sections = [
		[
			"🎯  OBJECTIVE",
			"Run your business across 5 days. Every decision affects your stats. Reach the end with the best grade possible."
		],
		[
			"💬  DIALOGUE",
			"Tap the screen to advance dialogue. When choices appear, tap a button to make your decision. Choose wisely!"
		],
		[
			"📊  STATS",
			"💰 Money — your cash flow\n⭐ Reputation — how customers see you\n😊 Morale — your team happiness\n😰 Stress — your pressure level"
		],
		[
			"⚡  CHOICES",
			"Every choice has consequences. Some affect stats immediately. Others have lasting effects throughout the game."
		],
		[
			"🏆  GRADING",
			"S — Business Mogul\nA — Thriving Enterprise\nB — Steady Business\nC — Struggling Shop\nD — Barely Surviving"
		],
	]

	for section in sections:
		vbox.add_child(_build_section(section[0], section[1]))

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK TO MENU", true)
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)


func _build_section(title: String, body: String) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 9)
	title_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	container.add_child(title_label)

	var body_label                  = Label.new()
	body_label.text                 = body
	body_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.add_theme_font_size_override("font_size", 8)
	body_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	container.add_child(body_label)

	return container


func _build_back_button() -> Button:
	var btn                    = Button.new()
	btn.text                   = "◂  BACK TO MENU"
	btn.custom_minimum_size    = Vector2(0, 44)
	btn.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	GameTheme.apply_font(btn, 10)

	btn.add_theme_color_override("font_color",         GameTheme.get_color("bg"))
	btn.add_theme_color_override("font_color_hover",   GameTheme.get_color("text"))
	btn.add_theme_color_override("font_color_pressed", GameTheme.get_color("text"))

	btn.add_theme_stylebox_override("normal",  GameTheme.make_button_style("normal",  true))
	btn.add_theme_stylebox_override("hover",   GameTheme.make_button_style("hover",   true))
	btn.add_theme_stylebox_override("pressed", GameTheme.make_button_style("pressed", true))
	btn.add_theme_stylebox_override("focus",   GameTheme.make_button_style("focus",   true))

	btn.pressed.connect(_on_back_pressed)
	return btn


# =========================================
# CALLBACKS
# =========================================
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
