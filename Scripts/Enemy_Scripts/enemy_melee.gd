extends "res://Scripts/Enemy_Scripts/enemy.gd"

@export var speed: float = 50.0
@export var stopping_distance: float = 10.0

@export var attack_interval: float = 2.0
@export var attack_time_damage: float = 4.0
@export var attack_area_distance: float = 8.0

@export var corpse_lifetime: float = 2.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var melee_timer: Timer = $MeleeTimer
@onready var attack_area: Area2D = $AttackArea

var is_attacking: bool = false
var is_hit: bool = false
var is_dying: bool = false


func _ready() -> void:
	super._ready()

	melee_timer.wait_time = attack_interval
	melee_timer.one_shot = false

	if not melee_timer.timeout.is_connected(attack):
		melee_timer.timeout.connect(attack)

	melee_timer.start()

	play_animation("Idle_Melee")


func _physics_process(_delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
		return

	if is_dying or is_hit or is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	var direction: Vector2 = global_position.direction_to(
		player.global_position
	)

	update_attack_area(direction)

	if distance_to_player > stopping_distance:
		velocity = direction * speed
		play_animation("Walk_Melee")
	else:
		velocity = Vector2.ZERO
		play_animation("Idle_Melee")

	move_and_slide()


func update_attack_area(direction: Vector2) -> void:
	attack_area.position = direction * attack_area_distance
	attack_area.rotation = direction.angle()


func attack() -> void:
	if player == null:
		return

	if is_attacking or is_hit or is_dying:
		return

	var distance_to_player: float = global_position.distance_to(
		player.global_position
	)

	if distance_to_player > stopping_distance + attack_area_distance:
		return

	is_attacking = true
	velocity = Vector2.ZERO

	animated_sprite.play("Attack_Melee")

	var bodies: Array[Node2D] = attack_area.get_overlapping_bodies()

	for body: Node2D in bodies:
		if not body.is_in_group("player"):
			continue

		var game: Node = get_tree().current_scene

		if game.has_method("drain_time"):
			game.drain_time(attack_time_damage)

		print(
			"MELEE GUY HIT PLAYER FOR ",
			attack_time_damage,
			" SECONDS"
		)

		break

	await animated_sprite.animation_finished

	if not is_instance_valid(self):
		return

	if is_dying:
		return

	is_attacking = false
	play_animation("Idle_Melee")


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	if is_dying:
		return

	current_health -= amount
	current_health = max(current_health, 0)

	print(
		name,
		" HP: ",
		current_health,
		"/",
		max_health
	)

	if current_health <= 0:
		die()
		return

	if is_hit:
		return

	is_hit = true
	is_attacking = false
	velocity = Vector2.ZERO

	animated_sprite.play("Hit_Melee")

	await animated_sprite.animation_finished

	if not is_instance_valid(self):
		return

	if is_dying:
		return

	is_hit = false
	play_animation("Idle_Melee")


func die() -> void:
	if is_dying:
		return

	is_dying = true
	is_attacking = false
	is_hit = false

	velocity = Vector2.ZERO

	melee_timer.stop()

	# Stop the corpse from attacking or blocking things.
	attack_area.monitoring = false
	attack_area.monitorable = false

	var body_collision: CollisionShape2D = $CollisionShape2D
	body_collision.disabled = true

	animated_sprite.play("Death_Melee")

	await animated_sprite.animation_finished

	if not is_instance_valid(self):
		return

	# Freeze on the final death frame.
	animated_sprite.pause()

	give_time_reward()

	print(name, " DIED")

	# Leave the bones behind for 5 seconds.
	await get_tree().create_timer(corpse_lifetime).timeout

	if is_instance_valid(self):
		queue_free()


func play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation == animation_name:
		if not animated_sprite.is_playing():
			animated_sprite.play()
		return

	animated_sprite.play(animation_name)
