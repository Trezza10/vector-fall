class_name ControlPreferences
extends RefCounted

const SAVE_PATH: String = "user://settings.cfg"

var sound_volumes: Dictionary = {"Master": 0.8, "Combat": 0.8, "Effects": 0.8, "UI": 0.8}
var sound_muted: bool = false
var camera_zoom_percent: float = 50.0

var control_mode: PlaygroundPlayer.ControlMode = PlaygroundPlayer.ControlMode.DIRECTIONAL

func load_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK: return
	var zoom_value: Variant = config.get_value("graphics", "camera_zoom", 50.0)
	if (zoom_value is float or zoom_value is int) and is_finite(float(zoom_value)):
		camera_zoom_percent = clampf(float(zoom_value), 0.0, 100.0)
	for bus: String in sound_volumes:
		var volume: Variant = config.get_value("sound", bus, sound_volumes[bus])
		if (volume is float or volume is int) and is_finite(float(volume)):
			sound_volumes[bus] = clampf(float(volume), 0.0, 1.0)
	var mute: Variant = config.get_value("sound", "muted", false)
	if mute is bool: sound_muted = mute
	var stored: Variant = config.get_value("controls", "mode", 0)
	if stored is int and stored >= 0 and stored <= 1:
		control_mode = stored as PlaygroundPlayer.ControlMode

func save_mode(mode: PlaygroundPlayer.ControlMode) -> Error:
	var config: ConfigFile = ConfigFile.new()
	# Preserve other sections as settings expand beyond controls.
	config.load(SAVE_PATH)
	config.set_value("controls", "mode", int(mode))
	var result: Error = config.save(SAVE_PATH)
	if result == OK: control_mode = mode
	return result

func save_settings(mode: PlaygroundPlayer.ControlMode, volumes: Dictionary, muted: bool, zoom_percent: float = camera_zoom_percent) -> Error:
	var config: ConfigFile = ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("controls", "mode", int(mode))
	for bus: String in sound_volumes:
		var volume: float = clampf(float(volumes.get(bus, sound_volumes[bus])), 0.0, 1.0)
		config.set_value("sound", bus, volume)
	config.set_value("sound", "muted", muted)
	config.set_value("graphics", "camera_zoom", clampf(zoom_percent, 0.0, 100.0))
	var result: Error = config.save(SAVE_PATH)
	if result == OK:
		control_mode = mode
		camera_zoom_percent = config.get_value("graphics", "camera_zoom")
		for bus: String in sound_volumes:
			sound_volumes[bus] = config.get_value("sound", bus)
		sound_muted = muted
		apply_audio()
	return result

func apply_audio() -> void:
	apply_audio_values(sound_volumes, sound_muted)

func apply_audio_values(volumes: Dictionary, muted: bool) -> void:
	for bus: String in sound_volumes:
		var index: int = AudioServer.get_bus_index(bus)
		if index < 0: continue
		var volume: float = clampf(float(volumes.get(bus, sound_volumes[bus])), 0.0, 1.0)
		AudioServer.set_bus_volume_linear(index, volume)
		AudioServer.set_bus_mute(index, (bus == "Master" and muted) or volume <= 0.0)
