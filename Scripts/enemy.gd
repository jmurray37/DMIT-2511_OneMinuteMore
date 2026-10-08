extends CharacterBody2D

@export var max_health: int = 3

# Base rule:
# Every 1 HP is worth 2 seconds when this enemy dies.
@export var time_per_health: float = 2.0

# Lets individual enemies be worth more or less
# without breaking the health-based reward system.
@export var time_reward_multiplier: float = 1.0

# Used by the room spawner when building encounters.
@export var encounter_cost: int = 1

var current_health: int = 0
var player: Node2D = null


func _ready() -> void:
	add_to_group("enemy")

	current_health = max_health

	find_player()


func find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		player = get_tree().current_scene.find_child(
			"Player",
			true,
			false
		) as Node2D

	if player == null:
		print("ERROR: Enemy could not find Player Guy")


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	current_health -= amount

	current_health = max(
		current_health,
		0
	)

	print(
		name,
		" HP: ",
		current_health,
		"/",
		max_health
	)

	if current_health <= 0:
		die()


func get_time_reward() -> float:
	return (
		float(max_health)
		* time_per_health
		* time_reward_multiplier
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
