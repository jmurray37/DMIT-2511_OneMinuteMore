class_name MainMenu
extends Control
@onready var settings_menu: Control = $SettingsMenu

@export var play_button: Button
@export var settings_button: Button
@export var quit_button: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	settings_menu.back_button.pressed.connect(_on_settings_back_pressed)
	quit_button.pressed.connect(_on_exit_pressed)
	#if settings_menu.back_button.pressed.is_connected(_on_settings_back_pressed):
	#	print("TEST")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_settings_pressed():
	print("Settings Pressed");
	settings_menu.visible = true

func _on_settings_back_pressed():
	print("Settings back pressed");
	settings_menu.visible = false

func _on_exit_pressed():
	get_tree().quit()
