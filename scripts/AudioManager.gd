extends Node

# =========================================
# SIMPLE AUDIO MANAGER
# =========================================

var music_player: AudioStreamPlayer = null
var sfx_players: Array = []

func _ready() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Create a pool of SFX players (for overlapping sounds)
	for i in range(5):
		var sfx = AudioStreamPlayer.new()
		sfx.bus = "SFX"
		add_child(sfx)
		sfx_players.append(sfx)

func play_music(music_name: String, fade_in: float = 0.0) -> void:
	var path = "res://assets/audio/music/" + music_name + ".mp3"
	if not ResourceLoader.exists(path):
		print("Music not found: ", path)
		return
	
	var stream = load(path) as AudioStream
	music_player.stream = stream
	
	if fade_in > 0:
		music_player.volume_db = -80
		music_player.play()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0.0, fade_in)
	else:
		music_player.play()

func play_sfx(sfx_name: String) -> void:
	var path = "res://assets/audio/sfx/" + sfx_name + ".wav"
	if not ResourceLoader.exists(path):
		# Silent fail - no sound is fine
		return
	
	var stream = load(path) as AudioStream
	
	# Find an idle SFX player
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return
	
	# If all are busy, use the first one (interrupt oldest)
	sfx_players[0].stream = stream
	sfx_players[0].play()

func stop_music(fade_out: float = 0.0) -> void:
	if fade_out > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

func set_music_volume(value: float) -> void:
	music_player.volume_db = linear_to_db(value / 100.0)

func set_sfx_volume(value: float) -> void:
	for player in sfx_players:
		player.volume_db = linear_to_db(value / 100.0)
