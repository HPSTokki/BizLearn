extends Node

# =========================================
# SIGNALS
# =========================================
signal minigame_completed(result: Dictionary)

# =========================================
# CONSTANTS
# =========================================
const SCRIPT_MAP = {
	"resource_allocation": "res://scripts/minigames/minigame_resource.gd",
	"budget_puzzle":       "res://scripts/minigames/minigame_budget.gd",
	"card_decisions":      "res://scripts/minigames/minigame_card.gd",
}

const OUTCOME_BONUSES = {
	"great": { "money": 15, "reputation": 10, "morale": 10, "stress": -15 },
	"good":  { "money": 8,  "reputation": 5,  "morale": 5,  "stress": -8  },
	"okay":  { "money": 3,  "reputation": 2,  "morale": 2,  "stress": -3  },
	"poor":  { "money": 0,  "reputation": 0,  "morale": 0,  "stress":  5  },
}

const OUTCOME_LABELS = {
	"great": "Excellent Work!",
	"good":  "Good Job!",
	"okay":  "Decent Effort",
	"poor":  "Room to Improve",
}

const OUTCOME_COLORS = {
	"great": "#c8a84b",
	"good":  "#4a7c59",
	"okay":  "#7c5c8a",
	"poor":  "#8b3a3a",
}

# =========================================
# STATE
# =========================================
var _active_minigame_id:  String = ""
var _pending_choice_next: String = ""

# Saved mid-day state so dialogue_scene can resume
# without calling load_dialogue() again
var _resuming:       bool       = false
var _saved_dialogue: Dictionary = {}
var _saved_event:    int        = 0
var _saved_total:    int        = 0
var _saved_branch:   String     = ""

# =========================================
# PUBLIC
# =========================================
func trigger_minigame(minigame_id: String, next_node_id: String = "") -> void:
	if not SCRIPT_MAP.has(minigame_id):
		push_error("MiniGameManager: Unknown minigame id: " + minigame_id)
		return

	var script_path = SCRIPT_MAP[minigame_id]
	if not ResourceLoader.exists(script_path):
		push_error("MiniGameManager: Script not found: " + script_path)
		return

	_active_minigame_id  = minigame_id
	_pending_choice_next = next_node_id

	# Save full mid-day state BEFORE leaving dialogue_scene
	_resuming       = true
	_saved_dialogue = DialogueManager.dialogue_data.duplicate(true)
	_saved_event    = DialogueManager.current_event
	_saved_total    = DialogueManager.total_events
	_saved_branch   = DialogueManager.current_branch

	var script = load(script_path) as GDScript
	var node   = Node2D.new()
	node.set_name("MinigameRoot")
	node.set_script(script)

	var packed = PackedScene.new()
	var err    = packed.pack(node)
	node.free()

	if err != OK:
		push_error("MiniGameManager: Failed to pack scene for: " + minigame_id)
		_resuming = false
		return

	get_tree().change_scene_to_packed(packed)


func complete_minigame(score: float) -> void:
	var outcome = _score_to_outcome(score)
	var bonuses = OUTCOME_BONUSES[outcome].duplicate()

	for stat in bonuses.keys():
		var current = DialogueManager.stats.get(stat, 50.0)
		var new_val = clamp(current + bonuses[stat], 0.0, 100.0)
		DialogueManager.stats[stat] = new_val
		DialogueManager.emit_signal("stats_changed", stat, new_val)

	var result_dict = {
		"outcome":    outcome,
		"label":      OUTCOME_LABELS[outcome],
		"color":      OUTCOME_COLORS[outcome],
		"stat_bonus": bonuses,
		"score":      score,
		"next_node":  _pending_choice_next,
	}
	emit_signal("minigame_completed", result_dict)


func return_to_dialogue(next_node_id: String = "") -> void:
	# Restore dialogue state into DialogueManager
	# NOTE: do NOT clear _resuming here — dialogue_scene._start_dialogue()
	# needs to read it. It clears _resuming itself after consuming it.
	if _resuming:
		DialogueManager.dialogue_data  = _saved_dialogue
		DialogueManager.current_event  = _saved_event
		DialogueManager.total_events   = _saved_total
		DialogueManager.current_branch = _saved_branch

	# Update pending next if a non-empty value was passed
	if next_node_id != "":
		_pending_choice_next = next_node_id

	get_tree().change_scene_to_file("res://scenes/dialogue_scene.tscn")


func consume_resume() -> String:
	# Called by dialogue_scene._start_dialogue() to atomically
	# read the pending node AND clear the resume flag in one call.
	_resuming = false
	return _pending_choice_next


func is_resuming() -> bool:
	return _resuming


func get_active_id() -> String:
	return _active_minigame_id


func get_pending_next() -> String:
	return _pending_choice_next


func _score_to_outcome(score: float) -> String:
	if score >= 0.85:   return "great"
	elif score >= 0.60: return "good"
	elif score >= 0.35: return "okay"
	else:               return "poor"
