extends Node2D

# =========================================
# CONSTANTS
# =========================================
# All colors now come from GameTheme - no hardcoded values!
var COLOR_BG         = Color()
var COLOR_PANEL_DARK = Color()
var COLOR_PANEL_MID  = Color()
var COLOR_ACCENT     = Color()
var COLOR_PURPLE     = Color()
var COLOR_TEXT       = Color()
var COLOR_DIM        = Color()

var HUD_HEIGHT       = 0.0
var HUD_Y            = 0.0
var DIALOGUEBOX_H    = 0.0

var _npc_sprite_node: Control = null

# =========================================
# REFERENCES
# =========================================
@onready var SCREEN_W = get_viewport().get_visible_rect().size.x
@onready var SCREEN_H = get_viewport().get_visible_rect().size.y

var canvas:            CanvasLayer      = null
var background:        ColorRect        = null
var vignette:          ColorRect        = null
var sprite_area:       Control          = null
var stats_hud:         PanelContainer   = null
var dialogue_box:      PanelContainer   = null
var choices_container: VBoxContainer    = null

# ── Shop sprite (center of sprite_area) ──────────────────────
var shop_sprite_host:  Control          = null
var shop_sprite:       Node             = null
var _current_business_id: String        = ""

# ── Character slots ───────────────────────────────────────────
var npc_placeholder:    PanelContainer  = null
var player_placeholder: PanelContainer  = null
var _current_speaker_id: String         = ""

# ── Scene interval state ──────────────────────────────────────
var _interval_skipped: bool             = false

var SPRITE_AREA_Y: float = 0.0
var SPRITE_AREA_H: float = 0.0

# =========================================
# STATE
# =========================================
var _is_transitioning: bool = false
var _is_day_start: bool = true

# =========================================
# LIFECYCLE
# =========================================
func _ready() -> void:
	# Load theme based on business
	var business_id = SaveManager.get_active_business_id()
	var business_def = SaveManager.get_business_def(business_id)
	var theme_id = business_def.get("theme", business_id)
	GameTheme.set_theme(theme_id)
	
	# Load settings
	var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			var saved = json.get_data()
			GameTheme.set_text_speed(saved.get("text_speed", 1))
			GameTheme.set_vibration(saved.get("vibration", true))
	
	# Get all colors from GameTheme
	_refresh_colors()
	
	# Get dimensions from GameTheme
	HUD_HEIGHT    = GameTheme.HUD_HEIGHT
	HUD_Y         = GameTheme.HUD_Y
	DIALOGUEBOX_H = GameTheme.DIALOGUEBOX_H
	
	# Calculate sprite area
	SPRITE_AREA_H = SCREEN_H - HUD_Y - HUD_HEIGHT - DIALOGUEBOX_H
	SPRITE_AREA_Y = HUD_Y + HUD_HEIGHT
	
	# Set business ID for shop sprite
	_current_business_id = SaveManager.get_active_business_id()
	if _current_business_id == "":
		_current_business_id = "laundromat"
	
	# Build UI
	_build_canvas()
	_build_background()
	_build_vignette()
	_build_stats_hud()
	_build_sprite_area()
	_build_choices_container()
	_build_dialogue_box()
	_build_burger_button()
	_connect_signals()
	
	# Add floating particles for visual flair
	_add_ambient_particles()
	
	AudioManager.play_music("gameplay", 0.3)
	
	call_deferred("_start_dialogue")

func _refresh_colors() -> void:
	"""Refresh all colors from current theme"""
	COLOR_BG         = GameTheme.get_color("bg")
	COLOR_PANEL_DARK = GameTheme.get_color("panel_dark")
	COLOR_PANEL_MID  = GameTheme.get_color("panel_mid")
	COLOR_ACCENT     = GameTheme.get_color("accent")
	COLOR_PURPLE     = GameTheme.get_color("reputation")
	COLOR_TEXT       = GameTheme.get_color("text")
	COLOR_DIM        = GameTheme.get_color("dim")

# =========================================
# BUILD
# =========================================
func _build_canvas() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

func _build_background() -> void:
	background = GameTheme.get_bg_for_scene(
		"shop_day",
		canvas,
		Vector2(SCREEN_W, SCREEN_H)
	)
	canvas.add_child(background)

func _build_vignette() -> void:
	vignette = ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.15)
	vignette.position = Vector2(0, 0)
	vignette.size = Vector2(SCREEN_W, SCREEN_H)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(vignette)

func _add_ambient_particles() -> void:
	"""Add floating particles using theme accent color"""
	var particle_layer = CanvasLayer.new()
	particle_layer.layer = 5
	add_child(particle_layer)
	
	for i in range(20):
		var particle = ColorRect.new()
		var size = randf_range(1, 3)
		particle.size = Vector2(size, size)
		particle.color = Color(
			COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b,
			randf_range(0.05, 0.15)
		)
		particle.position = Vector2(
			randf_range(0, SCREEN_W),
			randf_range(0, SCREEN_H)
		)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle_layer.add_child(particle)
		
		# Create animation WITHOUT set_loops() to avoid infinite loop
		var duration = randf_range(3, 6)
		var target_y = particle.position.y - randf_range(50, 150)
		var target_x = particle.position.x + randf_range(-20, 20)
		
		var tween = create_tween()
		# DON'T use set_loops() - just animate once and free
		tween.tween_property(particle, "position:y", target_y, duration)
		tween.parallel().tween_property(particle, "position:x", target_x, duration)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
		tween.tween_callback(particle.queue_free)

func _build_shop_sprite_host() -> void:
	var slot_w := GameTheme.SCENE_SPRITE_DISPLAY_SIZE.x
	var slot_h := GameTheme.SCENE_SPRITE_DISPLAY_SIZE.y
	shop_sprite_host = Control.new()
	shop_sprite_host.position = Vector2(
		(SCREEN_W - slot_w) * 0.5,
		SPRITE_AREA_H - slot_h
	)
	shop_sprite_host.size = Vector2(slot_w, slot_h)
	shop_sprite_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_sprite_host.visible = false
	sprite_area.add_child(shop_sprite_host)
	_load_shop_sprite("idle")

func _build_stats_hud() -> void:
	stats_hud = PanelContainer.new()
	stats_hud.position = Vector2(0, HUD_Y)
	stats_hud.size = Vector2(SCREEN_W, HUD_HEIGHT)
	canvas.add_child(stats_hud)
	stats_hud.set_script(load("res://scripts/status_hud.gd"))
	stats_hud.call("setup")

func _build_sprite_area() -> void:
	sprite_area = Control.new()
	sprite_area.position = Vector2(0, SPRITE_AREA_Y)
	sprite_area.size = Vector2(SCREEN_W, SPRITE_AREA_H)
	sprite_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_area.modulate = Color(1, 1, 1, 1)
	canvas.add_child(sprite_area)
	_build_shop_sprite_host()
	_build_npc_placeholder()
	_build_player_placeholder()

func _build_npc_placeholder() -> void:
	# Create a vertical container for NPC sprite + name on RIGHT side
	var npc_container = VBoxContainer.new()
	npc_container.position = Vector2(SCREEN_W - 150, SPRITE_AREA_H - 180)  # Right side
	npc_container.size = Vector2(120, 150)
	npc_container.alignment = BoxContainer.ALIGNMENT_CENTER
	npc_container.add_theme_constant_override("separation", 4)
	sprite_area.add_child(npc_container)
	
	# Sprite container with FIXED size
	var npc_sprite_container = PanelContainer.new()
	npc_sprite_container.custom_minimum_size = Vector2(100, 120)
	npc_sprite_container.size = Vector2(100, 120)
	npc_sprite_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	npc_sprite_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var sprite_style = StyleBoxFlat.new()
	sprite_style.bg_color = COLOR_PANEL_MID
	sprite_style.border_width_top = 2
	sprite_style.border_width_bottom = 2
	sprite_style.border_width_left = 2
	sprite_style.border_width_right = 2
	sprite_style.border_color = COLOR_PURPLE
	sprite_style.corner_radius_top_left = 8
	sprite_style.corner_radius_top_right = 8
	sprite_style.corner_radius_bottom_left = 8
	sprite_style.corner_radius_bottom_right = 8
	npc_sprite_container.add_theme_stylebox_override("panel", sprite_style)
	npc_container.add_child(npc_sprite_container)
	
	# Label below sprite
	var npc_name_label = Label.new()
	npc_name_label.text = ""
	npc_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	npc_name_label.add_theme_font_size_override("font_size", 10)
	npc_name_label.add_theme_color_override("font_color", COLOR_ACCENT)
	GameTheme.apply_font(npc_name_label, 10)
	npc_container.add_child(npc_name_label)
	
	# Store references
	npc_placeholder = npc_sprite_container
	sprite_area.set_meta("npc_container", npc_container)
	sprite_area.set_meta("npc_name_label", npc_name_label)

func _build_player_placeholder() -> void:
	# Create a vertical container for player sprite + name on LEFT side
	var player_container = VBoxContainer.new()
	player_container.position = Vector2(30, SPRITE_AREA_H - 180)  # Left side
	player_container.size = Vector2(100, 150)
	player_container.alignment = BoxContainer.ALIGNMENT_CENTER
	player_container.add_theme_constant_override("separation", 4)
	sprite_area.add_child(player_container)
	
	# Sprite container with FIXED size
	var player_sprite_container = PanelContainer.new()
	player_sprite_container.custom_minimum_size = Vector2(80, 110)
	player_sprite_container.size = Vector2(80, 110)
	player_sprite_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	player_sprite_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var sprite_style = StyleBoxFlat.new()
	sprite_style.bg_color = COLOR_PANEL_DARK
	sprite_style.border_width_top = 2
	sprite_style.border_width_bottom = 2
	sprite_style.border_width_left = 2
	sprite_style.border_width_right = 2
	sprite_style.border_color = COLOR_ACCENT
	sprite_style.corner_radius_top_left = 8
	sprite_style.corner_radius_top_right = 8
	sprite_style.corner_radius_bottom_left = 8
	sprite_style.corner_radius_bottom_right = 8
	player_sprite_container.add_theme_stylebox_override("panel", sprite_style)
	player_container.add_child(player_sprite_container)
	
	# Label below sprite
	var player_name_label = Label.new()
	player_name_label.text = "YOU"
	player_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_name_label.add_theme_font_size_override("font_size", 10)
	player_name_label.add_theme_color_override("font_color", COLOR_ACCENT)
	GameTheme.apply_font(player_name_label, 10)
	player_container.add_child(player_name_label)
	
	# Store references
	player_placeholder = player_sprite_container
	sprite_area.set_meta("player_container", player_container)

func _build_choices_container() -> void:
	choices_container = VBoxContainer.new()
	choices_container.position = Vector2(0, SCREEN_H - DIALOGUEBOX_H - 10)
	choices_container.size = Vector2(SCREEN_W, 0)
	canvas.add_child(choices_container)
	choices_container.set_script(load("res://scripts/choices_container.gd"))
	choices_container.call("setup")
	

func _build_dialogue_box() -> void:
	dialogue_box = PanelContainer.new()
	dialogue_box.position = Vector2(0, SCREEN_H - DIALOGUEBOX_H)
	dialogue_box.size = Vector2(SCREEN_W, DIALOGUEBOX_H)
	dialogue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_box.custom_minimum_size = Vector2(SCREEN_W, DIALOGUEBOX_H)
	
	# Use GameTheme panel style
	dialogue_box.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	dialogue_box.modulate = Color(1, 1, 1, 1 )
	
	canvas.add_child(dialogue_box)
	dialogue_box.set_script(load("res://scripts/dialogue_box.gd"))
	dialogue_box.call("setup")

# TEMPO FIX
func _load_shop_sprite(state: String = "idle") -> void:
	if shop_sprite_host == null:
		return
		
	# Clear previous sprite properly
	if shop_sprite != null:
		if shop_sprite is AnimatedSprite2D:
			shop_sprite.stop()
		shop_sprite.queue_free()
		shop_sprite = null
	
	var new_sprite = GameTheme.make_scene_sprite_for(_current_business_id, state)
	if new_sprite == null:
		shop_sprite_host.visible = false
		return
	
	# Handle TextureRect (static image)
	if new_sprite is TextureRect:
		# Make it fill the entire host container
		new_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		new_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Handle AnimatedSprite2D (if you add animations later)
	elif new_sprite is AnimatedSprite2D:
		new_sprite.position = Vector2(
			GameTheme.SCENE_SPRITE_DISPLAY_SIZE.x * 0.5,
			GameTheme.SCENE_SPRITE_DISPLAY_SIZE.y * 0.5
		)
		new_sprite.centered = true
	
	shop_sprite_host.add_child(new_sprite)
	shop_sprite = new_sprite
	shop_sprite_host.visible = true

func _set_shop_sprite_playing(playing: bool) -> void:
	if shop_sprite == null:
		return
	# Only animated sprites have play/stop
	if shop_sprite is AnimatedSprite2D:
		if playing:
			shop_sprite.play()
		else:
			shop_sprite.stop()

func _build_burger_button() -> void:
	var burger_btn = PanelContainer.new()
	burger_btn.position = Vector2(SCREEN_W - 36, HUD_Y + 4)
	burger_btn.size = Vector2(28, 28)
	burger_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 0, 0, 0.55)
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_color = Color(COLOR_ACCENT, 0.6)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	burger_btn.add_theme_stylebox_override("panel", btn_style)
	
	var btn_lbl = Label.new()
	btn_lbl.text = "☰"
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_lbl.add_theme_font_size_override("font_size", 12)
	btn_lbl.add_theme_color_override("font_color", COLOR_ACCENT)
	burger_btn.add_child(btn_lbl)
	canvas.add_child(burger_btn)
	GameTheme.connect_button(burger_btn, _on_burger_pressed)
	
	var pause_menu_scene = load("res://scenes/pause_menu.tscn")
	if pause_menu_scene:
		var pm = pause_menu_scene.instantiate()
		add_child(pm)
		set_meta("pause_menu", pm)

func _on_burger_pressed() -> void:
	if has_meta("pause_menu"):
		get_meta("pause_menu").toggle()

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
	if not (dialogue_box as PanelContainer).visible:
		_interval_skipped = true
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
	await get_tree().process_frame
	_is_day_start = true

	if MinigameManager.is_resuming():
		var next_node = MinigameManager.consume_resume()
		if next_node != "" and next_node != "end":
			DialogueManager._load_node(next_node)
		else:
			DialogueManager._on_event_end()
		var node = DialogueManager.get_current_node()
		if not node.is_empty():
			call_deferred("_push_first_node", node)
		return

	if SaveManager.is_loaded_from_save():
		SaveManager.consume_loaded_flag()
		
		var is_day_complete = (DialogueManager.total_events > 0 and
			DialogueManager.current_event >= DialogueManager.total_events)
		
		if is_day_complete:
			DialogueManager.apply_inventory_items()
			var file_name = DialogueManager.get_day_file(DialogueManager.get_current_day())
			DialogueManager.load_dialogue(file_name)
			var node = DialogueManager.get_current_node()
			if node.is_empty():
				push_error("DialogueScene: current node empty after day-complete resume")
				return
			call_deferred("_push_first_node", node)
			return
		
		var node = DialogueManager.get_current_node()
		if node.is_empty():
			push_error("DialogueScene: current_node empty after load - attempting reload")
			DialogueManager._load_event(DialogueManager.current_event)
			node = DialogueManager.get_current_node()
		
		if not node.is_empty():
			call_deferred("_push_first_node", node)
		return

	DialogueManager.apply_inventory_items()
	var file_name = DialogueManager.get_day_file(DialogueManager.get_current_day())
	DialogueManager.load_dialogue(file_name)
	var node = DialogueManager.get_current_node()
	if node.is_empty():
		push_error("DialogueScene: current node empty after load")
		return
	call_deferred("_push_first_node", node)

func _push_first_node(node: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var choices = node.get("choices", [])
	var db = dialogue_box as PanelContainer
	var text = node.get("text", "")
	var speaker = node.get("speaker", "")

	if _is_day_start:
		_is_day_start = false
		
		_set_shop_sprite_playing(true)
		if db: db.visible = false
		
		# Day start flash using theme accent
		var flash = ColorRect.new()
		flash.color = Color(COLOR_ACCENT.r, COLOR_ACCENT.g, COLOR_ACCENT.b, 0.3)
		flash.position = Vector2(0, 0)
		flash.size = Vector2(SCREEN_W, SCREEN_H)
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(flash)
		
		var flash_tween = create_tween()
		flash_tween.tween_property(flash, "modulate:a", 0.0, 0.5)
		flash_tween.tween_callback(flash.queue_free)
		
		var elapsed := 0.0
		var delay_duration := 1.5
		while elapsed < delay_duration:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		
		if db:
			db.visible = true
			db.modulate = Color(1, 1, 1, 0)
			db.position.y = SCREEN_H - DIALOGUEBOX_H + 20
			var tween = create_tween()
			tween.tween_property(db, "modulate", Color(1, 1, 1, 1), 0.3)
			tween.parallel().tween_property(db, "position:y", SCREEN_H - DIALOGUEBOX_H, 0.35)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await tween.finished
		
		_set_shop_sprite_playing(false)
	else:
		if db and db.visible == false:
			db.visible = true
			db.modulate = Color(1, 1, 1, 0)
			var tween = create_tween()
			tween.tween_property(db, "modulate", Color(1, 1, 1, 1), 0.15)
		_set_shop_sprite_playing(false)

	if db and db.has_method("show_dialogue"):
		db.show_dialogue(speaker, text)
		await db.dialogue_finished

	if choices.size() > 0:
		var cc = choices_container as VBoxContainer
		if cc and cc.has_method("show_choices"):
			cc.show_choices(choices)
			# Staggered fade-in for choices
			for i in range(cc.get_child_count()):
				var choice = cc.get_child(i)
				choice.modulate = Color(1, 1, 1, 0)
				var tween = create_tween()
				tween.tween_property(choice, "modulate", Color(1, 1, 1, 1), 0.2).set_delay(i * 0.05)

# =========================================
# CALLBACKS
# =========================================
func _on_dialogue_node_changed(speaker: String, text: String) -> void:
	_is_transitioning = true

	var node = DialogueManager.get_current_node()
	var choices = node.get("choices", [])
	var bg_id = DialogueManager.get_background_id()
	var speaker_id = DialogueManager.get_speaker_id()

	_swap_background(bg_id)
	_swap_npc(speaker_id)
	_swap_player(speaker_id)

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

# =========================================
# BACKGROUND AND NPC SWAPPING
# =========================================
var current_bg_id: String = ""

func _swap_background(bg_id: String) -> void:
	if bg_id == "" or bg_id == current_bg_id:
		return
	current_bg_id = bg_id
	background = GameTheme.swap_bg(
		bg_id,
		canvas,
		background,
		Vector2(SCREEN_W, SCREEN_H)
	)
	
	# Background tint comes from GameTheme now
	var sprite_state := "idle"
	match bg_id:
		"shop_day":     sprite_state = "idle"
		"shop_evening": sprite_state = "evening"
		"office":       sprite_state = "idle"
		"street":       sprite_state = "idle"
	_load_shop_sprite(sprite_state)

func _swap_npc(speaker_id: String) -> void:
	# If player is speaking, don't show anything on NPC side (or dim/hide it)
	if speaker_id == "player":
		# Dim the NPC placeholder if it has content
		if npc_placeholder and npc_placeholder.get_child_count() > 0:
			_dim_sprite(_current_speaker_id, true)
		_current_speaker_id = speaker_id
		return
	
	if npc_placeholder == null:
		return
	
	# FIRST: Dim the previous speaker if exists
	if _current_speaker_id != "" and _current_speaker_id != speaker_id:
		_dim_sprite(_current_speaker_id, true)
	
	var was_different = (speaker_id != _current_speaker_id)
	_current_speaker_id = speaker_id
	_dim_sprite(speaker_id, false)

	# Update name label
	var npc_container = sprite_area.get_meta("npc_container") if sprite_area.has_meta("npc_container") else null
	if npc_container:
		var name_label = npc_container.get_child(1) if npc_container.get_child_count() > 1 else null
		if name_label and name_label is Label:
			var display_name = ""
			match speaker_id:
				"mentor":     display_name = "MENTOR"
				"customer":   display_name = "CUSTOMER"
				"supplier":   display_name = "SUPPLIER"
				"staff":      display_name = "STAFF"
				"candidate":  display_name = "CANDIDATE"
				"influencer": display_name = "INFLUENCER"
				"inspector":  display_name = "INSPECTOR"
				"corporate":  display_name = "CORPORATE"
				_:            display_name = speaker_id.to_upper()
			name_label.text = display_name
	
	if not was_different:
		return
	
	var asset_path := GameTheme.get_char_path(speaker_id)
	
	# Clear existing children
	for child in npc_placeholder.get_children():
		child.queue_free()
	
	if asset_path != "":
		var texture = load(asset_path) as Texture2D
		var tex_rect = TextureRect.new()
		tex_rect.texture = texture
		
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.set_meta("speaker_id", speaker_id)
		
		npc_placeholder.add_child(tex_rect)
		
		await get_tree().process_frame
		tex_rect.size = npc_placeholder.size
		
		_set_placeholder_border(npc_placeholder, _speaker_color(speaker_id))
		return

	# No asset — show emoji label placeholder
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", COLOR_DIM)
	label.set_meta("speaker_id", speaker_id)

	match speaker_id:
		"mentor":     label.text = "🧑‍🏫"
		"customer":   label.text = "🧑"
		"supplier":   label.text = "🚚"
		"staff":      label.text = "👷"
		"candidate":  label.text = "🙋"
		"influencer": label.text = "📱"
		"inspector":  label.text = "📋"
		"corporate":  label.text = "💼"
		_:            label.text = "?"
	
	npc_placeholder.add_child(label)
	_set_placeholder_border(npc_placeholder, _speaker_color(speaker_id))

func _swap_player(speaker_id: String) -> void:
	if player_placeholder == null:
		return
	
	var is_player_talking = (speaker_id == "player")
	
	# Update name label (always show "YOU" on player side)
	var player_container = sprite_area.get_meta("player_container") if sprite_area.has_meta("player_container") else null
	if player_container:
		var name_label = player_container.get_child(1) if player_container.get_child_count() > 1 else null
		if name_label and name_label is Label:
			name_label.text = "YOU"
	
	# Dim/Brighten logic
	if is_player_talking:
		_dim_sprite("player", false)  # Brighten player
	else:
		_dim_sprite("player", true)   # Dim player when NPC speaks
	
	# Load sprite only once
	if player_placeholder.get_child_count() == 0:
		var asset_path := GameTheme.get_char_path("player")
		
		if asset_path != "" and ResourceLoader.exists(asset_path):
			var texture = load(asset_path) as Texture2D
			var tex_rect = TextureRect.new()
			tex_rect.texture = texture
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tex_rect.set_meta("speaker_id", "player")
			player_placeholder.add_child(tex_rect)
			
			await get_tree().process_frame
			tex_rect.size = player_placeholder.size
		else:
			# Fallback emoji
			var label = Label.new()
			label.text = "👤"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			label.add_theme_font_size_override("font_size", 32)
			label.add_theme_color_override("font_color", COLOR_ACCENT)
			label.set_meta("speaker_id", "player")
			player_placeholder.add_child(label)

func _speaker_color(speaker_id: String) -> Color:
	# Use theme colors for speaker borders
	match speaker_id:
		"mentor":     return COLOR_ACCENT
		"customer":   return COLOR_PURPLE
		"supplier":   return GameTheme.get_color("morale")
		"staff":      return Color("#3a5f8b")
		"candidate":  return COLOR_PURPLE
		"influencer": return COLOR_ACCENT
		"inspector":  return GameTheme.get_color("stress")
		"corporate":  return Color("#3a5f8b")
		"player":     return COLOR_ACCENT
		_:            return COLOR_PANEL_MID

func _set_placeholder_border(panel: PanelContainer, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_MID
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = color
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", style)
	
func _dim_sprite(speaker_id: String, dim: bool) -> void:
	"""Dim or brighten a character sprite (NPC or Player)"""
	var sprite_node = null
	
	# Check NPC placeholder
	if npc_placeholder and npc_placeholder.get_child_count() > 0:
		var child = npc_placeholder.get_child(0)
		if child.has_meta("speaker_id") and child.get_meta("speaker_id") == speaker_id:
			sprite_node = child
	
	# Check Player placeholder
	if player_placeholder and player_placeholder.get_child_count() > 0 and sprite_node == null:
		var child = player_placeholder.get_child(0)
		if child.has_meta("speaker_id") and child.get_meta("speaker_id") == speaker_id:
			sprite_node = child
	
	if sprite_node:
		var target_color = Color(0.5, 0.5, 0.5, 1.0) if dim else Color(1, 1, 1, 1)
		var tween = create_tween()
		tween.tween_property(sprite_node, "modulate", target_color, 0.2)
