
extends Node

@export var target_resolution: Vector2i = Vector2i(256, 256)


func _ready() -> void:
	var window: Window = get_window()

	# Render at the actual window resolution
	# rather than enlarging a low-resolution image.
	window.content_scale_mode = (
		Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	)

	# Preserve the intended aspect ratio.
	window.content_scale_aspect = (
		Window.CONTENT_SCALE_ASPECT_KEEP
	)

	# Keep the coordinate system for this scene.
	window.content_scale_size = target_resolution

	print(
		"SCENE RESOLUTION: ",
		target_resolution
	)
