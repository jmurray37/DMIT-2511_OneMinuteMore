extends "res://Scripts/Enemy_Scripts/enemy.gd"

@export var speed: float = 30.0
@export var drain_range: float = 50.0
@export var drain_rate: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var drain_line: Line2D = $Line2D


func _ready() -> void:
	super._ready()

	drain_line.visible = false


func _physics_process(delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
		drain_line.visible = false
		return

	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	if distance_to_player > drain_range:
		var direction: Vector2 = global_position.direction_to(
			player.global_position
		)

		velocity = direction * speed

		animated_sprite.play("Walk_Time_Thief")

		drain_line.visible = false

	else:
		velocity = Vector2.ZERO

		animated_sprite.play("Idle_Time_Thief")

		var target: Vector2 = (
			player.global_position
			+ Vector2(0, 2)
		)

		drain_line.visible = true
		drain_line.clear_points()

		drain_line.add_point(Vector2.ZERO)
		drain_line.add_point(
			drain_line.to_local(target)
		)

		var game: Node = get_tree().current_scene

		if game.has_method("drain_time"):
			game.drain_time(
				drain_rate * delta
			)

	move_and_slide()
