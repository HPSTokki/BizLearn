extends CanvasLayer

# =========================================
# PAUSE MENU
# Burger menu overlay usable during dialogue,
# analytics, and shop scenes.
# =========================================

signal resume_pressed
signal quit_to_menu_pressed

# =========================================
# CONSTANTS
# =========================================
const COLOR_OVERLAY     = Color(0, 0, 0, 0.72)
const COLOR_PANEL       = Color("2d1f0f")
const COLOR_PANEL_EDGE  = Color("c8a84b")
const COLOR_TEXT        = Color("e8e0d0")
const COLOR_DIM         = Color("8a7a6a")
const COLOR_BTN_PRIMARY = Color("c8a84b")
const COLOR_BTN_DANGER  = Color("8b3a3a")
const COLOR_BTN_NEUTRAL = Color("3d2d1a")

# =========================================
# REFERENCES
# =========================================
var _overlay:       ColorRect      = null
var _panel:         PanelContainer = null
var _resume_btn:    PanelContainer = null
var _save_quit_btn: PanelContainer = null
var _exit_btn:      PanelContainer = null

var _screen_w: float = 0.0
var _screen_h: float = 0.0

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_screen_w = get_viewport().get_visible_rect().size.x
	_screen_h = get_viewport().get_visible_rect().size.y

	# Render on top of everything
	layer = 10

	# Pause menu should always process even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_overlay()
	_build_panel()

	# Start hidden
	visible = false


# =========================================
# BUILD
# =========================================
func _build_overlay() -> void:
	_overlay              = ColorRect.new()
	_overlay.color        = COLOR_OVERLAY
	_overlay.position     = Vector2(0, 0)
	_overlay.size         = Vector2(_screen_w, _screen_h)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Tapping the overlay = resume
	_overlay.gui_input.connect(_on_overlay_input)


func _build_panel() -> void:
	var panel_w: float = min(_screen_w * 0.78, 280.0)
	var panel_h: float = 220.0
	var px: float = (_screen_w  - panel_w) * 0.5
	var py: float = (_screen_h  - panel_h) * 0.5

	_panel          = PanelContainer.new()
	_panel.position = Vector2(px, py)
	_panel.size     = Vector2(panel_w, panel_h)

	var style                             = StyleBoxFlat.new()
	style.bg_color                        = COLOR_PANEL
	style.border_width_top                = 2
	style.border_width_bottom             = 2
	style.border_width_left               = 2
	style.border_width_right              = 2
	style.border_color                    = COLOR_PANEL_EDGE
	style.corner_radius_top_left          = 6
	style.corner_radius_top_right         = 6
	style.corner_radius_bottom_left       = 6
	style.corner_radius_bottom_right      = 6
	style.content_margin_top              = 16
	style.content_margin_bottom           = 16
	style.content_margin_left             = 16
	style.content_margin_right            = 16
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox                   = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# ── Title ──
	var title                      = Label.new()
	title.text                     = "☰  PAUSED"
	title.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_PANEL_EDGE)
	GameTheme.apply_font(title, 16)
	vbox.add_child(title)

	# ── Divider ──
	var div        = ColorRect.new()
	div.color      = Color(COLOR_PANEL_EDGE, 0.35)
	div.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(div)

	# ── Buttons ──
	_resume_btn    = _make_button("▶  Resume",       COLOR_BTN_PRIMARY, Color("2d1f0f"))
	_save_quit_btn = _make_button("💾  Save & Quit",  COLOR_BTN_NEUTRAL, COLOR_TEXT)
	_exit_btn      = _make_button("✕  Exit Game",    COLOR_BTN_DANGER,  COLOR_TEXT)

	vbox.add_child(_resume_btn)
	vbox.add_child(_save_quit_btn)
	vbox.add_child(_exit_btn)

	GameTheme.connect_button(_resume_btn,    _on_resume)
	GameTheme.connect_button(_save_quit_btn, _on_save_and_quit)
	GameTheme.connect_button(_exit_btn,      _on_exit)


func _make_button(label_text: String, bg: Color, fg: Color) -> PanelContainer:
	var btn                = PanelContainer.new()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.mouse_filter       = Control.MOUSE_FILTER_STOP

	var style                        = StyleBoxFlat.new()
	style.bg_color                   = bg
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_top         = 8
	style.content_margin_bottom      = 8
	style.content_margin_left        = 12
	style.content_margin_right       = 12
	btn.add_theme_stylebox_override("panel", style)

	var lbl                      = Label.new()
	lbl.text                     = label_text
	lbl.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment       = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", fg)
	GameTheme.apply_font(lbl, 16)
	btn.add_child(lbl)

	return btn


# =========================================
# PUBLIC API
# =========================================

## Call this to show the menu and pause the scene tree.
func open() -> void:
	visible = true
	get_tree().paused = true


## Call this to hide the menu and unpause.
func close() -> void:
	visible = false
	get_tree().paused = false


## Toggle open/close — handy for the burger button.
func toggle() -> void:
	if visible:
		close()
	else:
		open()


# =========================================
# CALLBACKS
# =========================================
func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
		emit_signal("resume_pressed")


func _on_resume() -> void:
	close()
	emit_signal("resume_pressed")


func _on_save_and_quit() -> void:
	# Save first, then go to menu — tree is still paused here
	DialogueManager.save_game()
	close()
	emit_signal("quit_to_menu_pressed")
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_exit() -> void:
	# Hard quit — no save prompt
	get_tree().quit()
