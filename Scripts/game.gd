
extends Node2D

var time_left: float = 60.0
var is_dead: bool = false

var combat_room: int = 1
var is_transitioning: bool = false
var player_start_position: Vector2 = Vector2.ZERO

const MAX_TIME: float = 60.0
const HOURGLASS_FRAMES: int = 13

const TIME_ORB_SCENE: PackedScene = preload(
	"res://Scenes/Ui/TimeOrb.tscn"
)

@onready var timer_label: Label = $CanvasLayer/Label
@onready var hourglass: AnimatedSprite2D = $CanvasLayer/Hourglass
@onready var time_orbs: Node2D = $CanvasLayer/TimeOrbs

@onready var player: Player = $Player
@onready var floor_tiles: TileMapLayer = $FloorTiles
@onready var enemy_spawner: Node2D = $Node2D

@onready var death_fade: ColorRect = $DeathOverlay/ColorRect
@onready var death_message: Label = $DeathOverlay/DeathMessage


func _ready() -> void:
	player_start_position = player.global_position

	death_fade.color = Color(0.0, 0.0, 0.0, 0.0)

	death_message.visible = false
	death_message.modulate.a = 0.0
	death_message.text = "The Sands of Time Have Claimed Another"

	print("COMBAT ROOM: ", combat_room)


func _process(delta: float) -> void:
	if is_dead:
		return

	time_left -= delta

	if time_left <= 0.0:
		die()
		return

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func _unhandled_input(event: InputEvent) -> void:
	if not is_dead:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_R:
				restart_game()


func update_hourglass() -> void:
	if time_left <= 0.0:
		hourglass.frame = 12
		return

	var progress := 1.0 - (time_left / MAX_TIME)
	var frame_index := int(progress * 12.0)

	frame_index = clamp(frame_index, 0, 11)
	hourglass.frame = frame_index


func add_time(amount: float) -> void:
	if is_dead:
		return

	time_left = min(time_left + amount, MAX_TIME)

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func drain_time(amount: float) -> void:
	if is_dead:
		return

	time_left -= amount
	time_left = max(time_left, 0.0)

	if time_left <= 0.0:
		die()
		return

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func spawn_time_orb(enemy_position: Vector2) -> void:
	if is_dead:
		return

	var orb: Node2D = TIME_ORB_SCENE.instantiate() as Node2D

	time_orbs.add_child(orb)

	var screen_position: Vector2 = (
		get_viewport().get_canvas_transform() * enemy_position
	)

	orb.global_position = screen_position

	var frame_texture: Texture2D = hourglass.sprite_frames.get_frame_texture(
		hourglass.animation,
		hourglass.frame
	)

	var hourglass_center: Vector2 = hourglass.global_position

	if frame_texture != null:
		hourglass_center = hourglass.to_global(
			frame_texture.get_size() / 2.0
		)

	orb.call("fly_to", hourglass_center)


func advance_room() -> void:
	if is_dead or is_transitioning:
		return

	is_transitioning = true

	combat_room += 1

	print("ENTERING COMBAT ROOM: ", combat_room)

	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	player.global_position = player_start_position

	if floor_tiles.has_method("generate_floor"):
		floor_tiles.call("generate_floor")
	else:
		push_error("FloorTiles is missing generate_floor()")
		is_transitioning = false
		return

	await get_tree().process_frame

	if enemy_spawner.has_method("spawn_encounter"):
		enemy_spawner.call("spawn_encounter")
	else:
		push_error("EnemySpawner is missing spawn_encounter()")

	print("REMAINING LIFESPAN: ", time_left)

	is_transitioning = false


func die() -> void:
	if is_dead:
		return

	time_left = 0.0
	is_dead = true

	timer_label.text = "0.0"
	update_hourglass()

	print("TIME HAS RUN OUT")

	# Freeze gameplay and play the sand death animation.
	await player.begin_death()

	if not is_instance_valid(death_fade):
		return

	print("PLAYER HAS TURNED TO SAND")

	# Fade the screen to black.
	var fade_tween: Tween = create_tween()
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	fade_tween.tween_property(
		death_fade,
		"color",
		Color.BLACK,
		1.5
	).set_trans(Tween.TRANS_LINEAR)

	await fade_tween.finished

	print("DEATH FADE COMPLETE")

	# Reveal the message over the black screen.
	death_message.visible = true
	death_message.modulate.a = 0.0

	# Slowly fade in the message.
	var message_tween: Tween = create_tween()
	message_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	message_tween.tween_property(
		death_message,
		"modulate:a",
		1.0,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await message_tween.finished

	print("DEATH MESSAGE DISPLAYED")


func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
