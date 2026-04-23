extends Node

# =========================================
# TOGGLES — flip these when assets ready
# =========================================
const USE_TEXTURE_UI   = true  # true = texture buttons/panels
const USE_ANIMATED_BG  = false  # true = animated spritesheet bg
const USE_CUSTOM_FONT  = true  # true = custom pixel font

# Active theme — swap per business
var ACTIVE_THEME       = "coffee_shop"

# =========================================
# THEME DEFINITIONS
# =========================================
const THEMES = {
	"coffee_shop": {
		"accent":       Color("#c8a84b"),
		"accent_dark":  Color("#8a6f2e"),
		"bg":           Color("#1a1209"),
		"panel_dark":   Color("#2d1f0f"),
		"panel_mid":    Color("#3d2d1a"),
		"text":         Color("#e8e0d0"),
		"dim":          Color("#8a7a6a"),
		"positive":     Color("#4a7c59"),
		"negative":     Color("#8b3a3a"),
		"money":        Color("#c8a84b"),
		"reputation":   Color("#7c5c8a"),
		"morale":       Color("#4a7c59"),
		"stress":       Color("#8b3a3a"),
		"button_text_primary":         Color("#2d1f0f"), 
		"button_text_primary_hover":   Color("#e8e0d0"),  
		"button_text_secondary":       Color("#8a7a6a"),  
		"button_text_secondary_hover": Color("#e8e0d0"),  
		"bg_tints": {
			"shop_day":     Color("#1a1209"),
			"shop_evening": Color("#0d0a05"),
			"office":       Color("#120d05"),
			"street":       Color("#0d0a0a"),
		},
		"bg_folder":    "res://assets/backgrounds/coffee_shop/",
		"ui_folder":    "res://assets/ui/coffee_shop/",
		"font_path":    "res://assets/fonts/monogram/ttf/monogram.ttf",
	},
	"flower_shop": {
		"accent":       Color("#e8a0b4"),
		"accent_dark":  Color("#a06070"),
		"bg":           Color("#0d1a0d"),
		"panel_dark":   Color("#1a2d1a"),
		"panel_mid":    Color("#2d3d2d"),
		"text":         Color("#f0ece8"),
		"dim":          Color("#8a9a8a"),
		"positive":     Color("#4a9c69"),
		"negative":     Color("#9b4a4a"),
		"money":        Color("#e8a0b4"),
		"reputation":   Color("#9c7caa"),
		"morale":       Color("#5a9c69"),
		"stress":       Color("#9b4a4a"),
		"bg_tints": {
			"shop_day":     Color("#0d1a0d"),
			"shop_evening": Color("#0a1209"),
			"office":       Color("#091209"),
			"street":       Color("#0d120d"),
		},
		"bg_folder":    "res://assets/backgrounds/flower_shop/",
		"ui_folder":    "res://assets/ui/flower_shop/",
		"font_path":    "res://assets/fonts/pixel_font.ttf",
	},
	"tech_startup": {
		"accent":       Color("#00d4ff"),
		"accent_dark":  Color("#0090aa"),
		"bg":           Color("#0d0d1a"),
		"panel_dark":   Color("#1a1a2d"),
		"panel_mid":    Color("#2d2d40"),
		"text":         Color("#e0e8f0"),
		"dim":          Color("#6a7a8a"),
		"positive":     Color("#00cc88"),
		"negative":     Color("#ff4466"),
		"money":        Color("#00d4ff"),
		"reputation":   Color("#aa88ff"),
		"morale":       Color("#00cc88"),
		"stress":       Color("#ff4466"),
		"bg_tints": {
			"shop_day":     Color("#0d0d1a"),
			"shop_evening": Color("#0a0a14"),
			"office":       Color("#0a0d14"),
			"street":       Color("#0d0d1f"),
		},
		"bg_folder":    "res://assets/backgrounds/tech_startup/",
		"ui_folder":    "res://assets/ui/tech_startup/",
		"font_path":    "res://assets/fonts/pixel_font.ttf",
	},
}

# =========================================
# UI SIZE CONSTANTS — all in one place
# =========================================
const HUD_HEIGHT        = 36.0
const HUD_Y             = 20.0
const DIALOGUEBOX_H     = 140.0
const BUTTON_H          = 44.0
const BUTTON_SEP        = 6.0
const PORTRAIT_SIZE     = Vector2(36, 36)
const BAR_SIZE          = Vector2(60, 8)
const NPC_SIZE          = Vector2(80, 120)
const PLAYER_SIZE       = Vector2(70, 110)
const PANEL_BORDER_W    = 2
const DIALOGUE_BORDER_W = 3
const BUTTON_SIZE_STANDARD = 16

# =========================================
# INTERNAL STATE
# =========================================
var _current:    Dictionary = {}
var _bg_node:    Node       = null
var _font:       Font       = null

var current_text_speed: float = 0.03  # default normal
var vibration_enabled: bool = true

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_apply_theme(ACTIVE_THEME)

# ========================================
# CONSTANTS
# ========================================

const TEXT_SPEEDS = [0.06, 0.03, 0.01]

# =========================================
# PUBLIC — THEME
# =========================================

func set_text_speed(index: int) -> void:
	if index >= 0 and index < TEXT_SPEEDS.size():
		current_text_speed = TEXT_SPEEDS[index]

func get_text_speed() -> float:
	return current_text_speed

func set_vibration(enabled: bool) -> void:
	vibration_enabled = enabled

func vibrate() -> void:
	if vibration_enabled:
		Input.vibrate_handheld(50)

func set_theme(theme_id: String) -> void:
	if not THEMES.has(theme_id):
		push_warning("GameTheme: Unknown theme " + theme_id)
		return
	ACTIVE_THEME = theme_id
	_apply_theme(theme_id)
	print("GameTheme: switched to ", theme_id)
	print("Accent color is now: ", get_color("accent"))


func get_color(key: String) -> Color:
	return _current.get(key, Color("#ffffff"))


func get_bg_tint(bg_id: String) -> Color:
	var tints = _current.get("bg_tints", {})
	return tints.get(bg_id, _current.get("bg", Color("#1a1a2e")))


# =========================================
# PUBLIC — FONT
# =========================================
func get_font() -> Font:
	if not USE_CUSTOM_FONT:
		return null
	if _font != null:
		return _font
	var path = _current.get("font_path", "")
	if ResourceLoader.exists(path):
		_font = load(path)
		return _font
	return null


func apply_font(node: Control, size: int) -> void:
	var font = get_font()
	if font != null:
		node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)


# =========================================
# PUBLIC — BACKGROUND
# =========================================
func get_bg_for_scene(
	bg_id:    String,
	parent:   Node,
	size:     Vector2
) -> Node:
	if USE_ANIMATED_BG:
		var node = _try_load_animated_bg(bg_id, size)
		if node != null:
			return node

	# Fallback — ColorRect with theme tint
	var rect       = ColorRect.new()
	rect.color     = get_bg_tint(bg_id)
	rect.position  = Vector2(0, 0)
	rect.size      = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func swap_bg(
	bg_id:   String,
	parent:  Node,
	old_bg:  Node,
	size:    Vector2
) -> Node:
	if old_bg != null:
		old_bg.queue_free()
	var new_bg = get_bg_for_scene(bg_id, parent, size)
	parent.add_child(new_bg)
	# Move to back so it sits behind everything
	parent.move_child(new_bg, 0)
	return new_bg


# =========================================
# PUBLIC — BUTTON STYLES
# =========================================
func make_button_style(
	state:          String,
	is_primary:     bool
) -> StyleBox:
	if USE_TEXTURE_UI:
		var path = _current.get("ui_folder", "") + \
				   ("primary_" if is_primary else "secondary_") + \
				   state + ".png"
		if ResourceLoader.exists(path):
			var style   = StyleBoxTexture.new()
			style.texture = load(path)
			style.texture_margin_left   = 4
			style.texture_margin_right  = 4
			style.texture_margin_top    = 4
			style.texture_margin_bottom = 4
			return style

	# Fallback — StyleBoxFlat
	return _make_flat_button(state, is_primary)


func _make_flat_button(state: String, is_primary: bool) -> StyleBoxFlat:
	var style   = StyleBoxFlat.new()
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0

	match state:
		"normal":
			style.bg_color = get_color("accent") if is_primary \
							 else get_color("bg")
			style.border_width_top    = 0 if is_primary else PANEL_BORDER_W
			style.border_width_bottom = 0 if is_primary else PANEL_BORDER_W
			style.border_width_left   = 0 if is_primary else PANEL_BORDER_W
			style.border_width_right  = 0 if is_primary else PANEL_BORDER_W
			style.border_color        = get_color("accent")
		"hover":
			style.bg_color            = get_color("panel_mid")
			style.border_width_top    = PANEL_BORDER_W
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left   = PANEL_BORDER_W
			style.border_width_right  = PANEL_BORDER_W
			style.border_color        = get_color("accent")
		"pressed":
			style.bg_color            = get_color("panel_dark")
			style.border_width_top    = PANEL_BORDER_W
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left   = PANEL_BORDER_W
			style.border_width_right  = PANEL_BORDER_W
			style.border_color        = get_color("accent")
		"focus":
			style.bg_color            = get_color("panel_dark")
			style.border_width_top    = PANEL_BORDER_W
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left   = PANEL_BORDER_W
			style.border_width_right  = PANEL_BORDER_W
			style.border_color        = get_color("accent")
	return style


# =========================================
# PUBLIC — PANEL STYLES
# =========================================
func make_panel_style(
	variant: String = "dark",
	border_top: int = PANEL_BORDER_W
) -> StyleBox:
	if USE_TEXTURE_UI:
		var path = _current.get("ui_folder", "") + "panel_" + variant + ".png"
		if ResourceLoader.exists(path):
			var style   = StyleBoxTexture.new()
			style.texture = load(path)
			style.texture_margin_left   = 4
			style.texture_margin_right  = 4
			style.texture_margin_top    = 4
			style.texture_margin_bottom = 4
			return style

	# Fallback — StyleBoxFlat
	return _make_flat_panel(variant, border_top)


func _make_flat_panel(variant: String, border_top: int) -> StyleBoxFlat:
	var style   = StyleBoxFlat.new()
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0

	match variant:
		"dark":
			style.bg_color            = get_color("panel_dark")
			style.border_width_top    = border_top
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left   = PANEL_BORDER_W
			style.border_width_right  = PANEL_BORDER_W
			style.border_color        = get_color("accent")
		"mid":
			style.bg_color            = get_color("panel_mid")
			style.border_width_top    = border_top
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left   = PANEL_BORDER_W
			style.border_width_right  = PANEL_BORDER_W
			style.border_color        = get_color("accent")
		"accent":
			style.bg_color            = get_color("accent")
			style.border_width_top    = 0
			style.border_width_bottom = 0
			style.border_width_left   = 0
			style.border_width_right  = 0
	return style


# =========================================
# PUBLIC — PROGRESS BAR STYLES
# =========================================
func make_bar_fill_style(stat_key: String) -> StyleBoxFlat:
	var style   = StyleBoxFlat.new()
	style.bg_color                   = get_color(stat_key)
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	return style


func make_bar_bg_style() -> StyleBoxFlat:
	var style   = StyleBoxFlat.new()
	style.bg_color                   = Color(1, 1, 1, 0.094)
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	return style

# =========================================
# PUBLIC — BUTTON FACTORY
# =========================================
func build_button(
	label:      String,
	is_primary: bool,
	font_size:  int = BUTTON_SIZE_STANDARD
) -> PanelContainer:
	
	var btn_height = max(BUTTON_H, font_size * 2.8)

	
	var container                   = PanelContainer.new()
	container.custom_minimum_size   = Vector2(0, btn_height)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.mouse_filter          = Control.MOUSE_FILTER_STOP
	container.add_theme_stylebox_override("panel",
		make_button_style("normal", is_primary)
	)
	var content_margin = StyleBoxFlat.new()
	content_margin.content_margin_left   = 8
	content_margin.content_margin_right  = 8
	content_margin.content_margin_top    = 0
	content_margin.content_margin_bottom = 0
	container.add_theme_constant_override("margin_left",   8)
	container.add_theme_constant_override("margin_right",  8)
	container.add_theme_constant_override("margin_top",    0)
	container.add_theme_constant_override("margin_bottom", 0)

	var lbl                      = Label.new()
	lbl.text                     = label
	lbl.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment       = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical      = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter             = Control.MOUSE_FILTER_IGNORE
	lbl.autowrap_mode            = TextServer.AUTOWRAP_OFF
	lbl.clip_contents            = false
	apply_font(lbl, font_size)
	lbl.add_theme_color_override("font_color",
		get_color("button_text_primary") if is_primary
		else get_color("button_text_secondary")
	)
	container.add_child(lbl)

	# Store colors for state changes
	var color_normal = get_color("button_text_primary") if is_primary \
					   else get_color("button_text_secondary")
	var color_hover  = get_color("button_text_primary_hover") if is_primary \
					   else get_color("button_text_secondary_hover")

	container.mouse_entered.connect(func():
		container.add_theme_stylebox_override("panel",
			make_button_style("hover", is_primary)
		)
		# Change label color on hover
		lbl.add_theme_color_override("font_color", color_hover)
	)
	container.mouse_exited.connect(func():
		container.add_theme_stylebox_override("panel",
			make_button_style("normal", is_primary)
		)
		# Restore label color
		lbl.add_theme_color_override("font_color", color_normal)
	)
	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					container.add_theme_stylebox_override("panel",
						make_button_style("pressed", is_primary)
					)
					lbl.add_theme_color_override("font_color", color_hover)
				else:
					container.add_theme_stylebox_override("panel",
						make_button_style("hover", is_primary)
					)
					lbl.add_theme_color_override("font_color", color_hover)
	)

	return container


func connect_button(container: PanelContainer, callback: Callable) -> void:
	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				callback.call()
	)

func apply_font_rich(node: RichTextLabel, size: int) -> void:
	var font = get_font()
	if font != null:
		node.add_theme_font_override("normal_font",       font)
		node.add_theme_font_override("bold_font",         font)
		node.add_theme_font_override("italics_font",      font)
		node.add_theme_font_override("bold_italics_font", font)
		node.add_theme_font_override("mono_font",         font)
	node.add_theme_font_size_override("normal_font_size",  size)
	node.add_theme_font_size_override("bold_font_size",    size)
	node.add_theme_font_size_override("italics_font_size", size)
	node.add_theme_font_size_override("mono_font_size",    size)

# =========================================
# PRIVATE
# =========================================
func _apply_theme(theme_id: String) -> void:
	_current = THEMES.get(theme_id, THEMES["coffee_shop"])
	_font    = null


func _try_load_animated_bg(bg_id: String, size: Vector2) -> Node:
	var folder = _current.get("bg_folder", "") + bg_id + "/"
	if not DirAccess.dir_exists_absolute(folder):
		return null

	# Look for frames: bg_id_000.png, bg_id_001.png etc
	var frames      = []
	var frame_index = 0
	while true:
		var path = folder + bg_id + "_%03d.png" % frame_index
		if not ResourceLoader.exists(path):
			break
		frames.append(load(path))
		frame_index += 1

	if frames.is_empty():
		return null

	# Build AnimatedTexture on a TextureRect
	var anim_tex           = AnimatedTexture.new()
	anim_tex.frames        = frames.size()
	for i in range(frames.size()):
		anim_tex.set_frame_texture(i, frames[i])
		anim_tex.set_frame_duration(i, 0.1)  # 10fps default

	var rect               = TextureRect.new()
	rect.texture           = anim_tex
	rect.stretch_mode      = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.position          = Vector2(0, 0)
	rect.size              = size
	rect.mouse_filter      = Control.MOUSE_FILTER_IGNORE
	return rect
