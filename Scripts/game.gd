extends Node2D

var time_left: float = 60.0
var is_dead: bool = false

const MAX_TIME: float = 60.0
const HOURGLASS_FRAMES: int = 13

@onready var timer_label: Label = $CanvasLayer/Label
@onready var hourglass: AnimatedSprite2D = $CanvasLayer/Hourglass


func _process(delta: float) -> void:
	if is_dead:
		return

	time_left -= delta

	if time_left <= 0.0:
		time_left = 0.0
		is_dead = true
		print("YOU DIED")

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func update_hourglass() -> void:
	# The completely empty hourglass is only shown at 0 seconds.
	if time_left <= 0.0:
		hourglass.frame = 12
		return

	# Frames 0-11 represent the player's remaining time while alive.
	var progress := 1.0 - (time_left / MAX_TIME)

	var frame_index := int(progress * 12.0)
	frame_index = clamp(frame_index, 0, 11)

	hourglass.frame = frame_index
