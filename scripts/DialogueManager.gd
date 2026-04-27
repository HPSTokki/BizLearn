extends Node

# =========================================
# SIGNALS
# =========================================
signal dialogue_updated(speaker: String, text: String)
signal choices_updated(choices: Array)
signal stats_changed(stat_name: String, new_value: float)
signal minigame_triggered(minigame_id: String)
signal event_completed(current_event: int, total_events: int)
signal day_ended(day: int, stat_deltas: Dictionary)

# =========================================
# CONSTANTS
# =========================================
const STAT_MAX   = 100.0
const STAT_MIN   = 0.0
const TOTAL_DAYS = 5
const BRANCH_THRESHOLD_HIGH = 60.0
const BRANCH_THRESHOLD_LOW  = 40.0

# =========================================
# STATE
# =========================================
var current_node:  Dictionary = {}
var dialogue_data: Dictionary = {}

var current_day:   int = 1
var current_event: int = 0
var total_events:  int = 0

var current_branch: String = "normal"

var stats: Dictionary = {
	"money":      50.0,
	"reputation": 50.0,
	"morale":     50.0,
	"stress":     50.0
}

var stat_snapshot: Dictionary = {}

var used_random_events: Array = []
var permanent_consequences: Array = []  # Phase 2D hook

const SAVE_PATH = "user://savegame.cfg"

# =========================================
# ITEM / GOLD SYSTEM — add to STATE section
# =========================================
var gold:           int        = 50
var inventory:      Array      = []  # list of item ids
var items_data:     Array      = []  # loaded from items.json
var items_used_today: Array    = []  # reset each day

const GOLD_DAY_COMPLETE_BONUS  = 10
const GOLD_GOOD_CHOICE         = 20
const GOLD_NEUTRAL_CHOICE      = 10
const GOLD_POOR_CHOICE         = 3

# =========================================
# ITEM LOADING
# =========================================
func load_items() -> void:
	var path = "res://data/items.json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: Could not load items.json")
		return
	var json  = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		push_error("DialogueManager: items.json parse error")
		return
	items_data = json.get_data().get("items", [])
	print("DialogueManager: Loaded ", items_data.size(), " items")

func get_items_data() -> Array:
	return items_data

func get_available_items() -> Array:
	# Returns items available for current day
	# that player has not already purchased
	return items_data.filter(func(item):
		return item.get("available_from_day", 1) <= current_day \
			and not inventory.has(item.get("id", ""))
	)

func get_inventory() -> Array:
	return inventory

func get_gold() -> int:
	return gold

# =========================================
# GOLD EARNING
# =========================================
func earn_gold_from_choice(choice: Dictionary) -> void:
	var gold_earned = choice.get("gold", GOLD_NEUTRAL_CHOICE)
	gold += gold_earned
	print("DialogueManager: Earned ", gold_earned, " gold. Total: ", gold)

func _award_day_complete_bonus() -> void:
	gold += GOLD_DAY_COMPLETE_BONUS
	print("DialogueManager: Day complete bonus +", GOLD_DAY_COMPLETE_BONUS, " gold")

# =========================================
# SHOP SYSTEM
# =========================================
func buy_item(item_id: String) -> bool:
	# Find item
	var item = _get_item_by_id(item_id)
	if item.is_empty():
		push_error("DialogueManager: Item not found " + item_id)
		return false

	# Check already owned
	if inventory.has(item_id):
		push_warning("DialogueManager: Already own " + item_id)
		return false

	# Check gold
	var price = item.get("price", 0)
	if gold < price:
		push_warning("DialogueManager: Not enough gold")
		return false

	# Purchase
	gold -= price
	inventory.append(item_id)
	save_game()
	print("DialogueManager: Bought ", item_id, " for ", price, " gold")
	return true


func apply_inventory_items() -> void:
	# Called at start of each day
	# Applies all passive items in inventory
	items_used_today = []
	for item_id in inventory:
		var item = _get_item_by_id(item_id)
		if item.is_empty():
			continue
		if item.get("trigger", "passive") == "passive":
			_apply_item_effects(item)
			items_used_today.append(item_id)

	# Remove used items from inventory
	for used_id in items_used_today:
		inventory.erase(used_id)

	if items_used_today.size() > 0:
		print("DialogueManager: Applied ", items_used_today.size(), " items")
		save_game()


func _apply_item_effects(item: Dictionary) -> void:
	var effects = item.get("effects", {})
	for stat_name in effects.keys():
		if not stats.has(stat_name):
			continue
		var new_value = clamp(
			stats[stat_name] + effects[stat_name],
			STAT_MIN,
			STAT_MAX
		)
		stats[stat_name] = new_value
		emit_signal("stats_changed", stat_name, new_value)
	print("DialogueManager: Applied item ", item.get("name", ""))


func _get_item_by_id(item_id: String) -> Dictionary:
	for item in items_data:
		if item.get("id", "") == item_id:
			return item
	return {}

# =========================================
# READY
# =========================================

func _ready() -> void:
	load_items()

# =========================================
# SAVE / LOAD
# =========================================
func save_game() -> void:
	var save_data = {
		"current_day":            current_day,
		"current_branch":         current_branch,
		"current_event":          current_event,
		"stats":                  stats,
		"used_random_events":     used_random_events,
		"permanent_consequences": permanent_consequences,
		"gold":                   gold,        # ← ADD
		"inventory":              inventory,   # ← ADD
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json  = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("DialogueManager: Could not parse save file")
		return false

	var data = json.get_data()
	current_day            = data.get("current_day",            1)
	current_branch         = data.get("current_branch",         "normal")
	current_event          = data.get("current_event",          0)
	stats                  = data.get("stats",                  {
		"money":      50.0,
		"reputation": 50.0,
		"morale":     50.0,
		"stress":     50.0
	})
	gold                   = data.get("gold",                   50)
	inventory              = data.get("inventory",              [])
	used_random_events     = data.get("used_random_events",     [])
	permanent_consequences = data.get("permanent_consequences", [])

	print("DialogueManager: Game loaded — Day ", current_day)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("DialogueManager: Save deleted")

# =========================================
# PUBLIC
# =========================================
func load_dialogue(file_name: String) -> void:
	var path = "res://dialogue/" + file_name + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: Could not open file at " + path)
		return

	var json  = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("DialogueManager: JSON parse error in " + path)
		return

	dialogue_data = json.get_data()
	total_events  = dialogue_data.get("total_events", 0)
	current_event = 0

	_take_stat_snapshot()
	_load_event(current_event)

func advance(choice_index: int = -1) -> void:
	if current_node.is_empty():
		push_error("DialogueManager: No current node loaded")
		return

	var choices: Array = current_node.get("choices", [])

	if choices.size() > 0:
		if choice_index < 0 or choice_index >= choices.size():
			push_error("DialogueManager: Invalid choice_index " + str(choice_index))
			return

		var chosen: Dictionary = choices[choice_index]
		_apply_effects(chosen.get("effects", {}))
		earn_gold_from_choice(chosen)

		# ← SET FLAG IF CHOICE HAS ONE
		var flag = chosen.get("sets_flag", "")
		if flag != "":
			set_flag(flag)

		var minigame = chosen.get("minigame", null)
		if minigame != null and minigame != "null":
			print("advance: TRIGGERING MINIGAME")
			var next_id: String = chosen.get("next", "")
			emit_signal("minigame_triggered", next_id)
			return

		var next_id: String = chosen.get("next", "")
		_load_node(next_id)
	else:
		var next_id: String = current_node.get("next", "")
		_load_node(next_id)


func load_next_day() -> void:
	if current_day >= TOTAL_DAYS:
		push_error("DialogueManager: No more days")
		return
	current_day += 1
	var file_name = get_day_file(current_day)
	load_dialogue(file_name)


func get_current_node() -> Dictionary:
	return current_node


func get_current_day() -> int:
	return current_day


func get_all_stats() -> Dictionary:
	return stats.duplicate()


func get_stat_deltas() -> Dictionary:
	return _calculate_stat_deltas()

func reset() -> void:
	current_day            = 1
	current_event          = 0
	total_events           = 0
	current_node           = {}
	dialogue_data          = {}
	stat_snapshot          = {}
	current_branch         = "normal"
	used_random_events     = []
	permanent_consequences = []
	gold                   = 50
	inventory              = []
	items_used_today       = []
	stats = {
		"money":      50.0,
		"reputation": 50.0,
		"morale":     50.0,
		"stress":     50.0
	}
	delete_save()

func get_branch() -> String:
	return current_branch

# =========================================
# PRIVATE
# =========================================
func _load_event(event_index: int) -> void:
	var events: Array = dialogue_data.get("events", [])
	if event_index >= events.size():
		push_error("DialogueManager: Event index out of range")
		return

	var event: Dictionary = events[event_index]

	# Random pool check
	if event.get("start") == "random":
		var pool: Array = event.get("pool", [])
		var start_id    = _pick_random_event(pool)
		if start_id == "":
			push_error("DialogueManager: Empty random pool")
			return
		_load_node(start_id)
		return

	# ← FLAG REQUIREMENT CHECK
	var requires_flag = event.get("requires_flag", "")
	if requires_flag != "":
		if has_flag(requires_flag):
			var start_id: String = event.get("start", "")
			_load_node(start_id)
		else:
			var fallback: String = event.get("start_fallback", "")
			if fallback == "":
				push_error("DialogueManager: No fallback for flag " + requires_flag)
				return
			_load_node(fallback)
		return

	# Normal fixed event
	var start_id: String = event.get("start", "")
	if start_id == "":
		push_error("DialogueManager: No start ID in event")
		return
	_load_node(start_id)


func _pick_random_event(pool: Array) -> String:
	# Filter out already used events this run
	var available = pool.filter(func(id): 
		return not used_random_events.has(id)
	)

	# If all used reset the pool
	if available.is_empty():
		available = pool.duplicate()
		# Clear used events for this pool
		for id in pool:
			used_random_events.erase(id)

	# Pick random
	var picked = available[randi() % available.size()]
	used_random_events.append(picked)
	return picked

func get_day_file(day: int) -> String:
	match day:
		1:
			return "day1"
		2:
			match current_branch:
				"high_rep": return "day2_high_rep"
				"low_rep":  return "day2_low_rep"
				_:          return "day2_normal"
		3:
			match current_branch:
				"thriving":   return "day3_thriving"
				"struggling": return "day3_struggling"
				_:            return "day3_stable"
		4:
			match current_branch:
				"motivated": return "day4_motivated"
				"burnout":   return "day4_burnout"
				_:           return "day4_steady"
		5:
			match current_branch:
				"crisis": return "day5_crisis"
				_:        return "day5_strong"
	return "day1"

# =========================================
# CONSEQUENCE SYSTEM
# =========================================
func set_flag(flag: String) -> void:
	if not permanent_consequences.has(flag):
		permanent_consequences.append(flag)
		print("DialogueManager: Flag set → ", flag)
		save_game()


func has_flag(flag: String) -> bool:
	return permanent_consequences.has(flag)


func get_all_flags() -> Array:
	return permanent_consequences.duplicate()


func _load_node(node_id: String) -> void:
	if node_id == "" or node_id == "end":
		_on_event_end()
		return

	var nodes: Dictionary = dialogue_data.get("nodes", {})
	if not nodes.has(node_id):
		push_error("DialogueManager: Node ID not found: " + node_id)
		return

	current_node = nodes[node_id]

	var speaker: String = current_node.get("speaker", "")
	var text:    String = current_node.get("text", "")
	emit_signal("dialogue_updated", speaker, text)

	var choices: Array = current_node.get("choices", [])
	if choices.size() > 0:
		emit_signal("choices_updated", choices)


func _on_event_end() -> void:
	emit_signal("event_completed", current_event + 1, total_events)
	current_event += 1
	
	save_game()

	if current_event < total_events:
		_load_event(current_event)
	else:
		_on_day_end()


func _on_day_end() -> void:
	_award_day_complete_bonus()
	var deltas = _calculate_stat_deltas()
	current_branch = _decide_branch()
	emit_signal("day_ended", current_day, deltas)

func _decide_branch() -> String:
	match current_day:
		1:
			# Day 1 end — check reputation
			var rep = stats.get("reputation", 50.0)
			if rep >= BRANCH_THRESHOLD_HIGH:
				return "high_rep"
			elif rep < BRANCH_THRESHOLD_LOW:
				return "low_rep"
			else:
				return "normal"
		2:
			# Day 2 end — check money
			var money = stats.get("money", 50.0)
			if money >= BRANCH_THRESHOLD_HIGH:
				return "thriving"
			elif money < BRANCH_THRESHOLD_LOW:
				return "struggling"
			else:
				return "stable"
		3:
			# Day 3 end — check morale
			var morale = stats.get("morale", 50.0)
			if morale >= BRANCH_THRESHOLD_HIGH:
				return "motivated"
			elif morale < BRANCH_THRESHOLD_LOW:
				return "burnout"
			else:
				return "steady"
		4:
			# Day 4 end — check stress
			var stress = stats.get("stress", 50.0)
			if stress >= 70.0:
				return "crisis"
			else:
				return "strong"
	return "normal"


func _take_stat_snapshot() -> void:
	stat_snapshot = stats.duplicate()


func _calculate_stat_deltas() -> Dictionary:
	var deltas: Dictionary = {}
	for stat_name in stats.keys():
		deltas[stat_name] = stats[stat_name] - stat_snapshot.get(stat_name, 0.0)
	return deltas


func _apply_effects(effects: Dictionary) -> void:
	for stat_name in effects.keys():
		if not stats.has(stat_name):
			push_warning("DialogueManager: Unknown stat " + stat_name)
			continue
		var new_value = clamp(
			stats[stat_name] + effects[stat_name],
			STAT_MIN,
			STAT_MAX
		)
		stats[stat_name] = new_value
		emit_signal("stats_changed", stat_name, new_value)

func get_speaker_id() -> String:
	return current_node.get("speaker_id", "unknown")


func get_background_id() -> String:
	return current_node.get("background", "")
