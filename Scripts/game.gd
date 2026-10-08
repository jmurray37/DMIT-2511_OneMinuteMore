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
		die()

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func _unhandled_input(event: InputEvent) -> void:
	if not is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				restart_game()


func update_hourglass() -> void:
	if time_left <= 0.0:
		hourglass.frame = 12
		return

	var progress := 1.0 - (time_left / MAX_TIME)
	var frame_index := int(progress * 12.0)

	frame_index = clamp(frame_index, 0, 11)
	hourglass.frame = frame_index


func add_time(amount: float) -> void:
	if is_dead:
		return

	time_left = min(time_left + amount, MAX_TIME)

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func drain_time(amount: float) -> void:
	if is_dead:
		return

	time_left -= amount
	time_left = max(time_left, 0.0)

	if time_left <= 0.0:
		die()
		return

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func die() -> void:
	if is_dead:
		return

	time_left = 0.0
	is_dead = true

	timer_label.text = "0.0"
	update_hourglass()

	print("YOU DIED")
	print("PRESS R TO RESTART")


func restart_game() -> void:
	get_tree().reload_current_scene()
