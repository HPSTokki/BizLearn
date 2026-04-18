extends Node2D

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

const HUD_HEIGHT      = 36.0
const HUD_Y           = 20.0
const DIALOGUEBOX_H   = 160.0

# =========================================
# REFERENCES
# =========================================
@onready var SCREEN_W = get_viewport().get_visible_rect().size.x
@onready var SCREEN_H = get_viewport().get_visible_rect().size.y

var canvas:            CanvasLayer   = null
var background:        ColorRect     = null
var vignette:          ColorRect     = null
var scene_label:       Label         = null
var sprite_area:       Control       = null
var stats_hud:         PanelContainer = null
var dialogue_box:      PanelContainer = null
var choices_container: VBoxContainer  = null

var SPRITE_AREA_Y: float = 0.0
var SPRITE_AREA_H: float = 0.0

# =========================================
# STATE
# =========================================
var _is_transitioning: bool = false

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	SPRITE_AREA_Y = HUD_Y + HUD_HEIGHT
	SPRITE_AREA_H = SCREEN_H - HUD_Y - HUD_HEIGHT - DIALOGUEBOX_H

	_build_canvas()
	_build_background()
	_build_vignette()
	_build_scene_label()
	_build_stats_hud()
	_build_sprite_area()
	_build_choices_container()
	_build_dialogue_box()
	_connect_signals()

	call_deferred("_start_dialogue")


# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)


func _build_background() -> void:
	background          = ColorRect.new()
	background.color    = COLOR_BG
	background.position = Vector2(0, 0)
	background.size     = Vector2(SCREEN_W, SCREEN_H)
	canvas.add_child(background)


func _build_vignette() -> void:
	vignette              = ColorRect.new()
	vignette.color        = Color(0, 0, 0, 0.15)
	vignette.position     = Vector2(0, 0)
	vignette.size         = Vector2(SCREEN_W, SCREEN_H)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(vignette)


func _build_scene_label() -> void:
	scene_label                      = Label.new()
	scene_label.text                 = "📍 Your Shop - Day " + str(DialogueManager.get_current_day())
	scene_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_label.position             = Vector2(0, 4)
	scene_label.size                 = Vector2(SCREEN_W, 16)
	scene_label.add_theme_font_size_override("font_size", 7)
	scene_label.add_theme_color_override("font_color", COLOR_ACCENT)
	canvas.add_child(scene_label)


func _build_stats_hud() -> void:
	stats_hud          = PanelContainer.new()
	stats_hud.position = Vector2(0, HUD_Y)
	stats_hud.size     = Vector2(SCREEN_W, HUD_HEIGHT)
	canvas.add_child(stats_hud)
	stats_hud.set_script(load("res://scripts/status_hud.gd"))
	stats_hud.call("setup")


func _build_sprite_area() -> void:
	sprite_area              = Control.new()
	sprite_area.position     = Vector2(0, SPRITE_AREA_Y)
	sprite_area.size         = Vector2(SCREEN_W, SPRITE_AREA_H)
	sprite_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(sprite_area)
	_build_npc_placeholder()
	_build_player_placeholder()


func _build_npc_placeholder() -> void:
	var npc      = PanelContainer.new()
	npc.position = Vector2(SCREEN_W - 110, SPRITE_AREA_H - 120)
	npc.size     = Vector2(80, 120)

	var style = StyleBoxFlat.new()
	style.bg_color                   = COLOR_PANEL_MID
	style.border_width_top           = 2
	style.border_width_bottom        = 2
	style.border_width_left          = 2
	style.border_width_right         = 2
	style.border_color               = COLOR_PURPLE
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	npc.add_theme_stylebox_override("panel", style)

	var label                  = Label.new()
	label.text                 = "NPC"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.position             = Vector2(0, 0)
	label.size                 = Vector2(80, 120)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", COLOR_DIM)
	npc.add_child(label)
	sprite_area.add_child(npc)


func _build_player_placeholder() -> void:
	var player       = PanelContainer.new()
	player.position  = Vector2(30, SPRITE_AREA_H - 110)
	player.size      = Vector2(70, 110)

	var style = StyleBoxFlat.new()
	style.bg_color                   = COLOR_PANEL_DARK
	style.border_width_top           = 2
	style.border_width_bottom        = 2
	style.border_width_left          = 2
	style.border_width_right         = 2
	style.border_color               = COLOR_ACCENT
	style.corner_radius_top_left     = 0
	style.corner_radius_top_right    = 0
	style.corner_radius_bottom_left  = 0
	style.corner_radius_bottom_right = 0
	player.add_theme_stylebox_override("panel", style)

	var label                  = Label.new()
	label.text                 = "YOU"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.position             = Vector2(0, 0)
	label.size                 = Vector2(70, 110)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", COLOR_DIM)
	player.add_child(label)
	sprite_area.add_child(player)


func _build_choices_container() -> void:
	choices_container          = VBoxContainer.new()
	choices_container.position = Vector2(0, SCREEN_H - DIALOGUEBOX_H - 10)
	choices_container.size     = Vector2(SCREEN_W, 0)
	canvas.add_child(choices_container)
	choices_container.set_script(load("res://scripts/choices_container.gd"))
	choices_container.call("setup")


func _build_dialogue_box() -> void:
	dialogue_box                    = PanelContainer.new()
	dialogue_box.position           = Vector2(0, SCREEN_H - DIALOGUEBOX_H)
	dialogue_box.size               = Vector2(SCREEN_W, DIALOGUEBOX_H)
	dialogue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_box.custom_minimum_size   = Vector2(SCREEN_W, DIALOGUEBOX_H)
	canvas.add_child(dialogue_box)
	dialogue_box.set_script(load("res://scripts/dialogue_box.gd"))
	dialogue_box.call("setup")


# =========================================
# SIGNALS
# =========================================
func _connect_signals() -> void:
	if DialogueManager.dialogue_updated.is_connected(_on_dialogue_node_changed):
		DialogueManager.dialogue_updated.disconnect(_on_dialogue_node_changed)
	if DialogueManager.event_completed.is_connected(_on_event_completed):
		DialogueManager.event_completed.disconnect(_on_event_completed)
	if DialogueManager.day_ended.is_connected(_on_day_ended):
		DialogueManager.day_ended.disconnect(_on_day_ended)

	DialogueManager.dialogue_updated.connect(_on_dialogue_node_changed)
	DialogueManager.event_completed.connect(_on_event_completed)
	DialogueManager.day_ended.connect(_on_day_ended)


# =========================================
# INPUT
# =========================================
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_on_screen_tapped()
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_on_screen_tapped()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		_on_screen_tapped()


func _on_screen_tapped() -> void:
	if _is_transitioning:
		return
	if choices_container.visible:
		return
	var db = dialogue_box as PanelContainer
	if db and db.has_method("on_screen_tapped"):
		db.on_screen_tapped()
	else:
		DialogueManager.advance()


# =========================================
# PRIVATE
# =========================================
func _start_dialogue() -> void:
	DialogueManager.load_dialogue("day" + str(DialogueManager.get_current_day()))
	var node = DialogueManager.get_current_node()
	if node.is_empty():
		push_error("DialogueScene: current node empty after load")
		return
	call_deferred("_push_first_node", node)


func _push_first_node(node: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var choices = node.get("choices", [])
	var db      = dialogue_box as PanelContainer

	if db and db.has_method("show_dialogue"):
		db.show_dialogue(
			node.get("speaker", ""),
			node.get("text", "")
		)
		if choices.size() > 0:
			await db.dialogue_finished

	if choices.size() > 0:
		var cc = choices_container as VBoxContainer
		if cc and cc.has_method("show_choices"):
			cc.show_choices(choices)


# =========================================
# CALLBACKS
# =========================================
func _on_dialogue_node_changed(speaker: String, text: String) -> void:
	_is_transitioning = true

	var node    = DialogueManager.get_current_node()
	var choices = node.get("choices", [])

	var cc = choices_container as VBoxContainer
	if cc and cc.has_method("hide_choices"):
		cc.hide_choices()

	var db = dialogue_box as PanelContainer
	if db and db.has_method("show_dialogue"):
		db.show_dialogue(speaker, text)
		if choices.size() > 0:
			await db.dialogue_finished

	if choices.size() > 0:
		if cc and cc.has_method("show_choices"):
			cc.show_choices(choices)

	_is_transitioning = false


func _on_event_completed(_current_event: int, _total_events: int) -> void:
	_is_transitioning = true
	await get_tree().create_timer(0.5).timeout
	var cc = choices_container as VBoxContainer
	if cc and cc.has_method("hide_choices"):
		cc.hide_choices()
	_is_transitioning = false


func _on_day_ended(_day: int, _stat_deltas: Dictionary) -> void:
	_is_transitioning = true
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/analytics_scene.tscn")


func _on_dialogue_ended() -> void:
	pass
