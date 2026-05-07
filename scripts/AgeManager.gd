extends Node

const CONFIG_PATH = "user://user_data.cfg"

var is_age_set: bool = false
var user_age: int = 0

func _ready() -> void:
	_load_age()

func _load_age() -> void:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		if config.has_section_key("User", "age_set"):
			is_age_set = config.get_value("User", "age_set", false)
			user_age = config.get_value("User", "age", 0)
			print("Loaded age: ", user_age)

func get_age() -> int:
	return user_age

func is_adult() -> bool:
	return user_age >= 18

func is_minor() -> bool:
	return user_age > 0 and user_age < 18

func needs_age_check() -> bool:
	return not is_age_set
