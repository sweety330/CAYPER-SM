#!/usr/bin/env gdscript
# AudioManager - Handles all game audio

extends Node

# Audio buses
var master_bus: String = "Master"
var music_bus: String = "Music"
var sfx_bus: String = "SFX"
var ambient_bus: String = "Ambient"

# Volume levels (0.0-1.0)
var master_volume: float = 0.8
var music_volume: float = 0.6
var sfx_volume: float = 0.8
var ambient_volume: float = 0.7

# Music
var current_music: AudioStreamPlayer = null
var music_fade_duration: float = 1.0
var music_tween: Tween = null

# Ambient sounds
var ambient_player: AudioStreamPlayer = null
var ambient_fade_duration: float = 2.0

# SFX sources
const SFX_SOURCES = {
	"ui_click": "res://assets/audio/sfx_click.wav",
	"ui_hover": "res://assets/audio/sfx_hover.wav",
	"footstep": "res://assets/audio/sfx_footstep.wav",
	"computer_typing": "res://assets/audio/sfx_typing.wav",
	"computer_on": "res://assets/audio/sfx_computer_on.wav",
	"shop_bell": "res://assets/audio/sfx_shop_bell.wav",
	"money": "res://assets/audio/sfx_money.wav",
	"door": "res://assets/audio/sfx_door.wav",
	"cash_register": "res://assets/audio/sfx_cash.wav",
	"error": "res://assets/audio/sfx_error.wav",
}

func _ready():
	# Setup audio buses
	_setup_buses()
	print("AudioManager initialized")
	print("Available audio buses: " + str(AudioServer.get_bus_count()))

func _setup_buses():
	# Ensure buses exist
	if not _bus_exists("Master"):
		AudioServer.add_bus()
		AudioServer.set_bus_name(0, "Master")

	if not _bus_exists("Music"):
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")

	if not _bus_exists("SFX"):
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

	if not _bus_exists("Ambient"):
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Ambient")
		AudioServer.set_bus_send(idx, "Master")

func _bus_exists(name: String) -> bool:
	for i in range(AudioServer.get_bus_count()):
		if AudioServer.get_bus_name(i) == name:
			return true
	return false

# Music management
func play_music(path: String, fade_in: bool = true):
	if current_music:
		stop_music()

	current_music = AudioStreamPlayer.new()
	current_music.stream = load(path)
	current_music.bus = "Music"

	if current_music.stream:
		add_child(current_music)
		current_music.play()
		_set_bus_volume("Music", music_volume)
		print("Playing music: " + path)
	else:
		print("Failed to load music: " + path)

func stop_music(fade_out: bool = true):
	if current_music:
		if fade_out:
			_fade_out_and_free(current_music)
		else:
			current_music.stop()
			current_music.queue_free()
		current_music = null

func _fade_out_and_free(player: AudioStreamPlayer):
	if music_tween:
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_method(
		func(value): player.volume_db = value,
		player.volume_db,
		-80.0,
		music_fade_duration
	)
	music_tween.tween_callback(player.queue_free)

# Ambient sounds
func play_ambient(path: String):
	if ambient_player:
		ambient_player.stop()
		ambient_player.queue_free()

	ambient_player = AudioStreamPlayer.new()
	var ambient_stream := load(path) as AudioStreamWAV
	if ambient_stream:
		ambient_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ambient_stream.loop_end = int(ambient_stream.mix_rate * 8.0)
	ambient_player.stream = ambient_stream
	ambient_player.bus = "Ambient"
	ambient_player.autoplay = true

	if ambient_player.stream:
		add_child(ambient_player)
		ambient_player.play()
		_set_bus_volume("Ambient", ambient_volume)
		print("Playing ambient: " + path)
	else:
		print("Failed to load ambient: " + path)

func stop_ambient():
	if ambient_player:
		ambient_player.stop()
		ambient_player.queue_free()
		ambient_player = null

# SFX
func play_sfx(sfx_name: String):
	if not SFX_SOURCES.has(sfx_name):
		print("SFX not found: " + sfx_name)
		return

	var path = SFX_SOURCES[sfx_name]
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.bus = "SFX"

	if player.stream:
		add_child(player)
		player.play()
		_set_bus_volume("SFX", sfx_volume)
		# Auto-cleanup when finished
		player.finished.connect(func(): player.queue_free())
	else:
		print("Failed to load SFX: " + path)
		player.queue_free()

func play_sfx_at(sfx_name: String, position: Vector3):
	if not SFX_SOURCES.has(sfx_name):
		return

	var path = SFX_SOURCES[sfx_name]
	var player = AudioStreamPlayer3D.new()
	player.stream = load(path)
	player.bus = "SFX"
	player.global_position = position

	if player.stream:
		add_child(player)
		player.play()
		_set_bus_volume("SFX", sfx_volume)
		player.finished.connect(func(): player.queue_free())
	else:
		player.queue_free()

# Volume control
func set_volume(bus_name: String, volume: float):
	match bus_name:
		"master":
			master_volume = clamp(volume, 0.0, 1.0)
			_set_bus_volume("Master", master_volume)
		"music":
			music_volume = clamp(volume, 0.0, 1.0)
			_set_bus_volume("Music", music_volume)
		"sfx":
			sfx_volume = clamp(volume, 0.0, 1.0)
			_set_bus_volume("SFX", sfx_volume)
		"ambient":
			ambient_volume = clamp(volume, 0.0, 1.0)
			_set_bus_volume("Ambient", ambient_volume)

func _set_bus_volume(bus_name: String, volume: float):
	var idx = AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume))
		AudioServer.set_bus_mute(idx, volume < 0.01)

func get_volume(bus_name: String) -> float:
	match bus_name:
		"master": return master_volume
		"music": return music_volume
		"sfx": return sfx_volume
		"ambient": return ambient_volume
	return 1.0

# Audio settings persistence
func save_audio_settings() -> Dictionary:
	return {
		"master": master_volume,
		"music": music_volume,
		"sfx": sfx_volume,
		"ambient": ambient_volume
	}

func load_audio_settings(settings: Dictionary):
	if settings.has("master"): set_volume("master", settings.master)
	if settings.has("music"): set_volume("music", settings.music)
	if settings.has("sfx"): set_volume("sfx", settings.sfx)
	if settings.has("ambient"): set_volume("ambient", settings.ambient)
