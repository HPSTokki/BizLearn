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
signal gold_changed(new_gold: int)

# =========================================
# CONSTANTS
# =========================================
const STAT_MAX   = 100.0
const STAT_MIN   = 0.0
const TOTAL_DAYS = 5
const BRANCH_THRESHOLD_HIGH = 60.0
const BRANCH_THRESHOLD_LOW  = 40.0

const AUTO_SAVE_ON_STAT_CHANGE = true

# =========================================
# STATE
# =========================================
var current_node:  Dictionary = {}
var dialogue_data: Dictionary = {}

var current_node_id: String = ""

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
var permanent_consequences: Array = []

var random_event_map: Dictionary = {}

const SAVE_PATH = "user://savegame.cfg"

var _is_saving: bool = false

# =========================================
# ITEM / GOLD SYSTEM
# =========================================
var gold:             int   = 50
var inventory:        Array = []
var items_data:       Array = []
var items_used_today: Array = []

const GOLD_DAY_COMPLETE_BONUS = 10
const GOLD_GOOD_CHOICE        = 20
const GOLD_NEUTRAL_CHOICE     = 10
const GOLD_POOR_CHOICE        = 3

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
	emit_signal("gold_changed", gold)

func _award_day_complete_bonus() -> void:
	gold += GOLD_DAY_COMPLETE_BONUS

# =========================================
# SHOP SYSTEM
# =========================================
func buy_item(item_id: String) -> bool:
	var item = _get_item_by_id(item_id)
	if item.is_empty():
		push_error("DialogueManager: Item not found " + item_id)
		return false
	if inventory.has(item_id):
		push_warning("DialogueManager: Already own " + item_id)
		return false
	var price = item.get("price", 0)
	if gold < price:
		push_warning("DialogueManager: Not enough gold")
		return false
	gold -= price
	emit_signal("gold_changed", gold)
	inventory.append(item_id)
	save_game()
	return true


func apply_inventory_items() -> void:
	items_used_today = []
	for item_id in inventory:
		var item = _get_item_by_id(item_id)
		if item.is_empty():
			continue
		if item.get("trigger", "passive") == "passive":
			_apply_item_effects(item)
			items_used_today.append(item_id)
	for used_id in items_used_today:
		inventory.erase(used_id)
	if items_used_today.size() > 0:
		save_game()


func _apply_item_effects(item: Dictionary) -> void:
	var effects = item.get("effects", {})
	for stat_name in effects.keys():
		if not stats.has(stat_name):
			continue
		var new_value = clamp(
			stats[stat_name] + effects[stat_name],
			STAT_MIN, STAT_MAX
		)
		stats[stat_name] = new_value
		emit_signal("stats_changed", stat_name, new_value)


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
	# Prevent recursive saves
	if _is_saving:
		return
	_is_saving = true
	
	# Route through SaveManager so slot files stay in sync.
	if SaveManager.get_active_slot() >= 0:
		SaveManager.save_current_slot()
	else:
		var save_data = {
			"current_day":            current_day,
			"current_branch":         current_branch,
			"current_event":          current_event,
			"stats":                  stats,
			"used_random_events":     used_random_events,
			"random_event_map":       random_event_map,
			"permanent_consequences": permanent_consequences,
			"gold":                   gold,
			"inventory":              inventory,
		}
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(save_data))
			file.close()
	
	_is_saving = false


func load_game() -> bool:
	# Legacy — kept for compatibility.
	# Main flow now uses SaveManager.load_slot() directly.
	return SaveManager.has_any_save()


func has_save() -> bool:
	return SaveManager.has_any_save()


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

# =========================================
# PUBLIC
# =========================================
func load_dialogue(file_name: String) -> void:
	var path = "res://dialogue/" + file_name + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueManager: Could not open file at " + path)
		return
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		push_error("DialogueManager: JSON parse error in " + path)
		return
	
	dialogue_data = json.get_data()
	total_events = dialogue_data.get("total_events", 0)
	current_event = 0
	
	# CRITICAL FIX: Clear random event data when loading a new day
	# Random events are day-specific, so old ones won't exist in the new day's JSON
	used_random_events = []
	random_event_map = {}
	
	_take_stat_snapshot()
	_load_event(current_event)


# =========================================
# FIX: advance() — two bugs corrected
#
# BUG 1 (original): choice_index = -1 was rejected even for
#   no-choice nodes. A tap-to-continue after a minigame result
#   node calls advance() with no argument (defaults to -1).
#   Fix: when choices is empty, treat any index as "just advance".
#
# BUG 2 (original): MiniGameManager was called BEFORE set_flag,
#   so flags from minigame-triggering choices were never stored.
#   Fix: set_flag runs before trigger_minigame.
# =========================================
func advance(choice_index: int = -1) -> void:
	print("=== advance() called ===")
	
	if current_node.is_empty():
		push_error("DialogueManager: No current node loaded")
		return

	var choices: Array = current_node.get("choices", [])
	print("choices size: ", choices.size())

	if choices.size() == 0:
		var next_id: String = current_node.get("next", "")
		print("No choices, advancing to next: ", next_id)
		_load_node(next_id)
		return

	if choice_index < 0 or choice_index >= choices.size():
		push_error("DialogueManager: Invalid choice_index ", choice_index)
		return

	var chosen: Dictionary = choices[choice_index]
	print("Chosen option: ", chosen.get("text", ""))
	print("Next node from choice: ", chosen.get("next", "MISSING!!!"))  # <-- CRITICAL DEBUG

	# Apply stat effects
	_apply_effects(chosen.get("effects", {}))

	# Award gold
	earn_gold_from_choice(chosen)

	var flag = chosen.get("sets_flag", "")
	if flag != "":
		set_flag(flag)

	var minigame = chosen.get("minigame", null)
	if minigame != null and minigame != "null" and minigame != "":
		var next_id: String = chosen.get("next", "")
		print("Triggering minigame: ", minigame, " next: ", next_id)
		MinigameManager.trigger_minigame(minigame, next_id)
		return

	var next_id: String = chosen.get("next", "")
	print("Loading next node: ", next_id)
	_load_node(next_id)


func load_next_day() -> void:
	# current_day was already incremented by _on_day_end() when the day ended.
	# This function now just loads the dialogue file for the already-set day.
	if current_day > TOTAL_DAYS:
		push_error("DialogueManager: No more days")
		return
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
	current_node_id        = ""
	current_day            = 1
	current_event          = 0
	total_events           = 0
	current_node           = {}
	dialogue_data          = {}
	stat_snapshot          = {}
	current_branch         = "normal"
	used_random_events     = []
	random_event_map       = {}
	permanent_consequences = []
	gold                   = 50
	inventory              = []
	items_used_today       = []
	stats = {
		"money": 50.0, "reputation": 50.0,
		"morale": 50.0, "stress": 50.0
	}
	delete_save()

func get_current_node_id() -> String:
	# current_node_id is kept in sync by _load_node() — just return it directly.
	# The old reverse-lookup (dict == current_node) was unreliable because Godot
	# compares nested dictionaries by reference, so it almost always returned "".
	return current_node_id

func get_branch() -> String:
	return current_branch

# =========================================
# PRIVATE
# =========================================
func _load_event(event_index: int) -> void:
	var events: Array = dialogue_data.get("events", [])
	if event_index >= events.size():
		push_error("DialogueManager: Event index out of range. Index: ", event_index, " Size: ", events.size())
		# Try to recover - go to day end
		_on_day_end()
		return

	var event: Dictionary = events[event_index]

	if event.get("start") == "random":
		var pool: Array = event.get("pool", [])
		var start_id = _pick_random_event(pool, event_index)  # Pass event_index
		if start_id == "":
			push_error("DialogueManager: Empty random pool")
			return
		_load_node(start_id)
		return

	var requires_flag = event.get("requires_flag", "")
	if requires_flag != "":
		if has_flag(requires_flag):
			_load_node(event.get("start", ""))
		else:
			var fallback: String = event.get("start_fallback", "")
			if fallback == "":
				push_error("DialogueManager: No fallback for flag " + requires_flag)
				return
			_load_node(fallback)
		return

	var start_id: String = event.get("start", "")
	if start_id == "":
		push_error("DialogueManager: No start ID in event")
		return
	_load_node(start_id)

func load_saved_game_state(slot_data: Dictionary) -> void:
	"""Load full game state including random event map"""
	current_day = slot_data.get("current_day", 1)
	current_branch = slot_data.get("current_branch", "normal")
	current_event = slot_data.get("current_event", 0)
	stats = slot_data.get("stats", {"money": 50.0, "reputation": 50.0, "morale": 50.0, "stress": 50.0})
	gold = slot_data.get("gold", 50)
	inventory = slot_data.get("inventory", [])
	used_random_events = slot_data.get("used_random_events", [])
	permanent_consequences = slot_data.get("flags", [])
	random_event_map = slot_data.get("random_event_map", {})  # Load random event map
	current_node_id = slot_data.get("current_node_id", "")
	
	print("Loaded saved state - Day: ", current_day, " Event: ", current_event, " Node: ", current_node_id)

func _pick_random_event(pool: Array, event_index: int) -> String:
	# Check if we already picked one for this event index (from saved game)
	if random_event_map.has(event_index):
		var saved_pick = random_event_map[event_index]
		# Verify the saved pick still exists in the current day's pool
		if saved_pick != "" and pool.has(saved_pick):
			print("Using saved random pick: ", saved_pick)
			return saved_pick
		else:
			print("Saved random pick ", saved_pick, " not in current pool, picking new")
	
	var available = pool.filter(func(id):
		return not used_random_events.has(id)
	)
	if available.is_empty():
		available = pool.duplicate()
		used_random_events.clear()
	
	var picked = available[randi() % available.size()]
	used_random_events.append(picked)
	random_event_map[event_index] = picked
	print("Picked new random event: ", picked, " for event ", event_index)
	return picked


func get_day_file(day: int) -> String:
	match day:
		1: return "day1"
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
		save_game()


func has_flag(flag: String) -> bool:
	return permanent_consequences.has(flag)


func get_all_flags() -> Array:
	return permanent_consequences.duplicate()


func _load_node(node_id: String) -> void:
	print("Loading node: ", node_id)
	
	if node_id == "" or node_id == "end":
		print("Node is end - calling _on_event_end()")
		current_node_id = ""
		_on_event_end()
		return

	var nodes: Dictionary = dialogue_data.get("nodes", {})
	if not nodes.has(node_id):
		push_error("DialogueManager: Node ID not found: " + node_id)
		return
	
	current_node_id = node_id
	current_node = nodes[node_id]
	
	print("Node text: ", current_node.get("text", "").substr(0, 50))
	print("Next node: ", current_node.get("next", "MISSING"))

	var speaker: String = current_node.get("speaker", "")
	var text:    String = current_node.get("text", "")
	emit_signal("dialogue_updated", speaker, text)

	# CRITICAL FIX: Only emit choices if there are ACTUAL choices AND we're not at the end
	var choices: Array = current_node.get("choices", [])
	
	# Additional check: If this node has a "next" field, it's not a choice node
	var has_next = current_node.has("next") and current_node.get("next", "") != ""
	
	if choices.size() > 0 and not has_next:
		print("Emitting choices_updated for node: ", node_id)
		emit_signal("choices_updated", choices)
	else:
		print("Node ", node_id, " has no choices or is a result node")  # DEBUG

func load_node_direct(node_id: String) -> void:
	if node_id == "" or node_id == "end":
		_on_event_end()
		return
	
	var nodes: Dictionary = dialogue_data.get("nodes", {})
	if not nodes.has(node_id):
		push_error("DialogueManager: Node ID not found: " + node_id)
		return
	
	current_node = nodes[node_id]


func _on_event_end() -> void:
	emit_signal("event_completed", current_event + 1, total_events)
	current_event += 1

	if current_event < total_events:
		# Mid-day: safe to save (current_event points to the next valid event)
		save_game()
		_load_event(current_event)
	else:
		# Last event done — do NOT save here. _on_day_end() will save with
		# current_day and current_branch already updated to correct values.
		_on_day_end()


func _on_day_end() -> void:
	_award_day_complete_bonus()
	var deltas = _calculate_stat_deltas()
	# Decide and store branch NOW, before any save, so the slot file always
	# has the correct branch for the NEXT day — not the outgoing day's branch.
	current_branch = _decide_branch()
	# Advance the day counter here too so a quit on the analytics screen
	# reloads into day N+1, not day N.
	current_day += 1
	# Save with the updated day + branch so a quit here resumes correctly.
	save_game()
	# Signal uses the display day (pre-increment value) for the analytics screen.
	emit_signal("day_ended", current_day - 1, deltas)


func _decide_branch() -> String:
	match current_day:
		1:
			var rep = stats.get("reputation", 50.0)
			if rep >= BRANCH_THRESHOLD_HIGH:   return "high_rep"
			elif rep < BRANCH_THRESHOLD_LOW:   return "low_rep"
			else:                              return "normal"
		2:
			var money = stats.get("money", 50.0)
			if money >= BRANCH_THRESHOLD_HIGH: return "thriving"
			elif money < BRANCH_THRESHOLD_LOW: return "struggling"
			else:                              return "stable"
		3:
			var morale = stats.get("morale", 50.0)
			if morale >= BRANCH_THRESHOLD_HIGH: return "motivated"
			elif morale < BRANCH_THRESHOLD_LOW: return "burnout"
			else:                               return "steady"
		4:
			var stress = stats.get("stress", 50.0)
			if stress >= 70.0: return "crisis"
			else:              return "strong"
	return "normal"


func _take_stat_snapshot() -> void:
	stat_snapshot = stats.duplicate()


func _calculate_stat_deltas() -> Dictionary:
	var deltas: Dictionary = {}
	for stat_name in stats.keys():
		deltas[stat_name] = stats[stat_name] - stat_snapshot.get(stat_name, 0.0)
	return deltas


func _apply_effects(effects: Dictionary) -> void:
	var changed = false
	for stat_name in effects.keys():
		if not stats.has(stat_name):
			push_warning("DialogueManager: Unknown stat " + stat_name)
			continue
		var new_value = clamp(
			stats[stat_name] + effects[stat_name],
			STAT_MIN, STAT_MAX
		)
		if stats[stat_name] != new_value:
			stats[stat_name] = new_value
			changed = true
			emit_signal("stats_changed", stat_name, new_value)
	
	# Auto-save after stat changes
	if changed and AUTO_SAVE_ON_STAT_CHANGE:
		save_game()


func get_speaker_id() -> String:
	return current_node.get("speaker_id", "unknown")


func get_background_id() -> String:
	return current_node.get("background", "")
