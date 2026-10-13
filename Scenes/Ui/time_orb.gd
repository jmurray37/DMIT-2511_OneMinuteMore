
extends Node2D

@export var travel_duration: float = 0.6

var is_traveling: bool = false


func fly_to(target_position: Vector2) -> void:
	if is_traveling:
		return

	is_traveling = true

	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position",
		target_position,
		travel_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.tween_callback(queue_free)
