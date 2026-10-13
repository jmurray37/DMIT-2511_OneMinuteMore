
class_name RangedEnemy
extends Enemy

@export var speed: float = 40.0
@export var stopping_distance: float = 40.0
@export var shoot_interval: float = 2.0

@export var corpse_duration: float = 2.0

@onready var shoot_timer: Timer = $ShootTimer

var projectile_scene: PackedScene = preload(
	"res://Scenes/Enemies/enemy_projectile.tscn"
)

var is_dying: bool = false
var death_sprite: AnimatedSprite2D = null


func _ready() -> void:
	super._ready()

	# Find the sprite containing our death animation.
	for node in find_children("*", "AnimatedSprite2D", true, false):
		var candidate: AnimatedSprite2D = node as AnimatedSprite2D

		if candidate.sprite_frames != null:
			if candidate.sprite_frames.has_animation("Death_Ranged"):
				death_sprite = candidate
				break

	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false

	if not shoot_timer.timeout.is_connected(shoot):
		shoot_timer.timeout.connect(shoot)

	shoot_timer.start()


func _physics_process(_delta: float) -> void:
	if is_dying:
		return

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
	if is_dying:
		return

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


func take_damage(amount: int) -> void:
	if is_dying:
		return

	super.take_damage(amount)


func die() -> void:
	if is_dying:
		return

	is_dying = true

	# Stop movement and shooting.
	velocity = Vector2.ZERO
	shoot_timer.stop()

	# Disable collisions while dead.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	for node in find_children("*", "CollisionShape2D", true, false):
		node.set_deferred("disabled", true)

	for node in find_children("*", "Area2D", true, false):
		node.set_deferred("monitoring", false)
		node.set_deferred("monitorable", false)

	# Give the normal time reward and spawn the healing orb.
	give_time_reward()

	print(name, " DIED")

	# Play balloon-pop animation.
	if death_sprite != null:
		death_sprite.play("Death_Ranged")

		await death_sprite.animation_finished

		# Hold the final frame.
		death_sprite.stop()

		death_sprite.frame = (
			death_sprite.sprite_frames.get_frame_count(
				"Death_Ranged"
			) - 1
		)
	else:
		push_warning(
			"Ranged Enemy: Death_Ranged animation not found."
		)

	# Leave the remains for 2 seconds.
	await get_tree().create_timer(corpse_duration).timeout

	queue_free()
