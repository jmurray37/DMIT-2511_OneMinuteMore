
class_name Player
extends CharacterBody2D

@export var speed: float = 250.0
@export var melee_damage: int = 1
@export var melee_range: float = 10.0
@export var melee_cooldown: float = 0.35
@export var projectile_time_cost: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var melee_hitbox: Area2D = $MeleeHitbox

var aim_direction: Vector2 = Vector2.DOWN
var can_melee: bool = true
var is_dying: bool = false
var is_flipping: bool = false

var projectile_scene: PackedScene = preload(
	"res://Scenes/Player/player_projectile.tscn"
)


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	if is_dying or is_flipping:
		velocity = Vector2.ZERO
		return

	update_aim()
	update_melee_hitbox()

	var move_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = move_direction * speed

	update_animation(move_direction)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if is_dying or is_flipping:
		return

	# R activates the Hourglass Reset.
	# Once activated, the flip cannot be cancelled.
	if event is InputEventKey:
		if (
			event.pressed
			and not event.echo
			and event.keycode == KEY_R
		):
			var game: Node = get_tree().current_scene

			if (
				game != null
				and game.has_method(
					"try_start_hourglass_reset"
				)
			):
				game.call(
					"try_start_hourglass_reset"
				)

		return

	if event is InputEventMouseButton:
		if not event.pressed:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			melee_attack()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			shoot()


func begin_hourglass_flip() -> void:
	if is_dying or is_flipping:
		return

	is_flipping = true
	velocity = Vector2.ZERO

	# Hold the player on the first idle frame.
	# A dedicated flip animation can replace this later.
	animated_sprite.animation = get_aim_animation()
	animated_sprite.frame = 0
	animated_sprite.pause()

	print("PLAYER STARTED HOURGLASS RESET")


func end_hourglass_flip() -> void:
	if not is_flipping:
		return

	is_flipping = false

	print("PLAYER FINISHED HOURGLASS RESET")


func update_aim() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()

	var direction_to_mouse: Vector2 = global_position.direction_to(
		mouse_position
	)

	if direction_to_mouse != Vector2.ZERO:
		aim_direction = direction_to_mouse


func update_melee_hitbox() -> void:
	melee_hitbox.position = aim_direction * melee_range
	melee_hitbox.rotation = aim_direction.angle()


func melee_attack() -> void:
	if is_dying or is_flipping or not can_melee:
		return

	can_melee = false

	var bodies: Array[Node2D] = melee_hitbox.get_overlapping_bodies()

	for body: Node2D in bodies:
		if (
			body.is_in_group("enemy")
			and body.has_method("take_damage")
		):
			body.take_damage(melee_damage)

	await get_tree().create_timer(
		melee_cooldown
	).timeout

	if is_dying:
		return

	can_melee = true


func shoot() -> void:
	if is_dying or is_flipping:
		return

	var game: Node = get_tree().current_scene

	if game == null:
		return

	if game.has_method("drain_time"):
		game.drain_time(projectile_time_cost)

	if is_dying or is_flipping:
		return

	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = (
		global_position + aim_direction * 8.0
	)

	projectile.direction = aim_direction

	projectile.rotation = (
		aim_direction.angle()
		- deg_to_rad(90.0)
	)


func update_animation(move_direction: Vector2) -> void:
	if is_dying or is_flipping:
		return

	var animation_name: StringName = get_aim_animation()

	if move_direction == Vector2.ZERO:
		animated_sprite.animation = animation_name
		animated_sprite.frame = 0
		animated_sprite.pause()
	else:
		animated_sprite.play(animation_name)


func get_aim_animation() -> StringName:
	if abs(aim_direction.x) > abs(aim_direction.y):
		if aim_direction.x > 0:
			return &"walk_right"
		else:
			return &"walk_left"
	else:
		if aim_direction.y > 0:
			return &"walk_down"
		else:
			return &"walk_up"


func begin_death() -> void:
	if is_dying:
		return

	is_dying = true
	is_flipping = false

	velocity = Vector2.ZERO
	can_melee = false

	# Keep the player running while the rest
	# of the game pauses.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Freeze enemies, projectiles, and normal gameplay.
	get_tree().paused = true

	# Play the sand transformation and collapse.
	animated_sprite.play("Player_Death")

	await animated_sprite.animation_finished

	if not is_instance_valid(self):
		return

	# Hold the final death frame.
	animated_sprite.pause()
