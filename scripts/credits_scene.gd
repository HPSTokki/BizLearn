extends Node

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
		["DEVELOPED BY",   "Group 2 — SBIT3N"],
		["GAME DESIGN",    "Group 2 — SBIT3N"],
		["PROGRAMMING",    "Group 2 — SBIT3N"],
		["PROJECT LEAD",   "TBA"],
	],
	"ART": [
		["UI DESIGN",      "TBA"],
		["CHARACTER ART",  "TBA"],
		["BACKGROUNDS",    "TBA"],
		["PIXEL ART",      "TBA"],
	],
	"SFX": [
		["MUSIC",          "TBA"],
		["SOUND EFFECTS",  "TBA"],
		["VOICE",          "TBA"],
	],
	"THANKS": [
		["PROFESSOR",      "Our professor"],
		["CLASSMATES",     "SBIT3N"],
		["TOOLS",          "Godot 4, Aseprite"],
		["FONTS",          "Monogram by datagoblin"],
		["INSPIRATION",    "Lapse: A Forgotten Future"],
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
	vbox.add_theme_constant_override("separation",    0)
	vbox.add_theme_constant_override("margin_left",   24)
	vbox.add_theme_constant_override("margin_right",  24)
	vbox.add_theme_constant_override("margin_top",    20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(vbox)

	# Title
	var title                  = Label.new()
	title.text                 = "CREDITS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 24)
	vbox.add_child(title)

	# Divider
	var divider               = ColorRect.new()
	divider.color             = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Game subtitle
	var game_title                  = Label.new()
	game_title.text                 = "BIZLearn"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(game_title, 20)
	vbox.add_child(game_title)

	var game_sub                  = Label.new()
	game_sub.text                 = "Run it.  Learn it.  Own it."
	game_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_sub.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(game_sub, 14)
	vbox.add_child(game_sub)

	# Spacing
	var gap              = Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap)

	# Tab bar
	vbox.add_child(_build_tab_bar())

	# Tab divider
	var tab_divider               = ColorRect.new()
	tab_divider.color             = GameTheme.get_color("accent")
	tab_divider.custom_minimum_size = Vector2(0, 2)
	tab_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tab_divider)

	# Spacing
	var gap2              = Control.new()
	gap2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap2)

	# Content area
	content_area = VBoxContainer.new()
	content_area.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 8)
	vbox.add_child(content_area)

	# Spacing
	var gap3              = Control.new()
	gap3.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(gap3)

	# Version
	var version                  = Label.new()
	version.text                 = "v0.2  —  Business 1: The Coffee Shop"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(version, 12)
	vbox.add_child(version)

	# Spacing
	var gap4              = Control.new()
	gap4.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(gap4)

	# Back button
	var back_btn = GameTheme.build_button("◂  BACK TO MENU", true)
	GameTheme.connect_button(back_btn, _on_back_pressed)
	vbox.add_child(back_btn)

	# Load first tab
	_switch_tab(0)


func _build_tab_bar() -> HBoxContainer:
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for i in range(TABS.size()):
		var tab_btn = _build_tab_button(TABS[i], i)
		tab_buttons.append(tab_btn)
		bar.add_child(tab_btn)

	return bar


func _build_tab_button(label: String, index: int) -> PanelContainer:
	var btn = GameTheme.build_button(label, index == active_tab, 16)
	GameTheme.connect_button(btn, func(): _switch_tab(index))
	return btn


# =========================================
# TAB LOGIC
# =========================================
func _switch_tab(index: int) -> void:
	active_tab = index

	# Update tab button styles
	for i in range(tab_buttons.size()):
		var btn    = tab_buttons[i] as PanelContainer
		var is_active = i == active_tab
		btn.add_theme_stylebox_override("panel",
			GameTheme.make_button_style("normal" if not is_active else "pressed", true)
		)
		# Update label color
		var lbl = btn.get_child(0) as Label
		if lbl:
			lbl.add_theme_color_override("font_color",
				GameTheme.get_color("accent") if is_active
				else GameTheme.get_color("dim")
			)

	# Clear content area
	for child in content_area.get_children():
		child.queue_free()

	# Build content for active tab
	await get_tree().process_frame
	var tab_key    = TABS[index]
	var rows       = TAB_CONTENT.get(tab_key, [])
	for row in rows:
		content_area.add_child(_build_credit_row(row[0], row[1]))


# =========================================
# BUILD HELPERS
# =========================================
func _build_credit_row(role: String, name: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 32)

	# Role label
	var role_label                  = Label.new()
	role_label.text                 = role
	role_label.custom_minimum_size  = Vector2(160, 0)
	role_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	role_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(role_label, 16)
	row.add_child(role_label)

	# Dot separator
	var dot                  = Label.new()
	dot.text                 = "—"
	dot.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	dot.add_theme_color_override("font_color", GameTheme.get_color("panel_mid"))
	GameTheme.apply_font(dot, 12)
	row.add_child(dot)

	# Name label
	var name_label                   = Label.new()
	name_label.text                  = name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(name_label, 16)
	row.add_child(name_label)

	return row


# =========================================
# CALLBACKS
# =========================================
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
