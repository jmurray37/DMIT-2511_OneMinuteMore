class_name DrainerEnemy
extends Enemy

@export var speed: float = 30.0
@export var drain_range: float = 50.0
@export var drain_rate: float = 2.0

@export var flee_range: float = 30.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var drain_line: Line2D = $Line2D
var time_drained: float = 0

func _ready() -> void:
	super._ready()
	drain_line.visible = false


func _physics_process(delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
		drain_line.visible = false
		return

	var distance_to_player: float = global_position.distance_to(
		player.global_position)

	if distance_to_player < flee_range:
		var direction: Vector2 = global_position.direction_to(
			player.global_position) * -1

		velocity = direction * speed
		animated_sprite.play("Walk_Time_Thief")
		drain_line.visible = false

	else:
		velocity = Vector2.ZERO
		animated_sprite.play("Idle_Time_Thief")
		
		

		var target: Vector2 = (
			player.global_position + Vector2(0, 2)
			)

		drain_line.visible = true
		drain_line.clear_points()
		drain_line.add_point(Vector2.ZERO)
		drain_line.add_point(drain_line.to_local(target))
		time_drained += (drain_rate * delta)

		var game: Node = get_tree().current_scene

		if game.has_method("drain_time"):
			game.drain_time(drain_rate * delta)
		
		

	move_and_slide()
	
func get_time_reward() -> float:
	return (
		float((max_health)
		* (time_per_health
		* time_reward_multiplier))
		+ (time_drained / 2)
		) 


func give_time_reward() -> void:
	var game: Node = get_tree().current_scene

	if not game.has_method("add_time"):
		print("ERROR: Game scene does not have add_time()")
		return

	var reward: float = get_time_reward()

	game.add_time(reward)

	print(
		name,
		" returned ",
		reward,
		" seconds"
	)


func die() -> void:
	give_time_reward()

	print(name, " DIED")

	queue_free()
