extends Node

# =========================================
# PSEUDO LEADERBOARD MANAGER - Simplified
# Generates fake leaderboard entries mixed with real player data
# =========================================

signal leaderboard_updated

class LeaderboardEntry:
	var rank: int
	var player_name: String
	var business_id: String
	var business_name: String
	var grade: String
	var score: float
	var day: int
	var is_real: bool
	var timestamp: String

const FAKE_NAMES = [
	"BizWizard", "CoinMaster", "ProfitGuru", "CashFlow", "MarketKing",
	"VentureViking", "StartupStar", "TradeTitan", "WealthWarden", "CapitalCrafter",
	"BizNinja", "ProfitPanda", "CoinCollector", "MarketMage", "VentureVirtuoso"
]

const FAKE_SURNAMES = [
	"Enterprises", "Corp", "Industries", "Holdings", "Group",
	"Ventures", "Capital", "Partners", "Associates", "Global"
]

const BUSINESS_ICONS = {
	"coffee_shop": "☕",
	"laundromat": "🫧",
	"flower_shop": "🌸",
	"tech_startup": "💻"
}

const BUSINESS_NAMES = {
	"coffee_shop": "Coffee Shop",
	"laundromat": "Laundromat",
	"flower_shop": "Flower Shop",
	"tech_startup": "Tech Startup"
}

const GRADES = ["S", "A", "B", "C", "D"]
const GRADE_SCORES = {
	"S": 95,
	"A": 75,
	"B": 58,
	"C": 42,
	"D": 25
}

var _player_real_entries: Array = []

func _ready() -> void:
	_load_player_entries()

func _load_player_entries() -> void:
	_player_real_entries.clear()
	
	for slot_index in range(SaveManager.SLOT_COUNT):
		var slot = SaveManager.get_slot(slot_index)
		if slot.get("completed", false):
			var entry = LeaderboardEntry.new()
			entry.rank = 0
			entry.player_name = "YOU"
			entry.business_id = slot.get("business_id", "laundromat")
			entry.business_name = BUSINESS_NAMES.get(entry.business_id, "Business")
			entry.grade = slot.get("grade", "D")
			entry.score = GRADE_SCORES.get(entry.grade, 50)
			entry.day = slot.get("current_day", 5)
			entry.is_real = true
			entry.timestamp = slot.get("timestamp", "")
			_player_real_entries.append(entry)

func _generate_fake_entry(index: int, business_id: String = "") -> LeaderboardEntry:
	var entry = LeaderboardEntry.new()
	
	var name = FAKE_NAMES[index % FAKE_NAMES.size()]
	if randf() > 0.6:
		name += " " + FAKE_SURNAMES[index % FAKE_SURNAMES.size()]
	
	entry.player_name = name
	entry.business_id = business_id if business_id != "" else "laundromat"
	entry.business_name = BUSINESS_NAMES.get(entry.business_id, "Laundromat")
	
	var grade_roll = randf()
	if grade_roll < 0.05:
		entry.grade = "S"
	elif grade_roll < 0.20:
		entry.grade = "A"
	elif grade_roll < 0.45:
		entry.grade = "B"
	elif grade_roll < 0.70:
		entry.grade = "C"
	else:
		entry.grade = "D"
	
	entry.score = GRADE_SCORES.get(entry.grade, 50) + randf_range(-5, 5)
	entry.score = clamp(entry.score, 0, 100)
	entry.day = 5
	entry.is_real = false
	entry.timestamp = _random_timestamp()
	
	return entry

func _random_timestamp() -> String:
	var days_ago = randi() % 30
	return str(days_ago) + " days ago" if days_ago > 0 else "Just now"

func get_leaderboard(business_filter: String = "") -> Array:
	var all_entries = []
	
	if _player_real_entries.is_empty():
		var guest_entry = LeaderboardEntry.new()
		guest_entry.player_name = "GUEST"
		guest_entry.business_id = "laundromat"
		guest_entry.business_name = "Laundromat"
		guest_entry.grade = "C"
		guest_entry.score = 45
		guest_entry.day = 3
		guest_entry.is_real = false
		guest_entry.timestamp = "Just now"
		all_entries.append(guest_entry)
	else:
		var best_per_business = {}
		for entry in _player_real_entries:
			if not best_per_business.has(entry.business_id) or entry.score > best_per_business[entry.business_id].score:
				best_per_business[entry.business_id] = entry
		
		for entry in best_per_business.values():
			all_entries.append(entry)
	
	var target_count = 6
	var fake_needed = target_count - all_entries.size()
	
	for i in range(fake_needed):
		var biz = business_filter if business_filter != "" else "laundromat"
		all_entries.append(_generate_fake_entry(i, biz))
	
	all_entries.sort_custom(func(a, b): 
		if abs(a.score - b.score) < 0.1:
			return a.timestamp < b.timestamp
		return a.score > b.score
	)
	
	for i in range(all_entries.size()):
		all_entries[i].rank = i + 1
	
	if business_filter != "":
		all_entries = all_entries.filter(func(e): return e.business_id == business_filter)
	
	return all_entries

func get_player_best_grade(business_id: String = "") -> String:
	var player_best = null
	for entry in _player_real_entries:
		if business_id == "" or entry.business_id == business_id:
			if player_best == null or _grade_value(entry.grade) > _grade_value(player_best.grade):
				player_best = entry
	return player_best.grade if player_best else "—"

func _grade_value(grade: String) -> int:
	return ["D", "C", "B", "A", "S"].find(grade)
