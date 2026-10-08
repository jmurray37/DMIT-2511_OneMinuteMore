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

var projectile_scene: PackedScene = preload(
	"res://Scenes/Player/player_projectile.tscn"
)


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
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
	if event is InputEventMouseButton:
		if not event.pressed:
			return

		if event.button_index == MOUSE_BUTTON_LEFT:
			melee_attack()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			shoot()


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
	if not can_melee:
		return

	can_melee = false

	var bodies: Array[Node2D] = melee_hitbox.get_overlapping_bodies()

	for body: Node2D in bodies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(melee_damage)

	await get_tree().create_timer(melee_cooldown).timeout

	can_melee = true


func shoot() -> void:
	var game: Node = get_tree().current_scene

	if game.has_method("drain_time"):
		game.drain_time(projectile_time_cost)

	var projectile = projectile_scene.instantiate()

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position + aim_direction * 8.0
	projectile.direction = aim_direction

	projectile.rotation = (
		aim_direction.angle()
		- deg_to_rad(90.0)
	)


func update_animation(move_direction: Vector2) -> void:
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
