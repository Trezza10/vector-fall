class_name PlaygroundPauseMenu
extends CanvasLayer

signal camera_zoom_previewed(percent: float)

signal control_mode_applied(mode: PlaygroundPlayer.ControlMode)

@onready var _overlay: Control = $Overlay
@onready var _main: VBoxContainer = $Overlay/Center/Panel/Margin/Main
@onready var _settings: VBoxContainer = $Overlay/Center/Panel/Margin/Settings
@onready var _resume: Button = $Overlay/Center/Panel/Margin/Main/Resume
@onready var _settings_button: Button = $Overlay/Center/Panel/Margin/Main/Settings
@onready var _mode: OptionButton = $Overlay/Center/Panel/Margin/Settings/Tabs/Controls/Content/Mode
@onready var _status: Label = $Overlay/Center/Panel/Margin/Settings/Status
@onready var _tabs: TabContainer = $Overlay/Center/Panel/Margin/Settings/Tabs

var _preferences: ControlPreferences

func _ready() -> void:
	_overlay.hide()
	if OS.has_feature("web") and not JavaScriptBridge.eval("typeof document.documentElement.requestFullscreen === 'function'"):
		var fullscreen_button: Button = $Overlay/Center/Panel/Margin/Settings/Tabs/Graphics/Content/Fullscreen
		fullscreen_button.disabled = true
		fullscreen_button.text = "Fullscreen unavailable"
	if OS.has_feature("web"): $Overlay/Center/Panel/Margin/Main/Quit.text = "Reload game"
	for bus: String in ["Master", "Combat", "Effects", "UI"]:
		var slider: HSlider = _sound_content().get_node(bus + "Row/Volume")
		slider.value_changed.connect(_on_volume_changed.bind(bus))
	var mute: CheckButton = _sound_content().get_node("Mute")
	mute.toggled.connect(_on_mute_toggled)
	_sound_content().get_node("Previews/Preview").pressed.connect(_on_preview_pressed)
	_sound_content().get_node("Previews/Shot").pressed.connect($PreviewShot.trigger)
	_sound_content().get_node("Previews/Effect").pressed.connect($PreviewEffect.trigger)
	_tabs.tab_changed.connect(_on_tab_changed)
	_zoom_slider().value_changed.connect(_on_zoom_changed)

func configure(preferences: ControlPreferences) -> void:
	_preferences = preferences

func _exit_tree() -> void:
	if is_inside_tree(): get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if event.is_action_pressed("pause"):
		if _overlay.visible and _settings.visible:
			_show_main()
		else:
			set_paused(not _overlay.visible)
		get_viewport().set_input_as_handled()
	elif _overlay.visible and event.is_action_pressed("ui_cancel"):
		if _settings.visible: _show_main()
		else: set_paused(false)
		get_viewport().set_input_as_handled()

func set_paused(paused: bool) -> void:
	if not paused and _preferences != null:
		_preferences.apply_audio()
		camera_zoom_previewed.emit(_preferences.camera_zoom_percent)
	get_tree().paused = paused
	if paused: $PauseSound.trigger()
	else: $ResumeSound.trigger()
	_overlay.visible = paused
	if paused: _show_main()

func _show_main() -> void:
	if _preferences != null: camera_zoom_previewed.emit(_preferences.camera_zoom_percent)
	if _preferences != null: _preferences.apply_audio()
	_settings.hide()
	_main.show()
	_resume.grab_focus()

func _on_resume_pressed() -> void:
	set_paused(false)

func _on_settings_pressed() -> void:
	if _preferences == null: return
	$ClickSound.trigger()
	_main.hide()
	_settings.show()
	_tabs.current_tab = 0
	_mode.select(int(_preferences.control_mode))
	_zoom_slider().set_value_no_signal(_preferences.camera_zoom_percent)
	_on_zoom_changed(_preferences.camera_zoom_percent)
	for bus: String in _preferences.sound_volumes:
		var slider: HSlider = _sound_content().get_node(bus + "Row/Volume")
		slider.set_value_no_signal(_preferences.sound_volumes[bus] * 100.0)
		_on_volume_changed(slider.value, bus)
	_sound_content().get_node("Mute").set_pressed_no_signal(_preferences.sound_muted)
	_preferences.apply_audio()
	_status.text = "Adjust controls, sound or zoom, then Apply & save."
	_mode.grab_focus()

func _on_apply_pressed() -> void:
	if _preferences == null: return
	var selected: PlaygroundPlayer.ControlMode = _mode.get_selected_id() as PlaygroundPlayer.ControlMode
	if _preferences.save_settings(selected, _current_volumes(), _sound_content().get_node("Mute").button_pressed, _zoom_slider().value) != OK:
		_preferences.apply_audio()
		camera_zoom_previewed.emit(_preferences.camera_zoom_percent)
		_status.text = "Could not save settings. Your previous settings are still active."
		return
	$ClickSound.trigger()
	control_mode_applied.emit(selected)
	_status.text = "Saved. Settings will be used next time you launch."

func _on_back_pressed() -> void:
	$ClickSound.trigger()
	_show_main()
	_settings_button.grab_focus()

func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = './';")
	else:
		get_tree().quit()

func _sound_content() -> VBoxContainer:
	return $Overlay/Center/Panel/Margin/Settings/Tabs/Sound/Content

func _current_volumes() -> Dictionary:
	var volumes: Dictionary = {}
	for bus: String in ["Master", "Combat", "Effects", "UI"]:
		volumes[bus] = _sound_content().get_node(bus + "Row/Volume").value / 100.0
	return volumes

func _on_volume_changed(value: float, bus: String) -> void:
	_sound_content().get_node(bus + "Row/Label").text = "%s  %d%%" % [bus, roundi(value)]
	_preview_audio_settings()

func _on_mute_toggled(_muted: bool) -> void:
	_preview_audio_settings()

func _preview_audio_settings() -> void:
	if _preferences != null:
		_preferences.apply_audio_values(_current_volumes(), _sound_content().get_node("Mute").button_pressed)

func _on_preview_pressed() -> void:
	$ClickSound.trigger()

func _on_tab_changed(_tab: int) -> void:
	if _overlay.visible: $ClickSound.trigger()

func _zoom_slider() -> HSlider:
	return $Overlay/Center/Panel/Margin/Settings/Tabs/Graphics/Content/Zoom

func _on_zoom_changed(value: float) -> void:
	$Overlay/Center/Panel/Margin/Settings/Tabs/Graphics/Content/ZoomLabel.text = "CAMERA ZOOM  %d%%" % roundi(value)
	camera_zoom_previewed.emit(value)

func apply_portrait_layout(portrait: bool) -> void:
	$Overlay/Center/Panel.custom_minimum_size = Vector2(840, 780) if portrait else Vector2(660, 560)
	_overlay.theme.default_font_size = 28 if portrait else 18
	for button: Button in [_resume, _settings_button, $Overlay/Center/Panel/Margin/Main/Quit,
		$Overlay/Center/Panel/Margin/Settings/Buttons/Apply, $Overlay/Center/Panel/Margin/Settings/Buttons/Back]:
		button.custom_minimum_size.y = 90.0 if portrait else 0.0
	_zoom_slider().custom_minimum_size.y = 90.0 if portrait else 48.0
	for bus: String in ["Master", "Combat", "Effects", "UI"]:
		_sound_content().get_node(bus + "Row/Volume").custom_minimum_size.y = 80.0 if portrait else 0.0

func _on_fullscreen_pressed() -> void:
	$ClickSound.trigger()
	var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
