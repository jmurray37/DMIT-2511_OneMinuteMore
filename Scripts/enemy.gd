extends CharacterBody2D

@export var speed: float = 40.0
@export var stopping_distance: float = 40.0

@onready var player: CharacterBody2D = get_node("../Player")
@onready var shoot_timer: Timer = $ShootTimer

var projectile_scene: PackedScene = preload(
	"res://Scenes/Enemies/enemy_projectile.tscn"
)

func _ready() -> void:
	shoot_timer.wait_time = 2.0
	shoot_timer.one_shot = false
	shoot_timer.timeout.connect(shoot)
	shoot_timer.start()

	print("SHOOT TIMER STARTED")

func _physics_process(_delta: float) -> void:
	if player == null:
		return

	var distance_to_player := global_position.distance_to(player.global_position)

	if distance_to_player > stopping_distance:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func shoot() -> void:
	print("ENEMY GUY FIRED")

	if player == null:
		return

	var projectile = projectile_scene.instantiate()

	projectile.global_position = global_position
	projectile.direction = global_position.direction_to(player.global_position)

	get_parent().add_child(projectile)
