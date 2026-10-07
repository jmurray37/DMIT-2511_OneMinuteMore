extends Node2D

@export var speed: float = 40.0
@export var stopping_distance: float = 40.0

var player: Node2D = null
@onready var shoot_timer: Timer = find_child("ShootTimer", true, false) as Timer

var projectile_scene: PackedScene = preload(
	"res://Scenes/Enemies/enemy_projectile.tscn"
)

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		player = get_tree().current_scene.find_child("Player", true, false) as Node2D
		print("Player found by name: ", player)
	else:
		print("Player found in group: ", player)

	if player == null:
		print("ERROR: no player found. Add Player to the 'player' group or name the node 'Player'")

	if shoot_timer == null:
		print("ShootTimer not found, creating one in code")
		shoot_timer = Timer.new()
		shoot_timer.name = "ShootTimer"
		add_child(shoot_timer)

	shoot_timer.wait_time = 2.0
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(shoot)
	shoot_timer.start()

	print("SHOOT TIMER STARTED")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var distance_to_player := global_position.distance_to(player.global_position)

	if distance_to_player > stopping_distance:
		var direction := global_position.direction_to(player.global_position)
		global_position += direction * speed * delta

func shoot() -> void:
	print("ENEMY GUY FIRED")

	if player == null:
		print("SHOOT FAILED: player is null")
		return

	var projectile = projectile_scene.instantiate()
	projectile.direction = global_position.direction_to(player.global_position)
	projectile.shooter = self

	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.z_index = 10

	print("PROJECTILE SPAWNED at ", projectile.global_position, " direction ", projectile.direction)
