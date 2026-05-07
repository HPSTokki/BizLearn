extends Node

# =========================================
# CREDITS SCENE - Enhanced Mobile Version
# =========================================

# =========================================
# REFERENCES
# =========================================
var canvas:        CanvasLayer  = null
var screen_w:      float        = 0.0
var screen_h:      float        = 0.0
var content_area:  VBoxContainer = null
var active_tab:    int          = 0
var tab_buttons:   Array        = []

# =========================================
# DATA
# =========================================
const TABS = [
	"TEAM",
	"ART",
	"SFX",
	"THANKS"
]

const TAB_CONTENT = {
	"TEAM": [
		{"role": "DEVELOPED BY", "name": "Group 2 — SBIT3N", "icon": "💻"},
		{"role": "GAME DESIGN", "name": "Group 2 — SBIT3N", "icon": "🎮"},
		{"role": "PROGRAMMING", "name": "Group 2 — SBIT3N", "icon": "⚙️"},
		{"role": "PROJECT LEAD", "name": "TBA", "icon": "👑"},
		{"role": "TESTING", "name": "Classmates & Volunteers", "icon": "🐛"},
	],
	"ART": [
		{"role": "UI DESIGN", "name": "TBA", "icon": "🎨"},
		{"role": "CHARACTER ART", "name": "TBA", "icon": "👤"},
		{"role": "BACKGROUNDS", "name": "TBA", "icon": "🌆"},
		{"role": "PIXEL ART", "name": "TBA", "icon": "🖼️"},
		{"role": "ANIMATION", "name": "TBA", "icon": "🎬"},
	],
	"SFX": [
		{"role": "MUSIC", "name": "TBA", "icon": "🎵"},
		{"role": "SOUND EFFECTS", "name": "TBA", "icon": "🔊"},
		{"role": "VOICE", "name": "TBA", "icon": "🎙️"},
		{"role": "MIXING", "name": "TBA", "icon": "🎚️"},
	],
	"THANKS": [
		{"role": "PROFESSOR", "name": "Dr. Mary Jean M. Jayobo", "icon": "👩‍🏫"},
		{"role": "CLASSMATES", "name": "SBIT3N - QCU", "icon": "👥"},
		{"role": "TOOLS", "name": "Godot 4, Aseprite, VS Code", "icon": "🛠️"},
		{"role": "FONTS", "name": "Monogram by datagoblin", "icon": "🔤"},
		{"role": "INSPIRATION", "name": "Lapse: A Forgotten Future", "icon": "✨"},
	]
}

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
		particle.position = Vector2(randf_range(0, screen_w), randf_range(0, screen_h))
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle_layer.add_child(particle)
		
		var duration = randf_range(4, 8)
		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - randf_range(50, 150), duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

func _build_ui() -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.04, screen_h * 0.04)
	panel.size = Vector2(screen_w * 0.92, screen_h * 0.92)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
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
	
	var star_left = Label.new()
	star_left.text = "★"
	star_left.add_theme_font_size_override("font_size", 14)
	star_left.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	title_row.add_child(star_left)
	
	var title = Label.new()
	title.text = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 18)
	title_row.add_child(title)
	
	var star_right = Label.new()
	star_right.text = "★"
	star_right.add_theme_font_size_override("font_size", 14)
	star_right.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	title_row.add_child(star_right)

	# Divider
	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Game title
	var game_title = Label.new()
	game_title.text = "BIZLearn"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(game_title, 16)
	vbox.add_child(game_title)

	var game_sub = Label.new()
	game_sub.text = "Run it. Learn it. Own it."
	game_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(game_sub, 10)
	vbox.add_child(game_sub)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Tab bar
	vbox.add_child(_build_tab_bar())

	var tab_divider = ColorRect.new()
	tab_divider.color = GameTheme.get_color("accent")
	tab_divider.custom_minimum_size = Vector2(0, 1)
	tab_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_divider)

	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap)

	# Scrollable content area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	content_area = VBoxContainer.new()
	content_area.add_theme_constant_override("separation", 6)
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_area)

	var gap2 = Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap2)

	# Version
	var version = Label.new()
	version.text = "v1.0  —  Laundromat Release"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(version, 9)
	vbox.add_child(version)

	var gap3 = Control.new()
	gap3.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(gap3)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK TO MENU", true, 12)
	back_btn.custom_minimum_size = Vector2(screen_w * 0.4, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

	_switch_tab(0)

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
	var btn = GameTheme.build_button(label, index == active_tab, 12)
	btn.custom_minimum_size = Vector2(80, 34)
	GameTheme.connect_button(btn, func(): _switch_tab(index))
	return btn

func _switch_tab(index: int) -> void:
	active_tab = index

	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i] as PanelContainer
		var is_active = i == active_tab
		btn.add_theme_stylebox_override("panel",
			GameTheme.make_button_style("normal" if not is_active else "pressed", true)
		)
		var lbl = btn.get_child(0) as Label
		if lbl:
			lbl.add_theme_color_override("font_color",
				GameTheme.get_color("accent") if is_active else GameTheme.get_color("dim")
			)

	for child in content_area.get_children():
		child.queue_free()

	await get_tree().process_frame

	var tab_key = TABS[index]
	var items = TAB_CONTENT.get(tab_key, [])
	for item in items:
		content_area.add_child(_build_credit_card(item))

func _build_credit_card(credit: Dictionary) -> PanelContainer:
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
	icon.text = credit.get("icon", "📌")
	icon.add_theme_font_size_override("font_size", 18)
	icon.custom_minimum_size = Vector2(36, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Role text
	var role_label = Label.new()
	role_label.text = credit["role"]
	role_label.custom_minimum_size = Vector2(130, 0)
	role_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	role_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(role_label, 11)
	hbox.add_child(role_label)

	# Dot separator
	var dot = Label.new()
	dot.text = "•"
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.add_theme_color_override("font_color", GameTheme.get_color("panel_mid"))
	GameTheme.apply_font(dot, 12)
	hbox.add_child(dot)

	# Name (with highlight for special roles)
	var name_label = Label.new()
	name_label.text = credit["name"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Highlight "Group 2" entries
	if credit["name"].contains("Group 2"):
		name_label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
		GameTheme.apply_font(name_label, 12)
	else:
		name_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
		GameTheme.apply_font(name_label, 11)
	
	hbox.add_child(name_label)

	return card

# =========================================
# CALLBACKS
# =========================================
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
