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
var particles: Array = []
const PARTICLE_COUNT = 25

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
	_build_top_bar()
	_build_logo_section()
	_build_buttons()
	_build_version_label()
	
	AudioManager.play_music("menu_theme", 0.5)

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
		var p = ColorRect.new()
		var size = randf_range(1, 3)
		p.size = Vector2(size, size)
		p.color = Color(
			COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b,
			randf_range(0.05, 0.15)
		)
		p.position = Vector2(randf_range(0, screen_w), randf_range(0, screen_h))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(p)
		particles.append({
			"node": p,
			"speed": randf_range(5, 20),
			"drift": randf_range(-5, 5)
		})

func _build_top_bar() -> void:
	# Settings gear icon in top-right corner
	var gear_btn = PanelContainer.new()
	gear_btn.position = Vector2(screen_w - 50, 12)
	gear_btn.size = Vector2(38, 38)
	gear_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0.5)
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_color = Color(COLOR_ACCENT, 0.6)
	btn_style.corner_radius_top_left = 19
	btn_style.corner_radius_top_right = 19
	btn_style.corner_radius_bottom_left = 19
	btn_style.corner_radius_bottom_right = 19
	gear_btn.add_theme_stylebox_override("panel", btn_style)
	
	var gear_icon = Label.new()
	gear_icon.text = "⚙️"
	gear_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gear_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gear_icon.add_theme_font_size_override("font_size", 16)
	gear_icon.add_theme_color_override("font_color", COLOR_ACCENT)
	gear_btn.add_child(gear_icon)
	canvas.add_child(gear_btn)
	GameTheme.connect_button(gear_btn, _on_settings_pressed)
	
	# Help/How to play icon in top-left corner
	var help_btn = PanelContainer.new()
	help_btn.position = Vector2(12, 12)
	help_btn.size = Vector2(38, 38)
	help_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var help_style = StyleBoxFlat.new()
	help_style.bg_color = Color(0, 0, 0, 0.5)
	help_style.border_width_top = 1
	help_style.border_width_bottom = 1
	help_style.border_width_left = 1
	help_style.border_width_right = 1
	help_style.border_color = Color(COLOR_ACCENT, 0.6)
	help_style.corner_radius_top_left = 19
	help_style.corner_radius_top_right = 19
	help_style.corner_radius_bottom_left = 19
	help_style.corner_radius_bottom_right = 19
	help_btn.add_theme_stylebox_override("panel", help_style)
	
	var help_icon = Label.new()
	help_icon.text = "❓"
	help_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	help_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_icon.add_theme_font_size_override("font_size", 16)
	help_icon.add_theme_color_override("font_color", COLOR_ACCENT)
	help_btn.add_child(help_icon)
	canvas.add_child(help_btn)
	GameTheme.connect_button(help_btn, _on_how_to_play_pressed)

func _build_logo_section() -> void:
	var logo_container = VBoxContainer.new()
	logo_container.position = Vector2(0, screen_h * 0.1)
	logo_container.size = Vector2(screen_w, screen_h * 0.22)
	logo_container.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_container.add_theme_constant_override("separation", 6)
	canvas.add_child(logo_container)

	# Main logo
	var logo_main = Label.new()
	logo_main.text = "BIZLearn"
	logo_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo_main.add_theme_font_size_override("font_size", 44)
	logo_main.add_theme_color_override("font_color", COLOR_ACCENT)
	GameTheme.apply_font(logo_main, 44)
	logo_container.add_child(logo_main)

	var underline = ColorRect.new()
	underline.color = COLOR_ACCENT
	underline.custom_minimum_size = Vector2(screen_w * 0.2, 2)
	underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_container.add_child(underline)

	var tagline = Label.new()
	tagline.text = "Run it. Learn it. Own it."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tagline.add_theme_font_size_override("font_size", 10)
	tagline.add_theme_color_override("font_color", COLOR_DIM)
	GameTheme.apply_font(tagline, 10)
	logo_container.add_child(tagline)

func _build_buttons() -> void:
	SaveManager._load_all_slots()
	
	# Main button container
	var btn_container = VBoxContainer.new()
	btn_container.position = Vector2(screen_w * 0.1, screen_h * 0.38)
	btn_container.size = Vector2(screen_w * 0.8, screen_h * 0.45)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 12)
	canvas.add_child(btn_container)
	
	var has_saves = SaveManager.has_any_save()
	
	# CONTINUE button (if save exists) - largest
	if has_saves:
		var continue_btn = GameTheme.build_button("▶  CONTINUE", true, 20)
		continue_btn.custom_minimum_size = Vector2(screen_w * 0.6, 56)
		continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		GameTheme.connect_button(continue_btn, _on_continue_pressed)
		btn_container.add_child(continue_btn)
	
	# NEW GAME button - largest
	var new_btn_text = "✨  " + ("NEW GAME" if has_saves else "START GAME") + "  ✨"
	var new_btn = GameTheme.build_button(new_btn_text, not has_saves, 20)
	new_btn.custom_minimum_size = Vector2(screen_w * 0.6, 56)
	new_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(new_btn, _on_new_game_pressed)
	btn_container.add_child(new_btn)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	btn_container.add_child(spacer)
	
	# LEADERBOARD button - medium, secondary style
	var leaderboard_btn = GameTheme.build_button("🏆  LEADERBOARD", false, 16)
	leaderboard_btn.custom_minimum_size = Vector2(screen_w * 0.5, 48)
	leaderboard_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(leaderboard_btn, _on_leaderboard_pressed)
	btn_container.add_child(leaderboard_btn)
	
	# CREDITS button at bottom
	var credits_btn = GameTheme.build_button("🎭  CREDITS", false, 12)
	credits_btn.custom_minimum_size = Vector2(screen_w * 0.35, 40)
	credits_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credits_btn.modulate = Color(1, 1, 1, 0.7)
	GameTheme.connect_button(credits_btn, _on_credits_pressed)
	btn_container.add_child(credits_btn)

func _build_version_label() -> void:
	var version = Label.new()
	version.text = "Beta v1.0  —  Laundromat Release"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.position = Vector2(0, screen_h - 24)
	version.size = Vector2(screen_w, 16)
	version.add_theme_font_size_override("font_size", 8)
	version.add_theme_color_override("font_color", COLOR_PANEL_MID)
	GameTheme.apply_font(version, 8)
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
