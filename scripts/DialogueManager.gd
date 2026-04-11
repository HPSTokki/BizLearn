extends Node

# =========================================
# SIGNALS
# =========================================
signal dialogue_updated(speaker: String, text: String)
signal choices_updated(choices: Array)
signal stats_changed(stat_name: String, new_value: float)
signal minigame_triggered(minigame_id: String)
signal dialogue_ended
signal event_completed(current_event: int, total_events: int)
signal day_ended(day: int, stat_deltas: Dictionary)

# =========================================
# CONSTANTS
# =========================================
const STAT_MAX  = 100.0
const STAT_MIN  = 0.0
const TOTAL_DAYS = 5

# =========================================
# STATE
# =========================================
var current_node:    Dictionary = {}
var dialogue_data:   Dictionary = {}

var current_day:     int = 1
var current_event:   int = 0
var total_events:    int = 0

var stats: Dictionary = {
	"money":      50.0,
	"reputation": 50.0,
	"morale":     50.0,
	"stress":     50.0
}

# Snapshot of stats at start of day
# used to calculate deltas for analytics
var stat_snapshot: Dictionary = {}

# =========================================
# PUBLIC METHODS
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

	# Take stat snapshot at start of day
	_take_stat_snapshot()

	# Load first event
	_load_event(current_event)


func advance(choice_index: int = -1) -> void:
	print("DialogueManager.advance called — choice_index: ", choice_index)
	print("current_node: ", current_node)
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

		var minigame = chosen.get("minigame", null)
		if minigame != null and minigame != "null":
			emit_signal("minigame_triggered", minigame)
			return

		var next_id: String = chosen.get("next", "")
		_load_node(next_id)

	else:
		var next_id: String = current_node.get("next", "")
		_load_node(next_id)


func get_current_node() -> Dictionary:
	return current_node


func get_current_day() -> int:
	return current_day


func get_stat(stat_name: String) -> float:
	return stats.get(stat_name, 0.0)


func get_all_stats() -> Dictionary:
	return stats.duplicate()


# =========================================
# PRIVATE METHODS
# =========================================
func _load_event(event_index: int) -> void:
	var events: Array = dialogue_data.get("events", [])

	if event_index >= events.size():
		push_error("DialogueManager: Event index out of range " + str(event_index))
		return

	var event: Dictionary = events[event_index]
	var start_id: String  = event.get("start", "")

	if start_id == "":
		push_error("DialogueManager: No start ID in event " + str(event_index))
		return

	_load_node(start_id)


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
	emit_signal("event_completed", current_event, total_events)
	current_event += 1

	if current_event < total_events:
		# More events left in this day
		_load_event(current_event)
	else:
		# All events done — day is over
		_on_day_end()


func _on_day_end() -> void:
	var deltas = _calculate_stat_deltas()
	emit_signal("day_ended", current_day, deltas)


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


func load_next_day() -> void:
	if current_day >= TOTAL_DAYS:
		push_error("DialogueManager: No more days")
		return
	current_day += 1
	load_dialogue("day" + str(current_day))
