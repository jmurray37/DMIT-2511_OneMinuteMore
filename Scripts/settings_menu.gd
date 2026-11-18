class_name SettingsMenu
extends Node



@export var screen_mode: OptionButton

@export var back_button: Button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_mode.item_selected.connect(_on_select_screen_mode)
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
