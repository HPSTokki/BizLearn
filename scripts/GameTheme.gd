extends Node

# =========================================
# TOGGLES — flip these when assets ready
# =========================================
const USE_TEXTURE_UI   = true  # true = texture buttons/panels
const USE_ANIMATED_BG  = false  # true = animated spritesheet bg
const USE_CUSTOM_FONT  = true  # true = custom pixel font

# Active theme — swap per business
var ACTIVE_THEME       = "laundromat"

# =========================================
# THEME DEFINITIONS
# =========================================
const THEMES = {
	"laundromat": {
		# UPDATED: True laundromat colors (warm industrial)
		"accent":       Color("#d4a373"),      # Warm beige-gold
		"accent_dark":  Color("#b5835a"),      # Deeper gold
		"bg":           Color("#2c2a2a"),      # Dark charcoal
		"panel_dark":   Color("#3a3535"),      # Warm dark gray
		"panel_mid":    Color("#4a4545"),      # Mid gray
		"text":         Color("#2c2a2a"),      # Warm off-white
		"dim":          Color("#a39a8c"),      # Muted beige-gray
		"positive":     Color("#8cb369"),      # Sage green
		"negative":     Color("#bc4a4a"),      # Brick red
		"money":        Color("#d4a373"),      # Same as accent
		"reputation":   Color("#c9ada7"),      # Dusty rose
		"morale":       Color("#8cb369"),      # Sage green
		"stress":       Color("#bc4a4a"),      # Brick red
		"button_text_primary":         Color("#f4e9d8"), #2c2a2a
		"button_text_primary_hover":   Color("#ffffff"), #1a1818
		"button_text_secondary":       Color("#2c2a2a"), #f4e9d8
		"button_text_secondary_hover": Color("#1a1818"), #ffffff
		"bg_tints": {
			"shop_day":     Color("#2c2a2a"),
			"shop_evening": Color("#1a1818"),
			"office":       Color("#252222"),
			"street":       Color("#2a2828"),
		},
		"business_id":  "laundromat",
		"bg_folder":    "res://assets/backgrounds/laundromat/",
		"char_folder":  "res://assets/characters/laundromat/",
		"ui_folder":    "res://assets/ui/laundromat/",
		"font_path":    "res://assets/fonts/monogram/ttf/monogram.ttf",
	},
	# ── Coffee Shop (original colors) ──
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
		"business_id":  "coffee_shop",
		"bg_folder":    "res://assets/backgrounds/coffee_shop/",
		"char_folder":  "res://assets/characters/coffee_shop/",
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
		"button_text_primary":         Color("#0d1a0d"),
		"button_text_primary_hover":   Color("#f0ece8"),
		"button_text_secondary":       Color("#8a9a8a"),
		"button_text_secondary_hover": Color("#f0ece8"),
		"bg_tints": {
			"shop_day":     Color("#0d1a0d"),
			"shop_evening": Color("#0a1209"),
			"office":       Color("#091209"),
			"street":       Color("#0d120d"),
		},
		"business_id":  "flower_shop",
		"bg_folder":    "res://assets/backgrounds/flower_shop/",
		"char_folder":  "res://assets/characters/flower_shop/",
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
		"button_text_primary":         Color("#0d0d1a"),
		"button_text_primary_hover":   Color("#e0e8f0"),
		"button_text_secondary":       Color("#6a7a8a"),
		"button_text_secondary_hover": Color("#e0e8f0"),
		"bg_tints": {
			"shop_day":     Color("#0d0d1a"),
			"shop_evening": Color("#0a0a14"),
			"office":       Color("#0a0d14"),
			"street":       Color("#0d0d1f"),
		},
		"business_id":  "tech_startup",
		"bg_folder":    "res://assets/backgrounds/tech_startup/",
		"char_folder":  "res://assets/characters/tech_startup/",
		"ui_folder":    "res://assets/ui/tech_startup/",
		"font_path":    "res://assets/fonts/pixel_font.ttf",
	},
}

# =========================================
# UI SIZE CONSTANTS
# =========================================
const HUD_HEIGHT        = 48.0
const HUD_Y             = 8.0
const DIALOGUEBOX_H     = 140.0
const BUTTON_H          = 44.0
const BUTTON_SEP        = 6.0
const PORTRAIT_SIZE     = Vector2(36, 36)
const BAR_SIZE          = Vector2(60, 8)
const NPC_SIZE          = Vector2(32, 120)
const PLAYER_SIZE       = Vector2(70, 110)
const SCENE_SPRITE_FRAME_SIZE = Vector2(500, 500)
const SCENE_SPRITE_DISPLAY_SIZE = Vector2(200, 200)
const SCENE_SPRITE_COLS = 4
const SCENE_SPRITE_FPS  = 8.0
const PANEL_BORDER_W    = 2
const DIALOGUE_BORDER_W = 3
const BUTTON_SIZE_STANDARD = 16

const GAME_WIDTH = 854
const GAME_HEIGHT = 480

# Pill/Slider constants for Status HUD
const PILL_SLICE = 12  # 9-slice margin for pill backgrounds

# =========================================
# INTERNAL STATE
# =========================================
var _current:    Dictionary = {}
var _bg_node:    Node       = null
var _font:       Font       = null

var current_text_speed: float = 0.03
var vibration_enabled: bool = true

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	_apply_theme(ACTIVE_THEME)

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
		push_warning("GameTheme: Unknown theme " + theme_id + ", using laundromat")
		theme_id = "laundromat"
	ACTIVE_THEME = theme_id
	_apply_theme(theme_id)
	print("GameTheme: switched to ", theme_id)
	print("Accent color is now: ", get_color("accent"))

func get_color(key: String) -> Color:
	return _current.get(key, Color("#ffffff"))

func get_business_id() -> String:
	return _current.get("business_id", "laundromat")

func get_char_path(speaker_id: String) -> String:
	var biz_path = _current.get("char_folder", "res://assets/characters/laundromat/") + speaker_id + ".png"
	if ResourceLoader.exists(biz_path):
		return biz_path
	var shared_path := "res://assets/characters/shared/" + speaker_id + ".png"
	if ResourceLoader.exists(shared_path):
		return shared_path
	return ""

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
func get_bg_for_scene(bg_id: String, parent: Node, size: Vector2) -> Node:
	if USE_ANIMATED_BG:
		var node = _try_load_animated_bg(bg_id, size)
		if node != null:
			return node
	var rect = ColorRect.new()
	rect.color = get_bg_tint(bg_id)
	rect.position = Vector2(0, 0)
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func swap_bg(bg_id: String, parent: Node, old_bg: Node, size: Vector2) -> Node:
	if old_bg != null:
		old_bg.queue_free()
	var new_bg = get_bg_for_scene(bg_id, parent, size)
	parent.add_child(new_bg)
	parent.move_child(new_bg, 0)
	return new_bg

# =========================================
# PUBLIC — BUTTON STYLES
# =========================================
func make_button_style(state: String, is_primary: bool) -> StyleBox:
	if USE_TEXTURE_UI:
		var path = _current.get("ui_folder", "") + ("primary_" if is_primary else "secondary_") + state + ".png"
		if ResourceLoader.exists(path):
			var style = StyleBoxTexture.new()
			style.texture = load(path)
			style.texture_margin_left = 8
			style.texture_margin_right = 8
			style.texture_margin_top = 8
			style.texture_margin_bottom = 8
			return style
	return _make_flat_button(state, is_primary)

func _make_flat_button(state: String, is_primary: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	match state:
		"normal":
			style.bg_color = get_color("accent") if is_primary else get_color("bg")
			style.border_width_top = 0 if is_primary else PANEL_BORDER_W
			style.border_width_bottom = 0 if is_primary else PANEL_BORDER_W
			style.border_width_left = 0 if is_primary else PANEL_BORDER_W
			style.border_width_right = 0 if is_primary else PANEL_BORDER_W
			style.border_color = get_color("accent")
		"hover":
			style.bg_color = get_color("panel_mid")
			style.border_width_top = PANEL_BORDER_W
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left = PANEL_BORDER_W
			style.border_width_right = PANEL_BORDER_W
			style.border_color = get_color("accent")
		"pressed", "focus":
			style.bg_color = get_color("panel_dark")
			style.border_width_top = PANEL_BORDER_W
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left = PANEL_BORDER_W
			style.border_width_right = PANEL_BORDER_W
			style.border_color = get_color("accent")
	return style

# =========================================
# PUBLIC — PANEL STYLES
# =========================================
func make_panel_style(variant: String = "dark", border_top: int = PANEL_BORDER_W) -> StyleBox:
	if USE_TEXTURE_UI:
		var path = _current.get("ui_folder", "") + "panel_" + variant + ".png"
		if ResourceLoader.exists(path):
			var style = StyleBoxTexture.new()
			style.texture = load(path)
			style.texture_margin_left = 20
			style.texture_margin_right = 20
			style.texture_margin_top = 20
			style.texture_margin_bottom = 20
			return style
	return _make_flat_panel(variant, border_top)

func _make_flat_panel(variant: String, border_top: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	match variant:
		"dark":
			style.bg_color = get_color("panel_dark")
			style.border_width_top = border_top
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left = PANEL_BORDER_W
			style.border_width_right = PANEL_BORDER_W
			style.border_color = get_color("accent")
		"mid":
			style.bg_color = get_color("panel_mid")
			style.border_width_top = border_top
			style.border_width_bottom = PANEL_BORDER_W
			style.border_width_left = PANEL_BORDER_W
			style.border_width_right = PANEL_BORDER_W
			style.border_color = get_color("accent")
		"accent":
			style.bg_color = get_color("accent")
			style.border_width_top = 0
			style.border_width_bottom = 0
			style.border_width_left = 0
			style.border_width_right = 0
	return style

# =========================================
# PUBLIC — PILL STYLES (for Status HUD)
# =========================================
func make_pill_style(accent_color_key: String = "accent") -> StyleBox:
	"""Creates a pill-shaped background for status HUD items"""
	if USE_TEXTURE_UI:
		var path = _current.get("ui_folder", "") + "pill_bg.png"
		if ResourceLoader.exists(path):
			var style = StyleBoxTexture.new()
			style.texture = load(path)
			style.texture_margin_left = PILL_SLICE
			style.texture_margin_right = PILL_SLICE
			style.texture_margin_top = 8
			style.texture_margin_bottom = 8
			return style
	
	# Fallback flat pill style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.65)
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(get_color(accent_color_key), 0.5)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.shadow_size = 2
	style.shadow_color = Color(0, 0, 0, 0.3)
	return style

# =========================================
# PUBLIC — PROGRESS BAR STYLES
# =========================================
func make_bar_fill_style(stat_key: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = get_color(stat_key)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

func make_bar_bg_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

# =========================================
# PUBLIC — BUTTON FACTORY
# =========================================
func build_button(label: String, is_primary: bool, font_size: int = BUTTON_SIZE_STANDARD) -> PanelContainer:
	var btn_height = max(BUTTON_H, font_size * 2.8)
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, btn_height)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_theme_stylebox_override("panel", make_button_style("normal", is_primary))
	
	container.add_theme_constant_override("margin_left", 8)
	container.add_theme_constant_override("margin_right", 8)
	container.add_theme_constant_override("margin_top", 0)
	container.add_theme_constant_override("margin_bottom", 0)
	
	var lbl = Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_contents = false
	apply_font(lbl, font_size)
	lbl.add_theme_color_override("font_color",
		get_color("button_text_primary") if is_primary else get_color("button_text_secondary")
	)
	container.add_child(lbl)
	
	var color_normal = get_color("button_text_primary") if is_primary else get_color("button_text_secondary")
	var color_hover = get_color("button_text_primary_hover") if is_primary else get_color("button_text_secondary_hover")
	
	container.mouse_entered.connect(func():
		container.add_theme_stylebox_override("panel", make_button_style("hover", is_primary))
		lbl.add_theme_color_override("font_color", color_hover)
	)
	container.mouse_exited.connect(func():
		container.add_theme_stylebox_override("panel", make_button_style("normal", is_primary))
		lbl.add_theme_color_override("font_color", color_normal)
	)
	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				container.add_theme_stylebox_override("panel", make_button_style("pressed", is_primary))
				lbl.add_theme_color_override("font_color", color_hover)
			else:
				container.add_theme_stylebox_override("panel", make_button_style("hover", is_primary))
				lbl.add_theme_color_override("font_color", color_hover)
	)
	return container

func connect_button(container: PanelContainer, callback: Callable) -> void:
	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			callback.call()
	)

func apply_font_rich(node: RichTextLabel, size: int) -> void:
	var font = get_font()
	if font != null:
		node.add_theme_font_override("normal_font", font)
		node.add_theme_font_override("bold_font", font)
		node.add_theme_font_override("italics_font", font)
		node.add_theme_font_override("bold_italics_font", font)
		node.add_theme_font_override("mono_font", font)
	node.add_theme_font_size_override("normal_font_size", size)
	node.add_theme_font_size_override("bold_font_size", size)
	node.add_theme_font_size_override("italics_font_size", size)
	node.add_theme_font_size_override("mono_font_size", size)

func make_asset_texture(path: String, fallback_color: Color = Color("#2d1f0f")) -> Control:
	if ResourceLoader.exists(path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(path) as Texture2D
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return tex_rect
	var rect = ColorRect.new()
	rect.color = fallback_color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect

# TEMPO FIX
func make_scene_sprite_for(business_id: String, state: String = "idle") -> Node:
	"""Returns a TextureRect for static images (scaled to fit container)"""
	var path := "res://assets/shops/" + business_id + "/" + state + ".png"
	if not ResourceLoader.exists(path) and state != "idle":
		path = "res://assets/shops/" + business_id + "/idle.png"
	if not ResourceLoader.exists(path):
		return null

	var texture := load(path) as Texture2D
	
	# For static images - use TextureRect (simpler and more reliable)
	var tex_rect = TextureRect.new()
	tex_rect.texture = texture
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # For pixel art
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	return tex_rect

# =========================================
# PRIVATE
# =========================================
func _apply_theme(theme_id: String) -> void:
	_current = THEMES.get(theme_id, THEMES["laundromat"])
	_font = null

func _try_load_animated_bg(bg_id: String, size: Vector2) -> Node:
	var folder = _current.get("bg_folder", "") + bg_id + "/"
	if not DirAccess.dir_exists_absolute(folder):
		return null
	var frames = []
	var frame_index = 0
	while true:
		var path = folder + bg_id + "_%03d.png" % frame_index
		if not ResourceLoader.exists(path):
			break
		frames.append(load(path))
		frame_index += 1
	if frames.is_empty():
		return null
	var anim_tex = AnimatedTexture.new()
	anim_tex.frames = frames.size()
	for i in range(frames.size()):
		anim_tex.set_frame_texture(i, frames[i])
		anim_tex.set_frame_duration(i, 0.1)
	var rect = TextureRect.new()
	rect.texture = anim_tex
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.position = Vector2(0, 0)
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
