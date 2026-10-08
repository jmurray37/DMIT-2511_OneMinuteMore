extends Node2D

@onready var floor_tiles: TileMapLayer = $FloorTiles

const FLOOR_START_X: int = 2
const FLOOR_START_Y: int = 2
const FLOOR_WIDTH: int = 12
const FLOOR_HEIGHT: int = 12

# Tile source IDs:
# A = 0
# B = 1
# C = 2
# D = 3
# E = 4
# F = 5
# G = 6
# H = 7
# I = 8

var floor_themes: Array = [
	[3, 4, 0], # Purple / gold
	[5, 6, 7], # Dark / sparse
	[0, 1, 2]  # Ritual / damaged
]

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]


func _ready() -> void:
	randomize()
	generate_floor()


func generate_floor() -> void:
	floor_tiles.clear()

	var theme: Array = floor_themes.pick_random()

	var main_tile: int = theme[0]
	var secondary_tile: int = theme[1]
	var rare_tile: int = theme[2]

	fill_base_floor(main_tile)

	var secondary_cluster_count: int = randi_range(3, 5)

	for i in range(secondary_cluster_count):
		var start_cell: Vector2i = get_random_floor_cell()
		var cluster_size: int = randi_range(4, 10)

		grow_cluster(
			start_cell,
			secondary_tile,
			cluster_size
		)

	var rare_cluster_count: int = randi_range(1, 2)

	for i in range(rare_cluster_count):
		var start_cell: Vector2i = get_random_floor_cell()
		var cluster_size: int = randi_range(2, 5)

		grow_cluster(
			start_cell,
			rare_tile,
			cluster_size
		)


func fill_base_floor(source_id: int) -> void:
	for y in range(FLOOR_START_Y, FLOOR_START_Y + FLOOR_HEIGHT):
		for x in range(FLOOR_START_X, FLOOR_START_X + FLOOR_WIDTH):
			set_floor_tile(
				Vector2i(x, y),
				source_id
			)


func grow_cluster(
	start_cell: Vector2i,
	source_id: int,
	target_size: int
) -> void:

	var painted_cells: Array[Vector2i] = []
	var frontier: Array[Vector2i] = []

	painted_cells.append(start_cell)
	frontier.append(start_cell)

	set_floor_tile(
		start_cell,
		source_id
	)

	while painted_cells.size() < target_size and not frontier.is_empty():
		var frontier_index: int = randi_range(
			0,
			frontier.size() - 1
		)

		var current_cell: Vector2i = frontier[frontier_index]

		var shuffled_directions: Array[Vector2i] = DIRECTIONS.duplicate()
		shuffled_directions.shuffle()

		var found_new_cell: bool = false

		for direction in shuffled_directions:
			var next_cell: Vector2i = current_cell + direction

			if not is_inside_floor(next_cell):
				continue

			if painted_cells.has(next_cell):
				continue

			painted_cells.append(next_cell)
			frontier.append(next_cell)

			set_floor_tile(
				next_cell,
				source_id
			)

			found_new_cell = true
			break

		if not found_new_cell:
			frontier.remove_at(frontier_index)


func get_random_floor_cell() -> Vector2i:
	var x: int = randi_range(
		FLOOR_START_X,
		FLOOR_START_X + FLOOR_WIDTH - 1
	)

	var y: int = randi_range(
		FLOOR_START_Y,
		FLOOR_START_Y + FLOOR_HEIGHT - 1
	)

	return Vector2i(x, y)


func is_inside_floor(cell: Vector2i) -> bool:
	return (
		cell.x >= FLOOR_START_X
		and cell.x < FLOOR_START_X + FLOOR_WIDTH
		and cell.y >= FLOOR_START_Y
		and cell.y < FLOOR_START_Y + FLOOR_HEIGHT
	)


func set_floor_tile(
	cell: Vector2i,
	source_id: int
) -> void:

	floor_tiles.set_cell(
		cell,
		source_id,
		Vector2i(0, 0),
		0
	)
