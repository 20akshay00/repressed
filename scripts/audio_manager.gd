extends AudioStreamPlayer

var eye_hook_sfx := load("res://assets/sfx/Rope launch eye 01.ogg")
var hook_sfx := load("res://assets/sfx/Rope launch 03.ogg")
var unhook_sfx := load("res://assets/sfx/Rope release 02.ogg")

var eye_aim_sfx := load("res://assets/sfx/Eye aim 01.ogg")
var eye_shoot_sfx := load("res://assets/sfx/Eye shoot 01.ogg")

var bg1 := load("res://assets/sfx/Brackeys 2026 Music 02.ogg")
var bg2 := load("res://assets/sfx/Brackeys 2026 Music 02 vinyl no drums.ogg")
var bg3 := load("res://assets/sfx/Brackeys 2026 Music 02 vinyl partial drums.ogg")
var bg4 := load("res://assets/sfx/Brackeys 2026 Music 01 Clean.ogg")
var bg5 := load("res://assets/sfx/Brackeys 2026 Music 01 Bad Vinyl.ogg")

var lvl_change_sfx := load("res://assets/sfx/Next Level 01.ogg")

var music_players: Array[AudioStreamPlayer] = []
var active_p_idx := 0
var fade_duration := 2.0

func _ready():
	# Initialize two players for crossfading
	for i in 2:
		var p = AudioStreamPlayer.new()
		p.bus = "Music" 
		add_child(p)
		music_players.append(p)
	
	# Start the first track on launch
	if bg1:
		switch_track(bg1)
		pass
		
func switch_track(new_stream: AudioStream, volume = -7):
	var current_p = music_players[active_p_idx]
	# Toggle index between 0 and 1
	active_p_idx = (active_p_idx + 1) % 2
	var next_p = music_players[active_p_idx]
	
	if next_p.stream == new_stream:
		return

	# Sync timing: get current position so the new track starts at the same beat
	var playback_pos = 0.0
	if current_p.playing:
		playback_pos = current_p.get_playback_position()
	
	# Prepare next player
	next_p.stream = new_stream
	next_p.volume_db = -80
	next_p.play(playback_pos)
	
	# Crossfade: Old out, New in
	var tween = create_tween().set_parallel(true)
	tween.tween_property(current_p, "volume_db", -80, fade_duration)
	tween.tween_property(next_p, "volume_db", volume, fade_duration)
	
	# Stop the old player when fade is complete to save resources
	tween.set_parallel(false)
	tween.tween_callback(current_p.stop)

func play_music_level(level_index: int):
	# Maps specific tracks to a level index if needed
	var tracks = [bg1, bg2, bg3, bg4, bg5]
	if level_index >= 0 and level_index < tracks.size():
		switch_track(tracks[level_index])

func play_effect(aud_stream: AudioStream, pitch = 1., volume = 0.0, bus="Misc"):
	var fx_player = AudioStreamPlayer.new()
	fx_player.stream = aud_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume
	fx_player.bus = bus
	fx_player.pitch_scale = pitch
	add_child(fx_player)
	fx_player.play()
	fx_player.finished.connect(fx_player.queue_free)
	return fx_player
	
func play_spatial_effect(aud_stream: AudioStream, position=Vector2.ZERO, volume = 0.0, bus="Misc"):
	var fx_player = AudioStreamPlayer2D.new()
	fx_player.global_position = position
	fx_player.stream = aud_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume
	add_child(fx_player)
	fx_player.play()
	fx_player.finished.connect(fx_player.queue_free)
	return fx_player
