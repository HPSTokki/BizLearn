extends Node
# =========================================
# CONSTANTS
# =========================================
const COLOR_BG         = Color("#1a1a2e")
const COLOR_PANEL_DARK = Color("#2d2d3f")
const COLOR_PANEL_MID  = Color("#3d3d52")
const COLOR_ACCENT     = Color("#c8a84b")
const COLOR_PURPLE     = Color("#7c5c8a")
const COLOR_TEXT       = Color("#e8e0d0")
const COLOR_DIM        = Color("#8a8a9a")
# =========================================
# REFERENCES
# =========================================
var canvas:   CanvasLayer = null
var screen_w: float       = 0.0
var screen_h: float       = 0.0
# Particle state
var particles:            Array = []
const PARTICLE_COUNT            = 40
# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	GameTheme.set_theme("laundromat")
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y

	_build_canvas()
	_build_background()
	_build_particles()
	_build_logo_section()
	_build_buttons()
	_build_version_label()
# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

func _build_background() -> void:
	var bg = GameTheme.get_bg_for_scene(
		"shop_day",
		canvas,
		Vector2(screen_w, screen_h)
	)
	canvas.add_child(bg)

func _build_particles() -> void:
	for i in range(PARTICLE_COUNT):
		var p      = ColorRect.new()
		var size   = randf_range(2, 5)
		p.size     = Vector2(size, size)
		p.color    = Color(
			COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b,
			randf_range(0.1, 0.4)
		)
		p.position     = Vector2(randf_range(0, screen_w), randf_range(0, screen_h))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(p)
		particles.append({
			"node":  p,
			"speed": randf_range(10, 40),
			"drift": randf_range(-8, 8)
		})

func _build_logo_section() -> void:
	var logo_container          = VBoxContainer.new()
	logo_container.position     = Vector2(0, screen_h * 0.08)
	logo_container.size         = Vector2(screen_w, screen_h * 0.28)
	logo_container.alignment    = BoxContainer.ALIGNMENT_CENTER
	logo_container.add_theme_constant_override("separation", 8)
	canvas.add_child(logo_container)

	var logo_top                   = Label.new()
	logo_top.text                  = "— BIZ —"
	logo_top.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	logo_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo_top.add_theme_font_size_override("font_size", 10)
	logo_top.add_theme_color_override("font_color", COLOR_DIM)
	logo_container.add_child(logo_top)

	var logo_main                   = Label.new()
	logo_main.text                  = "BIZLearn"
	logo_main.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	logo_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo_main.add_theme_font_size_override("font_size", 48)
	logo_main.add_theme_color_override("font_color", COLOR_ACCENT)
	logo_container.add_child(logo_main)

	var underline               = ColorRect.new()
	underline.color             = COLOR_ACCENT
	underline.custom_minimum_size = Vector2(screen_w * 0.3, 2)
	underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_container.add_child(underline)

	var tagline                    = Label.new()
	tagline.text                    = "Run it.  Learn it.  Own it."
	tagline.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	tagline.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	tagline.add_theme_font_size_override("font_size", 10)
	tagline.add_theme_color_override("font_color", COLOR_DIM)
	logo_container.add_child(tagline)

func _build_buttons() -> void:
	SaveManager._load_all_slots()
	
	# Button container - centered, no card panel
	var btn_container = VBoxContainer.new()
	btn_container.position = Vector2(screen_w * 0.15, screen_h * 0.4)
	btn_container.size = Vector2(screen_w * 0.7, screen_h * 0.45)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 12)
	canvas.add_child(btn_container)
	
	var has_saves = SaveManager.has_any_save()
	
	# CONTINUE button (if save exists)
	if has_saves:
		var continue_btn = GameTheme.build_button("▶  CONTINUE", true, 18)
		continue_btn.custom_minimum_size = Vector2(screen_w * 0.5, 54)
		continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		GameTheme.connect_button(continue_btn, _on_continue_pressed)
		btn_container.add_child(continue_btn)
	
	# NEW GAME button
	var new_btn = GameTheme.build_button(
		"✨  " + ("NEW GAME" if has_saves else "START GAME") + "  ✨",
		not has_saves,
		18
	)
	new_btn.custom_minimum_size = Vector2(screen_w * 0.5, 54)
	new_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(new_btn, _on_new_game_pressed)
	btn_container.add_child(new_btn)
	
	# Spacer between main buttons and secondary row
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	btn_container.add_child(spacer)
	
	# Secondary buttons row (HOW TO, SETTINGS, CREDITS, EXIT)
	var secondary_row = HBoxContainer.new()
	secondary_row.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary_row.add_theme_constant_override("separation", 12)
	secondary_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_container.add_child(secondary_row)
	
	var small_btns = [
		{"text": "📖  HOW TO", "callback": _on_how_to_play_pressed},
		{"text": "⚙️  SETTINGS", "callback": _on_settings_pressed},
		{"text": "🎭  CREDITS", "callback": _on_credits_pressed},
		{"text": "✕  EXIT", "callback": _on_exit_pressed},
	]
	
	for btn_data in small_btns:
		var btn = GameTheme.build_button(btn_data.text, false, 12)
		btn.custom_minimum_size = Vector2(110, 40)
		GameTheme.connect_button(btn, btn_data.callback)
		secondary_row.add_child(btn)
	
	var leaderboard_btn = GameTheme.build_button("🏆  LEADERBOARD", false)
	GameTheme.connect_button(leaderboard_btn, _on_leaderboard_pressed)
	btn_container.add_child(leaderboard_btn)


func _build_version_label() -> void:
	var version                  = Label.new()
	version.text                 = "Beta v1.0  —  BIZLearn: The Laundromat Release"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.position             = Vector2(0, screen_h - 24)
	version.size                 = Vector2(screen_w, 16)
	version.add_theme_font_size_override("font_size", 7)
	version.add_theme_color_override("font_color", COLOR_PANEL_MID)
	canvas.add_child(version)

# =========================================
# PROCESS — particle animation
# =========================================
func _process(delta: float) -> void:
	for p in particles:
		var node = p["node"] as ColorRect
		node.position.y -= p["speed"] * delta
		node.position.x += p["drift"] * delta * 0.3
		if node.position.y < -10:
			node.position.y = screen_h + 5
			node.position.x = randf_range(0, screen_w)
		if node.position.x < -10:
			node.position.x = screen_w + 5
		if node.position.x > screen_w + 10:
			node.position.x = -5

# =========================================
# CALLBACKS
# =========================================
func _on_new_game_pressed() -> void:
	var scene = load("res://scenes/save_slot_screen.tscn").instantiate()
	scene.mode = "new_game"
	get_tree().root.add_child(scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = scene

func _on_continue_pressed() -> void:
	var scene = load("res://scenes/save_slot_screen.tscn").instantiate()
	scene.mode = "continue"
	get_tree().root.add_child(scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = scene

func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits_scene.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/leaderboard_scene.tscn")
