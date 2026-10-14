
extends Node2D

signal encounter_cleared

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

@export var portal_spawn_position: Vector2 = Vector2(128, 25)
@export var portal_spacing: float = 64.0

const PORTAL_SCENE: PackedScene = preload(
	"res://Scenes/Rooms/Portal.tscn"
)

var player: Node2D = null
var used_spawn_positions: Array[Vector2] = []

var spawned_enemies: Array[Enemy] = []

var encounter_started: bool = false
var room_cleared: bool = false


func _ready() -> void:
	randomize()

	encounter_cleared.connect(spawn_portals)

	await get_tree().process_frame

	player = get_tree().get_first_node_in_group("player") as Node2D

	spawn_encounter()


func _process(_delta: float) -> void:
	if not encounter_started:
		return

	if room_cleared:
		return

	for enemy: Enemy in spawned_enemies:
		if not is_instance_valid(enemy):
			continue

		if enemy.is_queued_for_deletion():
			continue

		if enemy.current_health > 0:
			return

	room_cleared = true

	print("ENCOUNTER CLEARED!")

	encounter_cleared.emit()


func spawn_portals() -> void:
	var combat_room: int = get_current_combat_room()
	var room_type: String = get_current_room_type()

	# After Room 4, force a red portal.
	if combat_room == 4:
		spawn_portal_of_type(
			"hard",
			portal_spawn_position
		)

		print("ROOM 4 CLEARED: FORCED RED PORTAL!")
		return

	# After Room 9, force the boss portal.
	if combat_room == 9:
		spawn_portal_of_type(
			"boss",
			portal_spawn_position
		)

		print("ROOM 9 CLEARED: BOSS PORTAL!")
		return

	# Peaceful rooms cannot lead to other peaceful rooms.
	var allow_green: bool = room_type != "peaceful"

	var portal_types: Array[String] = roll_portal_types(
		allow_green
	)

	var positions: Array[Vector2] = [
		portal_spawn_position + Vector2(
			-portal_spacing,
			0.0
		),
		portal_spawn_position,
		portal_spawn_position + Vector2(
			portal_spacing,
			0.0
		)
	]

	for i: int in range(3):
		spawn_portal_of_type(
			portal_types[i],
			positions[i]
		)

	print("PORTALS SPAWNED: ", portal_types)


func roll_portal_types(
	allow_green: bool = true
) -> Array[String]:
	var types: Array[String] = []

	var green_selected: bool = false

	for i: int in range(3):
		var possible_types: Array[String] = [
			"normal",
			"hard"
		]

		# Only one green portal may appear.
		if allow_green and not green_selected:
			possible_types.append("peaceful")

		var selected_type: String = String(
			possible_types.pick_random()
		)

		types.append(selected_type)

		if selected_type == "peaceful":
			green_selected = true

	# Randomize which position receives each color.
	types.shuffle()

	return types


func spawn_portal_of_type(
	portal_type: String,
	spawn_position: Vector2
) -> void:
	var portal: Node2D = PORTAL_SCENE.instantiate() as Node2D

	if portal == null:
		push_error("Portal scene root must inherit Node2D.")
		return

	portal.set_meta("portal_type", portal_type)
	portal.add_to_group("room_portals")

	get_tree().current_scene.add_child(portal)

	portal.global_position = spawn_position

	var portal_sprite: AnimatedSprite2D = (
		portal.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	)

	if portal_sprite != null:
		var animation_name: String = "Purple_Portal"

		match portal_type:
			"normal":
				animation_name = "Purple_Portal"

			"hard":
				animation_name = "Red_Portal"

			"peaceful":
				animation_name = "Green_Portal"

			"boss":
				if (
					portal_sprite.sprite_frames != null
					and portal_sprite.sprite_frames.has_animation(
						"Boss_Portal"
					)
				):
					animation_name = "Boss_Portal"

		if (
			portal_sprite.sprite_frames != null
			and portal_sprite.sprite_frames.has_animation(
				animation_name
			)
		):
			portal_sprite.play(animation_name)
		else:
			push_warning(
				"Portal animation not found: "
				+ animation_name
			)
	else:
		push_warning(
			"Portal is missing its AnimatedSprite2D child."
		)

	print(
		"PORTAL SPAWNED: ",
		portal_type,
		" at ",
		spawn_position
	)


func get_current_combat_room() -> int:
	var game: Node = get_tree().current_scene

	if game == null:
		return 1

	var room_value: Variant = game.get("combat_room")

	if room_value == null:
		return 1

	return int(room_value)


func get_current_room_type() -> String:
	var game: Node = get_tree().current_scene

	if game == null:
		return "normal"

	var room_value: Variant = game.get(
		"current_room_type"
	)

	if room_value == null:
		return "normal"

	return String(room_value)


func clear_existing_portals() -> void:
	for portal: Node in get_tree().get_nodes_in_group(
		"room_portals"
	):
		if is_instance_valid(portal):
			portal.queue_free()


func spawn_encounter() -> void:
	clear_existing_portals()

	if enemy_scenes.is_empty():
		print("ERROR: EnemySpawner has no enemy scenes assigned")
		return

	used_spawn_positions.clear()
	spawned_enemies.clear()

	encounter_started = false
	room_cleared = false

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

		var chosen_scene: PackedScene = (
			affordable_scenes.pick_random()
		)

		var chosen_cost: int = get_enemy_cost(
			chosen_scene
		)

		var spawn_position: Vector2 = (
			find_valid_spawn_position()
		)

		if spawn_position == Vector2.INF:
			print(
				"Could not find a valid enemy spawn position"
			)
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

	if not spawned_enemies.is_empty():
		encounter_started = true

		print(
			"Encounter started with ",
			spawned_enemies.size(),
			" enemies"
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

		if not is_far_enough_from_player(
			candidate_position
		):
			continue

		if not is_far_enough_from_enemies(
			candidate_position
		):
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

	var results: Array[Dictionary] = (
		space_state.intersect_shape(
			query,
			1
		)
	)

	return not results.is_empty()


func spawn_enemy(
	enemy_scene: PackedScene,
	spawn_position: Vector2
) -> void:
	var enemy_instance: Node = enemy_scene.instantiate()

	get_tree().current_scene.add_child(
		enemy_instance
	)

	if enemy_instance is Node2D:
		enemy_instance.global_position = spawn_position

	var enemy_body: Node = find_enemy_body(
		enemy_instance
	)

	if enemy_body is Enemy:
		spawned_enemies.append(
			enemy_body as Enemy
		)
	else:
		push_warning(
			"Spawned enemy has no Enemy script: "
			+ enemy_scene.resource_path
		)


func get_enemy_cost(enemy_scene: PackedScene) -> int:
	var enemy_instance: Node = enemy_scene.instantiate()

	var enemy_body: Node = find_enemy_body(
		enemy_instance
	)

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
