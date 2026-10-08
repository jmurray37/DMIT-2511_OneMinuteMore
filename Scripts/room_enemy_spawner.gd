extends Node2D

@export var encounter_budget: int = 5

@export var enemy_scenes: Array[PackedScene] = []

@export var room_left: float = 32.0
@export var room_top: float = 32.0
@export var room_right: float = 224.0
@export var room_bottom: float = 224.0

@export var wall_margin: float = 8.0
@export var minimum_player_distance: float = 48.0
@export var minimum_enemy_distance: float = 24.0
@export var max_spawn_attempts: int = 100

var player: Node2D = null
var used_spawn_positions: Array[Vector2] = []


func _ready() -> void:
	randomize()

	# Wait until the scene has finished creating its children.
	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	spawn_encounter()


func spawn_encounter() -> void:
	if enemy_scenes.is_empty():
		print("ERROR: EnemySpawner has no enemy scenes assigned")
		return

	var remaining_budget: int = encounter_budget

	while remaining_budget > 0:
		var affordable_scenes: Array[PackedScene] = []

		for enemy_scene: PackedScene in enemy_scenes:
			if enemy_scene == null:
				continue

			var cost: int = get_enemy_cost(enemy_scene)

			if cost <= remaining_budget:
				affordable_scenes.append(enemy_scene)

		if affordable_scenes.is_empty():
			break

		var chosen_scene: PackedScene = affordable_scenes.pick_random()
		var chosen_cost: int = get_enemy_cost(chosen_scene)

		var spawn_position: Vector2 = find_valid_spawn_position()

		if spawn_position == Vector2.INF:
			print("Could not find a valid enemy spawn position")
			break

		spawn_enemy(
			chosen_scene,
			spawn_position
		)

		used_spawn_positions.append(spawn_position)

		remaining_budget -= chosen_cost

		print(
			"Spawned enemy worth ",
			chosen_cost,
			" points. Remaining budget: ",
			remaining_budget
		)


func find_valid_spawn_position() -> Vector2:
	for attempt: int in range(max_spawn_attempts):
		var candidate_position: Vector2 = Vector2(
			randf_range(
				room_left + wall_margin,
				room_right - wall_margin
			),
			randf_range(
				room_top + wall_margin,
				room_bottom - wall_margin
			)
		)

		if not is_far_enough_from_player(candidate_position):
			continue

		if not is_far_enough_from_enemies(candidate_position):
			continue

		if is_position_blocked(candidate_position):
			continue

		return candidate_position

	return Vector2.INF


func is_far_enough_from_player(
	candidate_position: Vector2
) -> bool:

	if player == null:
		return true

	return candidate_position.distance_to(
		player.global_position
	) >= minimum_player_distance


func is_far_enough_from_enemies(
	candidate_position: Vector2
) -> bool:

	for used_position: Vector2 in used_spawn_positions:
		if candidate_position.distance_to(
			used_position
		) < minimum_enemy_distance:
			return false

	return true


func is_position_blocked(
	candidate_position: Vector2
) -> bool:

	var space_state: PhysicsDirectSpaceState2D = (
		get_world_2d().direct_space_state
	)

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 6.0

	var query: PhysicsShapeQueryParameters2D = (
		PhysicsShapeQueryParameters2D.new()
	)

	query.shape = shape

	query.transform = Transform2D(
		0.0,
		candidate_position
	)

	query.collide_with_bodies = true
	query.collide_with_areas = false

	var results: Array[Dictionary] = space_state.intersect_shape(
		query,
		1
	)

	return not results.is_empty()


func spawn_enemy(
	enemy_scene: PackedScene,
	spawn_position: Vector2
) -> void:

	var enemy_instance: Node = enemy_scene.instantiate()

	get_tree().current_scene.add_child(enemy_instance)

	if enemy_instance is Node2D:
		enemy_instance.global_position = spawn_position


func get_enemy_cost(enemy_scene: PackedScene) -> int:
	var enemy_instance: Node = enemy_scene.instantiate()

	var enemy_body: Node = find_enemy_body(enemy_instance)

	var cost: int = 1

	if enemy_body != null:
		cost = int(
			enemy_body.get("encounter_cost")
		)

	enemy_instance.free()

	return max(cost, 1)


func find_enemy_body(node: Node) -> Node:
	if node.get("encounter_cost") != null:
		return node

	for child: Node in node.get_children():
		var result: Node = find_enemy_body(child)

		if result != null:
			return result

	return null
