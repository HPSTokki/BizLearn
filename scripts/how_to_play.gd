extends Node

# =========================================
# HOW TO PLAY - Tabbed Interface
# =========================================

# =========================================
# REFERENCES
# =========================================
var canvas:       CanvasLayer   = null
var screen_w:     float         = 0.0
var screen_h:     float         = 0.0
var content_area: VBoxContainer = null
var tab_buttons:  Array         = []

# =========================================
# DATA
# =========================================
var active_tab: int = 0

const TABS = [
	"GAMEPLAY",
	"STATS",
	"MINIGAMES",
	"GRADING"
]

const TAB_CONTENT = {
	"GAMEPLAY": [
		{"icon": "🎯", "title": "Objective", 
		 "text": "Run your business across 5 days. Make smart decisions to build a successful company."},
		{"icon": "💬", "title": "Dialogue", 
		 "text": "Tap anywhere on screen to advance dialogue. Choices appear at key moments."},
		{"icon": "🛒", "title": "Shop", 
		 "text": "Visit the shop between days. Buy items that boost your stats for the next day."},
		{"icon": "💾", "title": "Saving", 
		 "text": "Game auto-saves after every choice. Use 3 save slots to manage multiple businesses."},
		{"icon": "🏪", "title": "Businesses", 
		 "text": "Each business has unique theme and challenges. Complete one to unlock the next."},
	],
	"STATS": [
		{"icon": "💰", "title": "Money", 
		 "text": "Your cash flow and profits. Higher money means more resources for growth.", 
		 "color": "money"},
		{"icon": "⭐", "title": "Reputation", 
		 "text": "How customers perceive your business. High reputation attracts more customers.", 
		 "color": "reputation"},
		{"icon": "😊", "title": "Morale", 
		 "text": "Your team's happiness. High morale improves performance and reduces turnover.", 
		 "color": "morale"},
		{"icon": "😰", "title": "Stress", 
		 "text": "Your pressure level. High stress reduces effectiveness. Keep it LOW!", 
		 "color": "stress"},
	],
	"MINIGAMES": [
		{"icon": "📊", "title": "Budget Puzzle", 
		 "text": "Sort expenses into correct categories (Fixed, Variable, Investment). Test your financial knowledge."},
		{"icon": "⚖️", "title": "Resource Allocation", 
		 "text": "Distribute 100 budget points across 4 departments. Hit optimal targets for bonus stats."},
		{"icon": "🎴", "title": "Card Decisions", 
		 "text": "Business scenarios appear. Choose the best option. Good decisions = better outcomes."},
		{"icon": "🏆", "title": "Minigame Rewards", 
		 "text": "Better performance = higher stat bonuses. Great outcomes give significant boosts!"},
	],
	"GRADING": [
		{"icon": "👑", "title": "S Rank (80+ pts)", 
		 "text": "Business Mogul — Exceptional performance! Mastered all aspects of business.",
		 "color": "S"},
		{"icon": "⭐", "title": "A Rank (65-79 pts)", 
		 "text": "Thriving Enterprise — Strong performance. Solid business foundations.",
		 "color": "A"},
		{"icon": "✅", "title": "B Rank (50-64 pts)", 
		 "text": "Steady Business — Good work. Room for improvement.",
		 "color": "B"},
		{"icon": "📉", "title": "C Rank (35-49 pts)", 
		 "text": "Struggling Shop — Challenging run. Learning opportunity.",
		 "color": "C"},
		{"icon": "⚠️", "title": "D Rank (below 35 pts)", 
		 "text": "Barely Surviving — Business is tough. Balance your key stats next time.",
		 "color": "D"},
	]
}

const GRADE_COLORS = {
	"S": Color("#ffd700"),
	"A": Color("#c8a84b"),
	"B": Color("#6a9c78"),
	"C": Color("#9b6b9b"),
	"D": Color("#8b5a5a"),
}

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_build_canvas()
	_build_ui()
	_switch_tab(0)

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
	
	# Add subtle particles
	_add_ambient_particles()

func _add_ambient_particles() -> void:
	var particle_layer = CanvasLayer.new()
	particle_layer.layer = 5
	add_child(particle_layer)
	
	for i in range(15):
		var particle = ColorRect.new()
		var size = randf_range(1, 2)
		particle.size = Vector2(size, size)
		particle.color = Color(
			GameTheme.get_color("accent").r,
			GameTheme.get_color("accent").g,
			GameTheme.get_color("accent").b,
			randf_range(0.05, 0.1)
		)
		particle.position = Vector2(
			randf_range(0, screen_w),
			randf_range(0, screen_h)
		)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle_layer.add_child(particle)
		
		var duration = randf_range(4, 8)
		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - randf_range(50, 150), duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

func _build_ui() -> void:
	# Main panel
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
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 12)
	vbox.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(vbox)

	# Title
	var title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 8)
	vbox.add_child(title_row)
	
	var book_icon = Label.new()
	book_icon.text = "📖"
	book_icon.add_theme_font_size_override("font_size", 18)
	title_row.add_child(book_icon)
	
	var title = Label.new()
	title.text = "HOW TO PLAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 18)
	title_row.add_child(title)

	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Tab bar
	vbox.add_child(_build_tab_bar())

	# Tab divider
	var tab_divider = ColorRect.new()
	tab_divider.color = GameTheme.get_color("accent")
	tab_divider.custom_minimum_size = Vector2(0, 1)
	tab_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_divider)

	# Spacer
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	# Content area (scrollable)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	content_area = VBoxContainer.new()
	content_area.add_theme_constant_override("separation", 8)
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_area)

	# Spacer
	var gap2 = Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap2)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK TO MENU", true, 12)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.4, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

func _build_tab_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 4)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for i in range(TABS.size()):
		var tab_btn = _build_tab_button(TABS[i], i)
		tab_buttons.append(tab_btn)
		bar.add_child(tab_btn)

	return bar

func _build_tab_button(label: String, index: int) -> PanelContainer:
	var btn = GameTheme.build_button(label, index == active_tab, 11)
	btn.custom_minimum_size = Vector2(90, 36)
	GameTheme.connect_button(btn, func(): _switch_tab(index))
	return btn

func _switch_tab(index: int) -> void:
	active_tab = index

	# Update tab button styles
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as PanelContainer
		var is_active = i == active_tab
		btn.add_theme_stylebox_override("panel",
			GameTheme.make_button_style("normal" if not is_active else "pressed", true)
		)
		var lbl = btn.get_child(0) as Label
		if lbl:
			lbl.add_theme_color_override("font_color",
				GameTheme.get_color("accent") if is_active
				else GameTheme.get_color("dim")
			)

	# Clear content area
	for child in content_area.get_children():
		child.queue_free()

	await get_tree().process_frame
	
	var tab_key = TABS[index]
	var items = TAB_CONTENT.get(tab_key, [])
	
	for item in items:
		content_area.add_child(_build_info_card(item))

func _build_info_card(item: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 1)
	)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 12)
	hbox.add_theme_constant_override("margin_left", 12)
	hbox.add_theme_constant_override("margin_right", 12)
	hbox.add_theme_constant_override("margin_top", 10)
	hbox.add_theme_constant_override("margin_bottom", 10)
	card.add_child(hbox)

	# Icon
	var icon = Label.new()
	icon.text = item.get("icon", "📌")
	icon.add_theme_font_size_override("font_size", 20)
	icon.custom_minimum_size = Vector2(40, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Text content
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(text_vbox)

	var title_label = Label.new()
	title_label.text = item.get("title", "").to_upper()
	title_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title_label, 10)
	text_vbox.add_child(title_label)

	var body_label = Label.new()
	body_label.text = item.get("text", "")
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(body_label, 9)
	text_vbox.add_child(body_label)

	# Optional color indicator for grading
	if item.has("color"):
		var color_val = item.get("color", "")
		if color_val in GRADE_COLORS:
			var color_indicator = ColorRect.new()
			color_indicator.color = GRADE_COLORS[color_val]
			color_indicator.custom_minimum_size = Vector2(4, 0)
			color_indicator.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hbox.add_child(color_indicator)

	return card

# =========================================
# CALLBACKS
# =========================================
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
