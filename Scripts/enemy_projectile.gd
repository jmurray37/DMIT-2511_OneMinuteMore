extends Area2D

@export var speed: float = 100.0

var direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
