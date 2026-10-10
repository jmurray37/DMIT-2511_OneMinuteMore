class_name RangedEnemy
extends Enemy

@export var speed: float = 40.0
@export var stopping_distance: float = 40.0
@export var shoot_interval: float = 2.0

@onready var shoot_timer: Timer = $ShootTimer

var projectile_scene: PackedScene = preload(
	"res://Scenes/Enemies/enemy_projectile.tscn"
)


func _ready() -> void:
	super._ready()

	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false

	if not shoot_timer.timeout.is_connected(shoot):
		shoot_timer.timeout.connect(shoot)

	shoot_timer.start()


func _physics_process(_delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
		return

	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	if distance_to_player > stopping_distance:
		var direction: Vector2 = global_position.direction_to(
			player.global_position
		)

		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func shoot() -> void:
	if player == null:
		return

	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position

	projectile.direction = global_position.direction_to(
		player.global_position
	)

	projectile.shooter = self
	projectile.z_index = 10
