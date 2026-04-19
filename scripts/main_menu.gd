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
var canvas:     CanvasLayer = null
var screen_w:   float       = 0.0
var screen_h:   float       = 0.0

# Particle state
var particles:  Array       = []
const PARTICLE_COUNT        = 40

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	# Set theme based on current business
	# For now defaults to coffee_shop
	GameTheme.set_theme("coffee_shop")

	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y

	_build_canvas()
	_build_background()
	_build_particles()
	_build_logo_section()
	_build_character_slot()
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
	# ASSET SLOT — swap with spritesheet particles later
	# For now: animated ColorRect dots floating upward
	for i in range(PARTICLE_COUNT):
		var p          = ColorRect.new()
		var size       = randf_range(2, 5)
		p.size         = Vector2(size, size)
		p.color        = Color(
			COLOR_ACCENT.r,
			COLOR_ACCENT.g,
			COLOR_ACCENT.b,
			randf_range(0.1, 0.4)
		)
		p.position     = Vector2(
			randf_range(0, screen_w),
			randf_range(0, screen_h)
		)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(p)

		# Store particle with its speed for _process
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

	# ASSET SLOT — swap Label for TextureRect logo image
	# Keep label as fallback until art is ready
	var logo_top                    = Label.new()
	logo_top.text                   = "— BIZ —"
	logo_top.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	logo_top.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	logo_top.add_theme_font_size_override("font_size", 10)
	logo_top.add_theme_color_override("font_color", COLOR_DIM)
	logo_container.add_child(logo_top)

	var logo_main                   = Label.new()
	logo_main.text                  = "BIZLearn"
	logo_main.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	logo_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	logo_main.add_theme_font_size_override("font_size", 38)
	logo_main.add_theme_color_override("font_color", COLOR_ACCENT)
	logo_container.add_child(logo_main)

	# Underline accent
	var underline               = ColorRect.new()
	underline.color             = COLOR_ACCENT
	underline.custom_minimum_size = Vector2(screen_w * 0.4, 2)
	underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_container.add_child(underline)

	var tagline                     = Label.new()
	tagline.text                    = "Run it.  Learn it.  Own it."
	tagline.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	tagline.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	tagline.add_theme_font_size_override("font_size", 9)
	tagline.add_theme_color_override("font_color", COLOR_DIM)
	logo_container.add_child(tagline)


func _build_character_slot() -> void:
	# ASSET SLOT — swap PanelContainer for Sprite2D character art
	var slot          = PanelContainer.new()
	slot.position     = Vector2(screen_w * 0.5 - 50, screen_h * 0.36)
	slot.size         = Vector2(100, 120)

	var style = StyleBoxFlat.new()
	style.bg_color                   = COLOR_PANEL_DARK
	style.border_width_top           = 2
	style.border_width_bottom        = 2
	style.border_width_left          = 2
	style.border_width_right         = 2
	style.border_color               = COLOR_PANEL_MID
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	slot.add_theme_stylebox_override("panel", style)
	canvas.add_child(slot)

	var slot_label                  = Label.new()
	slot_label.text                 = "👤"
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	slot_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_label.add_theme_font_size_override("font_size", 32)
	slot.add_child(slot_label)

	# Animate the character slot with a gentle bob
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(slot, "position:y", screen_h * 0.36 - 8, 1.2)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	tween.tween_property(slot, "position:y", screen_h * 0.36, 1.2)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)


func _build_buttons() -> void:
	var btn_container          = VBoxContainer.new()
	btn_container.position     = Vector2(screen_w * 0.15, screen_h * 0.55)
	btn_container.size         = Vector2(screen_w * 0.7, screen_h * 0.38)
	btn_container.add_theme_constant_override("separation", 10)
	canvas.add_child(btn_container)

	var start_btn = GameTheme.build_button("▸  START BUSINESS", true)
	GameTheme.connect_button(start_btn, _on_start_pressed)
	btn_container.add_child(start_btn)

	var how_btn = GameTheme.build_button("HOW TO PLAY", false)
	GameTheme.connect_button(how_btn, _on_how_to_play_pressed)
	btn_container.add_child(how_btn)

	var settings_btn = GameTheme.build_button("SETTINGS", false)
	GameTheme.connect_button(settings_btn, _on_settings_pressed)
	btn_container.add_child(settings_btn)

	var credits_btn = GameTheme.build_button("CREDITS", false)
	GameTheme.connect_button(credits_btn, _on_credits_pressed)
	btn_container.add_child(credits_btn)

	var exit_btn = GameTheme.build_button("EXIT", false)
	GameTheme.connect_button(exit_btn, _on_exit_pressed)
	btn_container.add_child(exit_btn)

func _build_version_label() -> void:
	var version                  = Label.new()
	version.text                 = "v0.2  —  Business 1: The Shop"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.position             = Vector2(0, screen_h - 20)
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
		# Float upward
		node.position.y -= p["speed"] * delta
		# Gentle horizontal drift
		node.position.x += p["drift"] * delta * 0.3
		# Wrap around when off screen
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
func _on_start_pressed() -> void:
	DialogueManager.reset()
	get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")


func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits_scene.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
