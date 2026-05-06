extends Node

# =========================================
# CONSTANTS
# =========================================
# Grade thresholds
const GRADE_THRESHOLDS = {
	"S": 80,
	"A": 65,
	"B": 50,
	"C": 35,
	"D": 0
}

const GRADE_LABELS = {
	"S": "BUSINESS MOGUL",
	"A": "THRIVING ENTERPRISE",
	"B": "STEADY BUSINESS",
	"C": "STRUGGLING SHOP",
	"D": "BARELY SURVIVING"
}

const GRADE_DESCRIPTIONS = {
	"S": "You've mastered the art of business! Your decisions were bold and brilliant.",
	"A": "Exceptional performance! Your business is built on solid foundations.",
	"B": "Good work! With a few tweaks, you could reach greatness.",
	"C": "A challenging run. Every setback is a learning opportunity.",
	"D": "Business is tough. Next time, focus on balancing your key stats."
}

const GRADE_QUOTES = {
	"S": "\"Fortune favors the bold.\"",
	"A": "\"Success is not final; failure is not fatal.\"",
	"B": "\"The secret of getting ahead is getting started.\"",
	"C": "\"Fall seven times, stand up eight.\"",
	"D": "\"The only real mistake is the one from which we learn nothing.\""
}

# Grade colors
const COLOR_S = Color("#ffd700")  # Gold
const COLOR_A = Color("#c8a84b")  # Bronze-gold
const COLOR_B = Color("#6a9c78")  # Silver-green
const COLOR_C = Color("#9b6b9b")  # Purple
const COLOR_D = Color("#8b5a5a")  # Bronze-red

# =========================================
# REFERENCES
# =========================================
var canvas:   CanvasLayer = null
var confetti_timer: Timer = null

# =========================================
# STATE
# =========================================
var _stats:       Dictionary  = {}
var _grade:       String      = ""
var _score:       float       = 0.0
var _confetti_particles: Array = []

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_receive_data()
	_calculate_grade()
	_build_canvas()
	_build_ui()
	_start_confetti()
	DialogueManager.save_game()
	SaveManager.complete_business(_grade, _stats)

# =========================================
# DATA
# =========================================
func _receive_data() -> void:
	_stats = DialogueManager.get_all_stats()

func _calculate_grade() -> void:
	var money = _stats.get("money", 50.0)
	var reputation = _stats.get("reputation", 50.0)
	var morale = _stats.get("morale", 50.0)
	var stress = _stats.get("stress", 50.0)
	
	_score = (money + reputation + morale - stress) / 3.0
	
	for grade in GRADE_THRESHOLDS:
		if _score >= GRADE_THRESHOLDS[grade]:
			_grade = grade
			break

func _get_grade_color() -> Color:
	match _grade:
		"S": return COLOR_S
		"A": return COLOR_A
		"B": return COLOR_B
		"C": return COLOR_C
		"D": return COLOR_D
	return _grade

# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)
	
	# Gradient background instead of solid
	var gradient_bg = ColorRect.new()
	gradient_bg.position = Vector2(0, 0)
	gradient_bg.size = get_viewport().get_visible_rect().size
	gradient_bg.material = _create_gradient_material()
	canvas.add_child(gradient_bg)

func _create_gradient_material() -> ShaderMaterial:
	var shader_code = """
	shader_type canvas_item;
	
	uniform vec4 color_top : source_color = vec4(0.12, 0.10, 0.18, 1.0);
	uniform vec4 color_bottom : source_color = vec4(0.06, 0.05, 0.10, 1.0);
	
	void fragment() {
		float mix_factor = UV.y;
		COLOR = mix(color_top, color_bottom, mix_factor);
	}
	"""
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	return material

func _start_confetti() -> void:
	# Create celebratory confetti particles
	for i in range(60):
		var confetti = ColorRect.new()
		var size = randf_range(4, 8)
		confetti.size = Vector2(size, size)
		
		# Random color based on grade
		var grade_color = _get_grade_color()
		confetti.color = Color(
			grade_color.r + randf_range(-0.2, 0.2),
			grade_color.g + randf_range(-0.2, 0.2),
			grade_color.b + randf_range(-0.2, 0.2),
			randf_range(0.7, 1.0)
		)
		
		confetti.position = Vector2(
			randf_range(0, get_viewport().get_visible_rect().size.x),
			randf_range(-100, -20)
		)
		confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(confetti)
		
		_confetti_particles.append({
			"node": confetti,
			"speed_y": randf_range(80, 150),
			"speed_x": randf_range(-30, 30),
			"rotation_speed": randf_range(-2, 2),
			"gravity": randf_range(50, 100)
		})

func _process(delta: float) -> void:
	# Animate confetti
	for p in _confetti_particles:
		var node = p["node"] as ColorRect
		node.position.y += p["speed_y"] * delta
		node.position.x += p["speed_x"] * delta
		node.rotation += p["rotation_speed"] * delta
		
		# Reset if off screen
		if node.position.y > get_viewport().get_visible_rect().size.y + 100:
			node.position = Vector2(
				randf_range(0, get_viewport().get_visible_rect().size.x),
				randf_range(-100, -20)
			)
			node.rotation = 0

func _build_ui() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	var screen_h = get_viewport().get_visible_rect().size.y

	# Main panel - floating, elegant
	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.05, screen_h * 0.04)
	panel.size = Vector2(screen_w * 0.9, screen_h * 0.92)
	panel.custom_minimum_size = panel.size
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.85)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = _get_grade_color()
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	vbox.add_theme_constant_override("margin_left", 16)
	vbox.add_theme_constant_override("margin_right", 16)
	vbox.add_theme_constant_override("margin_top", 12)
	vbox.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(vbox)

	# === HEADER WITH TROPHY ===
	_build_header(vbox)
	
	# === GRADE SECTION ===
	_build_grade_section(vbox)
	
	# Divider
	var divider = ColorRect.new()
	divider.color = _get_grade_color()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)
	
	# === QUOTE ===
	var quote = Label.new()
	quote.text = GRADE_QUOTES.get(_grade, "\"Success is a journey, not a destination.\"")
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(quote, 9)
	vbox.add_child(quote)
	
	# === STAT CARDS (2x2 grid) ===
	var stat_grid = GridContainer.new()
	stat_grid.columns = 2
	stat_grid.add_theme_constant_override("h_separation", 16)
	stat_grid.add_theme_constant_override("v_separation", 12)
	stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(stat_grid)
	
	var stat_defs = [
		["money", "💰", "TOTAL CAPITAL", GameTheme.get_color("money")],
		["reputation", "⭐", "REPUTATION", GameTheme.get_color("reputation")],
		["morale", "😊", "TEAM MORALE", GameTheme.get_color("morale")],
		["stress", "😰", "STRESS LEVEL", GameTheme.get_color("stress")],
	]
	
	for stat in stat_defs:
		stat_grid.add_child(_build_stat_card(stat[0], stat[1], stat[2], stat[3]))

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# === BUTTON ROW ===
	var btn_center = HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_center.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_center)
	
	var play_again = GameTheme.build_button("🔄  PLAY AGAIN", true, 14)
	play_again.custom_minimum_size = Vector2(screen_w * 0.4, 48)
	play_again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(play_again, _on_play_again_pressed)
	btn_center.add_child(play_again)
	
	var menu_btn = GameTheme.build_button("🏠  MAIN MENU", false, 14)
	menu_btn.custom_minimum_size = Vector2(screen_w * 0.35, 48)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameTheme.connect_button(menu_btn, _on_menu_pressed)
	btn_center.add_child(menu_btn)

func _build_header(vbox: VBoxContainer) -> void:
	# Trophy/celebration header
	var header_row = HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_row.add_theme_constant_override("separation", 12)
	vbox.add_child(header_row)
	
	# Left decoration
	var left_star = Label.new()
	left_star.text = "✦"
	left_star.add_theme_font_size_override("font_size", 16)
	left_star.add_theme_color_override("font_color", _get_grade_color())
	header_row.add_child(left_star)
	
	var title = Label.new()
	title.text = "GAME COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", _get_grade_color())
	GameTheme.apply_font(title, 20)
	header_row.add_child(title)
	
	var right_star = Label.new()
	right_star.text = "✦"
	right_star.add_theme_font_size_override("font_size", 16)
	right_star.add_theme_color_override("font_color", _get_grade_color())
	header_row.add_child(right_star)

func _build_grade_section(vbox: VBoxContainer) -> void:
	var grade_container = VBoxContainer.new()
	grade_container.alignment = BoxContainer.ALIGNMENT_CENTER
	grade_container.add_theme_constant_override("separation", 8)
	vbox.add_child(grade_container)
	
	# Grade label
	var grade_header = Label.new()
	grade_header.text = "YOUR FINAL GRADE"
	grade_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_header.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(grade_header, 10)
	grade_container.add_child(grade_header)
	
	# Large grade letter with glow effect
	var grade_letter = Label.new()
	grade_letter.text = _grade
	grade_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_letter.add_theme_font_size_override("font_size", 72)
	grade_letter.add_theme_color_override("font_color", _get_grade_color())
	# Add shadow for depth
	grade_letter.add_theme_constant_override("shadow_offset_x", 3)
	grade_letter.add_theme_constant_override("shadow_offset_y", 3)
	grade_letter.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	GameTheme.apply_font(grade_letter, 64)
	grade_container.add_child(grade_letter)
	
	# Grade title
	var grade_title = Label.new()
	grade_title.text = GRADE_LABELS[_grade]
	grade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_title.add_theme_font_size_override("font_size", 14)
	grade_title.add_theme_color_override("font_color", _get_grade_color())
	GameTheme.apply_font(grade_title, 20)
	grade_container.add_child(grade_title)
	
	# Score
	var score_text = Label.new()
	score_text.text = "Score: " + str(int(_score)) + " / 100"
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_text.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(score_text, 10)
	grade_container.add_child(score_text)
	
	# Description
	var description = Label.new()
	description.text = GRADE_DESCRIPTIONS[_grade]
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(description, 10)
	grade_container.add_child(description)

func _build_stat_card(stat_key: String, icon: String, label: String, bar_color: Color) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 85)  # Was 100
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("mid", 2)
	)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 12)
	vbox.add_theme_constant_override("margin_bottom", 12)
	card.add_child(vbox)
	
	# Top row: icon + label
	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	vbox.add_child(top_row)
	
	# Icon (asset or emoji)
	var icon_node = _load_or_create_icon(stat_key + "_stat", icon, 24)
	icon_node.custom_minimum_size = Vector2(28, 28)
	top_row.add_child(icon_node)
	
	var label_label = Label.new()
	label_label.text = label
	label_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(label_label, 8)
	top_row.add_child(label_label)
	
	# Progress bar
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = _stats.get(stat_key, 50.0)
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0, 8)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_left = 4
	fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg)
	vbox.add_child(bar)
	
	# Value display
	var value = int(_stats.get(stat_key, 50.0))
	var value_label = Label.new()
	value_label.text = str(value) + " / 100"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(value_label, 10)
	vbox.add_child(value_label)
	
	return card

func _load_or_create_icon(asset_name: String, fallback_emoji: String, font_size: int) -> Control:
	var asset_path = GameTheme._current.get("ui_folder", "") + asset_name + ".png"
	if ResourceLoader.exists(asset_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(asset_path)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.custom_minimum_size = Vector2(font_size, font_size)
		return tex_rect
	
	var label = Label.new()
	label.text = fallback_emoji
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label

# =========================================
# CALLBACKS
# =========================================
func _on_play_again_pressed() -> void:
	DialogueManager.reset()
	get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")

func _on_menu_pressed() -> void:
	DialogueManager.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
