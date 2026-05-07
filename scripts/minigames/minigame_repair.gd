extends Node

# =========================================
# REPAIR PUZZLE MINI-GAME
# Connect power source to the machine by rotating pipe tiles
# =========================================

const TIME_LIMIT = 45.0

const TILE_TYPES = {
	"straight_ud":   5,
	"straight_rl":   10,
	"corner_ur":     3,
	"corner_rd":     6,
	"corner_dl":     12,
	"corner_lu":     9,
	"tee_u":         7,
	"tee_r":         14,
	"tee_d":         13,
	"tee_l":         11,
	"cross":         15,
}

const TILE_SPRITES = {
	"straight_ud": "║",
	"straight_rl": "═",
	"corner_ur":   "╚",
	"corner_rd":   "╔",
	"corner_dl":   "╗",
	"corner_lu":   "╝",
	"tee_u":       "╩",
	"tee_r":       "╠",
	"tee_d":       "╦",
	"tee_l":       "╣",
	"cross":       "╬",
}

const SRC_ICON = "⚡"
const TGT_ICON = "🔧"

const PUZZLES = {
	"easy": {
		"grid": [
			[10, 3, 5, 0],
			[6, 10, 6, 0],
			[0, 9, 10, 3],
			[0, 5, 5, 4],
		],
		"source": Vector2i(0, 0),
		"target": Vector2i(3, 3),
		"size": 4,
	},
	"medium": {
		"grid": [
			[10, 3, 5, 6, 3],
			[6, 10, 0, 10, 5],
			[0, 9, 0, 0, 12],
			[9, 5, 0, 10, 3],
			[5, 0, 6, 3, 4],
		],
		"source": Vector2i(0, 0),
		"target": Vector2i(4, 4),
		"size": 5,
	},
	"hard": {
		"grid": [
			[10, 3, 5, 6, 3, 5],
			[6, 10, 6, 10, 5, 6],
			[0, 9, 0, 0, 12, 0],
			[9, 5, 0, 10, 3, 0],
			[5, 0, 6, 3, 5, 6],
			[0, 5, 0, 6, 3, 4],
		],
		"source": Vector2i(0, 0),
		"target": Vector2i(5, 5),
		"size": 6,
	},
}

var canvas: CanvasLayer = null
var grid_container: GridContainer = null
var timer_label: Label = null
var moves_label: Label = null
var status_label: Label = null
var grid_scroll: ScrollContainer = null
var _minigame_base_instance: Node = null

var screen_w: float = 0.0
var screen_h: float = 0.0
var time_left: float = TIME_LIMIT
var moves_used: int = 0
var current_grid: Array = []
var grid_size: int = 4
var source_pos: Vector2i = Vector2i(0, 0)
var target_pos: Vector2i = Vector2i(3, 3)
var _done: bool = false
var _current_difficulty: String = "easy"

func _ready() -> void:
	screen_w = get_viewport().get_visible_rect().size.x
	screen_h = get_viewport().get_visible_rect().size.y
	_select_difficulty()
	_build_ui()
	
	_minigame_base_instance = load("res://scripts/minigames/MinigameBase.gd").new()
	add_child(_minigame_base_instance)
	_minigame_base_instance._build_base_canvas()
	_minigame_base_instance.canvas.visible = false

func _process(delta: float) -> void:
	if _done:
		return
	time_left -= delta
	if timer_label:
		timer_label.text = "⏱ " + str(int(ceil(time_left))) + "s"
		if time_left <= 10:
			timer_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	if time_left <= 0:
		_finish(false)

func _select_difficulty() -> void:
	var roll = randf()
	if roll < 0.5:
		_current_difficulty = "easy"
		grid_size = 4
	elif roll < 0.8:
		_current_difficulty = "medium"
		grid_size = 5
	else:
		_current_difficulty = "hard"
		grid_size = 6

func _reset_puzzle() -> void:
	var puzzle = PUZZLES[_current_difficulty]
	current_grid = []
	for row in range(grid_size):
		current_grid.append([])
		for col in range(grid_size):
			current_grid[row].append(puzzle["grid"][row][col])
	
	source_pos = puzzle["source"]
	target_pos = puzzle["target"]
	moves_used = 0
	_update_moves_label()
	await get_tree().process_frame
	_refresh_grid()

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)
	canvas.layer = 100

	var bg = ColorRect.new()
	bg.color = GameTheme.get_color("bg")
	bg.position = Vector2(0, 0)
	bg.size = Vector2(screen_w, screen_h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)

	var panel = PanelContainer.new()
	panel.position = Vector2(screen_w * 0.02, screen_h * 0.02)
	panel.size = Vector2(screen_w * 0.96, screen_h * 0.96)
	panel.custom_minimum_size = panel.size
	panel.add_theme_stylebox_override("panel",
		GameTheme.make_panel_style("dark", GameTheme.DIALOGUE_BORDER_W)
	)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(vbox)

	# Header row
	var header_row = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var title = Label.new()
	title.text = "MACHINE REPAIR"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", GameTheme.get_color("accent"))
	GameTheme.apply_font(title, 18)
	header_row.add_child(title)

	timer_label = Label.new()
	timer_label.text = "⏱ " + str(int(TIME_LIMIT)) + "s"
	timer_label.add_theme_color_override("font_color", GameTheme.get_color("text"))
	GameTheme.apply_font(timer_label, 16)
	header_row.add_child(timer_label)

	# Info row
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 12)
	vbox.add_child(info_row)
	
	moves_label = Label.new()
	moves_label.text = "🌀 MOVES: 0"
	moves_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	moves_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(moves_label, 12)
	info_row.add_child(moves_label)
	
	status_label = Label.new()
	status_label.text = "Tap tiles to rotate"
	status_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))
	GameTheme.apply_font(status_label, 11)
	info_row.add_child(status_label)

	var divider = ColorRect.new()
	divider.color = GameTheme.get_color("accent")
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider)

	# Grid container with scroll
	grid_scroll = ScrollContainer.new()
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(grid_scroll)

	grid_container = GridContainer.new()
	grid_container.columns = grid_size
	grid_container.add_theme_constant_override("h_separation", 4)
	grid_container.add_theme_constant_override("v_separation", 4)
	grid_scroll.add_child(grid_container)

	# Button row
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var reset_btn = GameTheme.build_button("🔄  RESET", false, 12)
	reset_btn.custom_minimum_size = Vector2(screen_w * 0.28, 40)
	GameTheme.connect_button(reset_btn, _reset_puzzle)
	btn_row.add_child(reset_btn)

	var submit_btn = GameTheme.build_button("✓  TEST", true, 12)
	submit_btn.custom_minimum_size = Vector2(screen_w * 0.28, 40)
	GameTheme.connect_button(submit_btn, _submit)
	btn_row.add_child(submit_btn)
	
	call_deferred("_reset_puzzle")

func _refresh_grid() -> void:
	if grid_container == null:
		return
		
	for child in grid_container.get_children():
		child.queue_free()
	
	var tile_size = 48
	if screen_w < 400:
		tile_size = 40
	
	grid_container.columns = grid_size
	
	for row in range(grid_size):
		for col in range(grid_size):
			var tile_value = current_grid[row][col]
			var is_source = (row == source_pos.x and col == source_pos.y)
			var is_target = (row == target_pos.x and col == target_pos.y)
			
			var btn = _make_tile_button(tile_value, is_source, is_target, row, col, tile_size)
			grid_container.add_child(btn)

func _make_tile_button(tile_value: int, is_source: bool, is_target: bool, row: int, col: int, size: int) -> PanelContainer:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(size, size)
	container.size = Vector2(size, size)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style = StyleBoxFlat.new()
	if is_source or is_target:
		style.bg_color = GameTheme.get_color("panel_dark")
	else:
		style.bg_color = GameTheme.get_color("panel_mid")
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = GameTheme.get_color("accent")
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	container.add_theme_stylebox_override("panel", style)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(center)
	
	var content = HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	
	if is_source:
		var label = Label.new()
		label.text = SRC_ICON
		label.add_theme_font_size_override("font_size", int(size * 0.5))
		content.add_child(label)
	elif is_target:
		var label = Label.new()
		label.text = TGT_ICON
		label.add_theme_font_size_override("font_size", int(size * 0.5))
		content.add_child(label)
	else:
		var tile_type = _get_tile_type_from_value(tile_value)
		var symbol = TILE_SPRITES.get(tile_type, "?")
		var label = Label.new()
		label.text = symbol
		label.add_theme_font_size_override("font_size", int(size * 0.45))
		label.add_theme_color_override("font_color", GameTheme.get_color("accent"))
		content.add_child(label)
	
	center.add_child(content)
	
	container.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not _done:
			_rotate_tile(row, col)
	)
	
	return container

func _get_tile_type_from_value(value: int) -> String:
	for type_name in TILE_TYPES:
		if TILE_TYPES[type_name] == value:
			return type_name
	return "straight_ud"

func _rotate_tile(row: int, col: int) -> void:
	if _done:
		return
	
	var is_source = (row == source_pos.x and col == source_pos.y)
	var is_target = (row == target_pos.x and col == target_pos.y)
	
	if is_source or is_target:
		return
	
	var current = current_grid[row][col]
	var rotated = _get_rotated_value(current)
	
	print("Tile at [", row, "][", col, "] ", current, " -> ", rotated)
	
	current_grid[row][col] = rotated
	moves_used += 1
	_update_moves_label()
	_refresh_grid()
	
	if _check_connection():
		_finish(true)

func _get_rotated_value(value: int) -> int:
	var rotated = 0
	if value & 1: rotated |= 2
	if value & 2: rotated |= 4
	if value & 4: rotated |= 8
	if value & 8: rotated |= 1
	return rotated

func _check_connection() -> bool:
	var visited = []
	for i in range(grid_size):
		visited.append([])
		for j in range(grid_size):
			visited[i].append(false)
	
	return _dfs(source_pos.x, source_pos.y, visited, -1)

func _dfs(row: int, col: int, visited: Array, came_from: int) -> bool:
	if row < 0 or row >= grid_size or col < 0 or col >= grid_size:
		return false
	if visited[row][col]:
		return false
	
	visited[row][col] = true
	
	if row == target_pos.x and col == target_pos.y:
		return true
	
	var tile = current_grid[row][col]
	var connections = []
	
	if tile & 1 and came_from != 4:
		connections.append(Vector2i(row - 1, col))
	if tile & 2 and came_from != 8:
		connections.append(Vector2i(row, col + 1))
	if tile & 4 and came_from != 1:
		connections.append(Vector2i(row + 1, col))
	if tile & 8 and came_from != 2:
		connections.append(Vector2i(row, col - 1))
	
	for next_pos in connections:
		var nr = next_pos.x
		var nc = next_pos.y
		if nr < 0 or nr >= grid_size or nc < 0 or nc >= grid_size:
			continue
		
		var opposite_dir = 0
		if nr == row - 1: opposite_dir = 4
		elif nr == row + 1: opposite_dir = 1
		elif nc == col - 1: opposite_dir = 2
		elif nc == col + 1: opposite_dir = 8
		
		var next_tile = current_grid[nr][nc]
		if next_tile & opposite_dir:
			if _dfs(nr, nc, visited, opposite_dir):
				return true
	
	return false

func _update_moves_label() -> void:
	if moves_label:
		moves_label.text = "🌀 MOVES: " + str(moves_used)

func _submit() -> void:
	if _check_connection():
		_finish(true)
	else:
		status_label.text = "✗ NOT CONNECTED!"
		status_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
		await get_tree().create_timer(1.5).timeout
		status_label.text = "Tap tiles to rotate"
		status_label.add_theme_color_override("font_color", GameTheme.get_color("dim"))

func _finish(success: bool) -> void:
	if _done:
		return
	_done = true
	
	var score = 0.0
	if success:
		var moves_bonus = max(0, 1.0 - (moves_used / 25.0))
		var time_bonus = max(0, time_left / TIME_LIMIT)
		score = 0.4 + (moves_bonus * 0.3) + (time_bonus * 0.3)
		score = clamp(score, 0.0, 1.0)
		
		status_label.text = "✓ REPAIR SUCCESSFUL!"
		status_label.add_theme_color_override("font_color", GameTheme.get_color("positive"))
	else:
		score = 0.15
		status_label.text = "✗ REPAIR FAILED"
		status_label.add_theme_color_override("font_color", GameTheme.get_color("negative"))
	
	await get_tree().create_timer(0.5).timeout
	
	if _minigame_base_instance:
		_minigame_base_instance.show_results(score)
		canvas.visible = false

func _on_continue() -> void:
	MinigameManager.return_to_dialogue(MinigameManager.get_pending_next())
