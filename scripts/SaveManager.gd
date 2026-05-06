extends Node

const SLOT_COUNT = 3
const SAVE_DIR   = "user://saves/"

const BUSINESSES = [
	{ "id": "laundromat",  "name": "The Laundromat",  "tagline": "Clean clothes, clean profits", "icon": "🫧", "difficulty": 1, "theme": "laundromat", "always_unlocked": true },
	{ "id": "coffee_shop", "name": "The Coffee Shop", "tagline": "Brew your way to success", "icon": "☕", "difficulty": 2, "theme": "coffee_shop", "always_unlocked": false, "unlock_requires": { "business_id": "laundromat", "min_grade": "B" } },
]

const GRADE_ORDER = ["D", "C", "B", "A", "S"]

var _slots:            Array = []
var _active_slot:      int   = -1
var _loaded_from_save: bool  = false

func _ready() -> void:
	_ensure_save_dir()
	_load_all_slots()

# ── Slot template ──────────────────────────────────────────
func _empty_slot(index: int) -> Dictionary:
	return {
		"slot_index": index, "occupied": false,
		"business_id": "", "business_name": "",
		"current_day": 0, "current_event": 0,"current_node_id": "", "current_branch": "normal",
		"completed": false, "grade": "", "stats": {},
		"gold": 50, "inventory": [], "used_random_events": [], "flags": [],
		"timestamp": "", "playtime_days": 0, "completed_businesses": [],
	}

# ── Slot access ────────────────────────────────────────────
func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= SLOT_COUNT: return {}
	return _slots[index]

func get_all_slots() -> Array:
	return _slots.duplicate(true)

func get_active_slot() -> int:   return _active_slot
func set_active_slot(i: int):    _active_slot = i
func has_any_save() -> bool:
	_load_all_slots()
	for s in _slots:
		if s.get("occupied", false): return true
	return false

func is_loaded_from_save() -> bool: return _loaded_from_save
func consume_loaded_flag() -> void: _loaded_from_save = false

# ── Business unlock ────────────────────────────────────────
func get_businesses_for_slot(slot_index: int) -> Array:
	var completed = get_slot(slot_index).get("completed_businesses", [])
	var result = []
	for biz in BUSINESSES:
		var e = biz.duplicate()
		e["locked"]   = false if biz.get("always_unlocked", false) else not _is_unlocked(biz, completed)
		e["best_run"] = _get_best_run(biz["id"], completed)
		result.append(e)
	return result

func _is_unlocked(biz: Dictionary, completed: Array) -> bool:
	var req = biz.get("unlock_requires", {})
	if req.is_empty(): return true
	for run in completed:
		if run.get("business_id") == req.get("business_id") and _grade_gte(run.get("grade", "D"), req.get("min_grade", "D")):
			return true
	return false

func _grade_gte(a: String, b: String) -> bool:
	return GRADE_ORDER.find(a) >= GRADE_ORDER.find(b)

func _get_best_run(bid: String, completed: Array) -> Dictionary:
	var best = {}
	for run in completed:
		if run.get("business_id") != bid: continue
		if best.is_empty() or _grade_gte(run.get("grade","D"), best.get("grade","D")): best = run
	return best

func get_business_def(bid: String) -> Dictionary:
	return _get_business_def(bid)

func get_active_business_id() -> String:
	if _active_slot < 0: return "laundromat"
	return _slots[_active_slot].get("business_id", "laundromat")

# ── New game ───────────────────────────────────────────────
func start_new_game(slot_index: int, business_id: String) -> void:
	var biz = _get_business_def(business_id)
	if biz.is_empty(): return
	var prev = _slots[slot_index].get("completed_businesses", [])
	
	# Create a COMPLETE slot dictionary
	_slots[slot_index] = {
		"slot_index": slot_index,
		"occupied": true,  # EXPLICITLY true
		"business_id": business_id,
		"business_name": biz.get("name", ""),
		"current_day": 1,
		"current_event": 0,
		"current_branch": "normal",
		"completed": false,
		"grade": "",
		"stats": {"money": 50, "reputation": 50, "morale": 50, "stress": 50},
		"gold": 50,
		"inventory": [],
		"used_random_events": [],
		"flags": [],
		"timestamp": _now(),
		"playtime_days": 0,
		"completed_businesses": prev
	}
	
	_active_slot = slot_index
	_loaded_from_save = false
	DialogueManager.reset()
	GameTheme.set_theme(biz.get("theme", "laundromat"))
	_save_slot(slot_index)
	
	print("🆕 New game created in slot ", slot_index)
	print("   Occupied: ", _slots[slot_index]["occupied"])

# ── Load slot (Continue) ───────────────────────────────────
func load_slot(slot_index: int) -> bool:
	var slot = get_slot(slot_index)
	if not slot.get("occupied", false): return false
	_active_slot = slot_index

	# Restore all DialogueManager state (day, branch, stats, flags, etc.)
	DialogueManager.load_saved_game_state(slot)

	var saved_event_index = DialogueManager.current_event
	var saved_node_id     = slot.get("current_node_id", "")

	# Reload the dialogue JSON for the saved day
	var day_file = DialogueManager.get_day_file(DialogueManager.current_day)
	var file = FileAccess.open("res://dialogue/" + day_file + ".json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			DialogueManager.dialogue_data = json.get_data()
			DialogueManager.total_events  = DialogueManager.dialogue_data.get("total_events", 0)

			# ── Guard: event index past end means day was complete when saved ──
			# This can happen if the player quit on the analytics screen.
			# In that case dialogue_scene will start the new day fresh, so we
			# just leave things as-is (current_day is already N+1 from _on_day_end).
			if saved_event_index >= DialogueManager.total_events:
				print("ℹ️ Saved event index ", saved_event_index,
					" >= total_events ", DialogueManager.total_events,
					" — day was complete, will start next day fresh.")
				# current_day is already the correct next day from save
			elif saved_node_id != "":
				# Restore the exact node the player was on
				var nodes = DialogueManager.dialogue_data.get("nodes", {})
				if nodes.has(saved_node_id):
					DialogueManager._load_node(saved_node_id)
					print("✅ Restored exact node: ", saved_node_id)
				else:
					print("⚠️ Node not found: ", saved_node_id, " — falling back to event start")
					DialogueManager._load_event(saved_event_index)
			else:
				# No node saved — start from the beginning of the saved event
				DialogueManager._load_event(saved_event_index)
		else:
			print("ERROR: Failed to parse JSON for ", day_file)
		file.close()
	else:
		print("ERROR: Could not load dialogue file: ", day_file)

	GameTheme.set_theme(_get_business_def(slot.get("business_id", "laundromat")).get("theme", "laundromat"))
	_loaded_from_save = true
	return true

func verify_save(slot_index: int) -> bool:
	var slot = get_slot(slot_index)
	if not slot.get("occupied", false): return false
	
	# Check required fields
	var required = ["current_day", "current_event", "stats", "gold", "flags"]
	for field in required:
		if not slot.has(field):
			return false
	
	# Check stats integrity
	var stats = slot.get("stats", {})
	var required_stats = ["money", "reputation", "morale", "stress"]
	for stat in required_stats:
		if not stats.has(stat):
			return false
	
	return true

# ── Save mid-game (called by DialogueManager.save_game) ───
func save_current_slot() -> void:
	if _active_slot < 0: return
	var slot = _slots[_active_slot]
	
	var current_node_id = DialogueManager.get_current_node_id()
	
	# Make a fresh copy with ALL required fields
	var updated_slot = {
		"slot_index": _active_slot,
		"occupied": true,  # EXPLICITLY set to true
		"business_id": slot.get("business_id", "laundromat"),
		"business_name": slot.get("business_name", "The Laundromat-o-Matrix"),
		"current_day": DialogueManager.current_day,
		"current_event": DialogueManager.current_event,
		"current_node_id": current_node_id,
		"current_branch": DialogueManager.current_branch,
		"completed": slot.get("completed", false),
		"grade": slot.get("grade", ""),
		"stats": DialogueManager.stats.duplicate(),
		"gold": DialogueManager.gold,
		"inventory": DialogueManager.inventory.duplicate(),
		"used_random_events": DialogueManager.used_random_events.duplicate(),
		"random_event_map": DialogueManager.random_event_map.duplicate(),
		"flags": DialogueManager.permanent_consequences.duplicate(),
		"playtime_days": DialogueManager.current_day,
		"timestamp": _now(),
		"completed_businesses": slot.get("completed_businesses", [])
	}
	
	_slots[_active_slot] = updated_slot
	_save_slot(_active_slot)
	
	# Debug: Verify the save
	print("✅ Saved slot ", _active_slot)
	print("   Occupied flag: ", updated_slot["occupied"])
	print("   Business: ", updated_slot["business_name"])
	print("   Day: ", updated_slot["current_day"])	
	
# ── Complete business ──────────────────────────────────────
func complete_business(grade: String, final_stats: Dictionary) -> void:
	if _active_slot < 0: return
	var slot = _slots[_active_slot]
	var bid  = slot.get("business_id", "")
	slot["completed"] = true
	slot["grade"]     = grade
	slot["stats"]     = final_stats.duplicate()
	slot["timestamp"] = _now()
	var completed = slot.get("completed_businesses", [])
	var found = false
	for i in range(completed.size()):
		if completed[i].get("business_id") == bid:
			if _grade_gte(grade, completed[i].get("grade","D")):
				completed[i] = { "business_id": bid, "grade": grade, "stats": final_stats.duplicate() }
			found = true; break
	if not found:
		completed.append({ "business_id": bid, "grade": grade, "stats": final_stats.duplicate() })
	slot["completed_businesses"] = completed
	_slots[_active_slot] = slot
	_save_slot(_active_slot)

func delete_slot(slot_index: int) -> void:
	_slots[slot_index] = _empty_slot(slot_index)
	var path = _slot_path(slot_index)
	if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

# ── File IO ────────────────────────────────────────────────
func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _slot_path(i: int) -> String: return SAVE_DIR + "slot_" + str(i) + ".cfg"

func _load_all_slots() -> void:
	_slots = []
	for i in range(SLOT_COUNT): _slots.append(_load_slot_from_disk(i))

func _load_slot_from_disk(index: int) -> Dictionary:
	var path = _slot_path(index)
	if not FileAccess.file_exists(path): return _empty_slot(index)
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return _empty_slot(index)
	var json = JSON.new()
	var err  = json.parse(file.get_as_text())
	file.close()
	if err != OK: return _empty_slot(index)
	var data = json.get_data()
	data["slot_index"] = index
	# Debug: Show what was loaded
	print("📂 Loaded slot ", index, " from disk:")
	print("   Raw occupied value: ", data.get("occupied", "MISSING"))
	print("   Business: ", data.get("business_name", "MISSING"))
	print("   Day: ", data.get("current_day", "MISSING"))
	
	# Ensure occupied is explicitly set
	if not data.has("occupied"):
		data["occupied"] = false
		print("   ⚠️ Missing 'occupied' flag, setting to false")
	return data

func _save_slot(index: int) -> void:
	var file = FileAccess.open(_slot_path(index), FileAccess.WRITE)
	if not file: return
	file.store_string(JSON.stringify(_slots[index]))
	file.close()

func _get_business_def(bid: String) -> Dictionary:
	for biz in BUSINESSES:
		if biz["id"] == bid: return biz
	return {}

func _now() -> String:
	var t = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [t["year"],t["month"],t["day"],t["hour"],t["minute"]]

# Add to SaveManager.gd
func debug_print_slot(slot_index: int) -> void:
	var slot = get_slot(slot_index)
	print("=== SLOT ", slot_index, " ===")
	print("Occupied: ", slot.get("occupied", false))
	if slot.get("occupied", false):
		print("Business: ", slot.get("business_name", "Unknown"))
		print("Day: ", slot.get("current_day", 0))
		print("Event: ", slot.get("current_event", 0))
		print("Gold: ", slot.get("gold", 0))
		print("Stats: ", slot.get("stats", {}))
		print("Flags: ", slot.get("flags", []))
		print("Timestamp: ", slot.get("timestamp", ""))
