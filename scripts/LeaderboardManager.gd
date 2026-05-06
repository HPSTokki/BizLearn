extends Node

# =========================================
# PSEUDO LEADERBOARD MANAGER
# Generates fake leaderboard entries mixed with real player data
# =========================================

signal leaderboard_updated

# Leaderboard entry structure
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

# Generated fake player names pool
const FAKE_NAMES = [
	"BizWizard", "CoinMaster", "ProfitGuru", "CashFlow", "MarketKing",
	"VentureViking", "StartupStar", "TradeTitan", "WealthWarden", "CapitalCrafter",
	"BizNinja", "ProfitPanda", "CoinCollector", "MarketMage", "VentureVirtuoso",
	"BizBaron", "CashCzar", "TradeTycoon", "WealthWizard", "StartupSensei",
	"BizBrigade", "ProfitPhoenix", "CoinCaptain", "MarketMaestro", "VentureValiant"
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

var _current_leaderboard: Array = []
var _player_real_entries: Array = []

func _ready() -> void:
	_load_player_entries()

func _load_player_entries() -> void:
	"""Load all completed business runs from save slots"""
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
			entry.score = _grade_to_score(entry.grade)
			entry.day = slot.get("current_day", 5)
			entry.is_real = true
			entry.timestamp = slot.get("timestamp", "")
			_player_real_entries.append(entry)

func _grade_to_score(grade: String) -> float:
	return GRADE_SCORES.get(grade, 50)

func _generate_fake_entry(index: int, business_id: String = "") -> LeaderboardEntry:
	"""Generate a single fake leaderboard entry"""
	var entry = LeaderboardEntry.new()
	
	# Generate random name
	var name = FAKE_NAMES[index % FAKE_NAMES.size()]
	if randf() > 0.6:
		name += " " + FAKE_SURNAMES[index % FAKE_SURNAMES.size()]
	
	entry.player_name = name
	entry.business_id = business_id if business_id != "" else _random_business()
	entry.business_name = BUSINESS_NAMES.get(entry.business_id, "Business")
	
	# Generate weighted grade (more B and C grades for realism)
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
	
	entry.score = _grade_to_score(entry.grade) + randf_range(-5, 5)
	entry.score = clamp(entry.score, 0, 100)
	entry.day = 5
	entry.is_real = false
	entry.timestamp = _random_timestamp()
	
	return entry

func _random_business() -> String:
	var businesses = ["coffee_shop", "laundromat", "flower_shop", "tech_startup"]
	var weights = [0.35, 0.35, 0.15, 0.15]  # Coffee shop and laundromat most common
	var roll = randf()
	var cumulative = 0.0
	for i in range(businesses.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return businesses[i]
	return "coffee_shop"

func _random_timestamp() -> String:
	var days_ago = randi() % 30
	var hours_ago = randi() % 24
	return "%d days ago" % days_ago if days_ago > 0 else "%d hours ago" % hours_ago

func get_leaderboard(business_filter: String = "") -> Array:
	"""Get combined leaderboard with player entries + fake entries"""
	var all_entries = []
	
	# Always include player's best runs if any exist
	if _player_real_entries.is_empty():
		# If no real runs, generate 1-3 "guest" entries
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
		# Add player's best run per business
		var best_per_business = {}
		for entry in _player_real_entries:
			if not best_per_business.has(entry.business_id) or entry.score > best_per_business[entry.business_id].score:
				best_per_business[entry.business_id] = entry
		
		for entry in best_per_business.values():
			all_entries.append(entry)
	
	# Add fake entries to reach 15-20 total entries
	var target_count = 18
	var fake_needed = target_count - all_entries.size()
	
	for i in range(fake_needed):
		# If filtering by business, generate same business
		var biz = business_filter if business_filter != "" else ""
		all_entries.append(_generate_fake_entry(i, biz))
	
	# Sort by score (descending), then by timestamp for ties
	all_entries.sort_custom(func(a, b): 
		if abs(a.score - b.score) < 0.1:
			return a.timestamp < b.timestamp  # More recent first
		return a.score > b.score
	)
	
	# Assign ranks
	for i in range(all_entries.size()):
		all_entries[i].rank = i + 1
	
	# Filter by business if needed
	if business_filter != "":
		all_entries = all_entries.filter(func(e): return e.business_id == business_filter)
	
	return all_entries

func get_player_best_rank(business_id: String = "") -> int:
	"""Get player's best rank for a specific business"""
	var leaderboard = get_leaderboard(business_id)
	var player_entries = leaderboard.filter(func(e): return e.is_real)
	if player_entries.is_empty():
		return -1
	return player_entries[0].rank if player_entries[0].rank <= 10 else -1

func get_player_best_grade(business_id: String = "") -> String:
	"""Get player's best grade for a specific business"""
	var player_best = null
	for entry in _player_real_entries:
		if business_id == "" or entry.business_id == business_id:
			if player_best == null or _grade_value(entry.grade) > _grade_value(player_best.grade):
				player_best = entry
	return player_best.grade if player_best else "—"

func _grade_value(grade: String) -> int:
	return ["D", "C", "B", "A", "S"].find(grade)
