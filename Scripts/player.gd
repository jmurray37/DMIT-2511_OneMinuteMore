extends CharacterBody2D

@export var speed: float = 250.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed

	update_animation(direction)
	move_and_slide()


func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animated_sprite.stop()
		return

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			animated_sprite.play("walk_right")
		else:
			animated_sprite.play("walk_left")
	else:
		if direction.y > 0:
			animated_sprite.play("walk_down")
		else:
			animated_sprite.play("walk_up")
