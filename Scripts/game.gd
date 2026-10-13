
extends Node2D

var time_left: float = 60.0
var is_dead: bool = false

const MAX_TIME: float = 60.0
const HOURGLASS_FRAMES: int = 13

const TIME_ORB_SCENE: PackedScene = preload("res://Scenes/Ui/TimeOrb.tscn")

@onready var timer_label: Label = $CanvasLayer/Label
@onready var hourglass: AnimatedSprite2D = $CanvasLayer/Hourglass
@onready var time_orbs: Node2D = $CanvasLayer/TimeOrbs


func _process(delta: float) -> void:
	if is_dead:
		return

	time_left -= delta

	if time_left <= 0.0:
		die()

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

	# Convert the enemy's world position to screen coordinates.
	var screen_position: Vector2 = (
		get_viewport().get_canvas_transform() * enemy_position
	)

	orb.global_position = screen_position

	# Find the visible center of the hourglass sprite.
	var frame_texture: Texture2D = hourglass.sprite_frames.get_frame_texture(
		hourglass.animation,
		hourglass.frame
	)

	var hourglass_center: Vector2 = hourglass.global_position

	if frame_texture != null:
		hourglass_center = hourglass.to_global(
			frame_texture.get_size() / 2.0
		)

	# Send the orb toward the hourglass.
	orb.call("fly_to", hourglass_center)


func die() -> void:
	if is_dead:
		return

	time_left = 0.0
	is_dead = true

	timer_label.text = "0.0"
	update_hourglass()

	print("YOU DIED")
	print("PRESS R TO RESTART")


func restart_game() -> void:
	get_tree().reload_current_scene()
