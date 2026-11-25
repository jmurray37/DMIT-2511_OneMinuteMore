class_name SettingsMenu
extends Node

@export var master_volume: HSlider
@export var music_volume: HSlider
@export var sfx_volume: HSlider

@export var screen_mode: OptionButton
@export var back_button: Button

@export var dia_spd_slow: CheckBox
@export var dia_spd_nrml: CheckBox
@export var dia_spd_fast: CheckBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_mode.item_selected.connect(_on_select_screen_mode)
	master_volume.value_changed.connect(_on_master_volume_value_changed)
	music_volume.value_changed.connect(_on_music_volume_value_changed)
	sfx_volume.value_changed.connect(_on_sfx_volume_value_changed)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_select_screen_mode(index: int) -> void: #Sets the Window mode to the selected type
	match index:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) #True Fullscreen
			print("Window is: ", DisplayServer.window_get_mode())
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) #Windowed
			print("Window is: ", DisplayServer.window_get_mode())
			get_window().move_to_center()
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN) #Borderless Windowed
			print("Window is: ", DisplayServer.window_get_mode())
			
func _on_master_volume_value_changed(value: float) -> void: #TODO hook up audio to buses, and test functions
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	print("Audio Bus Master:", str(AudioServer.get_bus_index("Master")))

func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	print("Audio Bus Music:", str(AudioServer.get_bus_index("Music")))

func _on_sfx_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	print("Audio Bus SFX:", str(AudioServer.get_bus_index("SFX")))

func on_dialogue_speed_selected(): #TODO Control for Dialogue speed goes here
	var default_wpm = 35.0
	var slow_wpm = 20.0
	var normal_wpm = 35.0
	var fast_wpm = 60.0
	pass
