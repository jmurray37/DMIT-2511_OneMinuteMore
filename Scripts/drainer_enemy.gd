extends CharacterBody2D

@export var speed: float = 30.0
@export var drain_range: float = 50.0
@export var drain_rate: float = 2.0

@onready var player: CharacterBody2D = get_node("../../Player")
@onready var game: Node2D = get_node("../..")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var drain_line: Line2D = $Line2D

func _ready() -> void:
	drain_line.visible = false

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var distance_to_player := global_position.distance_to(player.global_position)

	if distance_to_player > drain_range:
		var direction := global_position.direction_to(player.global_position)

		velocity = direction * speed
		animated_sprite.play("Walk_Time_Thief")

		drain_line.visible = false
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("Idle_Time_Thief")

		# Aim the line from the Line2D's origin (staff tip) at the player
		var target := player.global_position + Vector2(0, 2) # adjust to hit the player's body
		drain_line.visible = true
		drain_line.clear_points()
		drain_line.add_point(Vector2.ZERO)
		drain_line.add_point(drain_line.to_local(target))

		game.drain_time(drain_rate * delta)

	move_and_slide()
