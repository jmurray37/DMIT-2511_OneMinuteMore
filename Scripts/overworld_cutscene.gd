
extends Node

@export var walking_speed: float = 50.0
@export var dungeon_scene: PackedScene

@export_group("Cutscene Nodes")
@export var player: AnimatedSprite2D
@export var door_point: Marker2D
@export var dialogue_box: Control

@export_group("Walking Animation")
@export var walk_animation: StringName = &"Walk"

var cutscene_active: bool = false
var is_walking: bool = false
var is_transitioning: bool = false


func _ready() -> void:
	set_physics_process(false)

	if player == null or door_point == null or dialogue_box == null:
		push_error(
			"OverworldCutscene: Assign Player, Door Point, "
			+ "and Dialogue Box in the Inspector."
		)
		return

	if not dialogue_box.has_signal("dialogue_finished"):
		push_error(
			"OverworldCutscene: Dialogue Box is missing "
			+ "the dialogue_finished signal."
		)
		return

	player.stop()

	call_deferred("start_opening_cutscene")


func start_opening_cutscene() -> void:
	cutscene_active = true

	var opening_dialogue: Array[Dictionary] = [
		{
			"speaker": "You",
			"text": "Damn... this place creeps me out!"
		},
		{
			"speaker": "You",
			"text": "But... I can't turn back now. I can feel the curse closing in."
		}
	]

	dialogue_box.connect(
		"dialogue_finished",
		Callable(self, "_on_dialogue_finished"),
		CONNECT_ONE_SHOT
	)

	dialogue_box.call("start_dialogue", opening_dialogue)


func _on_dialogue_finished() -> void:
	if not cutscene_active:
		return

	is_walking = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not is_walking or is_transitioning:
		return

	var target: Vector2 = door_point.global_position

	var distance: float = player.global_position.distance_to(target)

	if distance <= 2.0:
		finish_walking()
		return

	var direction: Vector2 = (
		target - player.global_position
	).normalized()

	player.global_position = player.global_position.move_toward(
		target,
		walking_speed * delta
	)

	play_walk_animation()


func play_walk_animation() -> void:
	if player.sprite_frames == null:
		return

	if not player.sprite_frames.has_animation(walk_animation):
		return

	if player.animation != walk_animation or not player.is_playing():
		player.play(walk_animation)


func finish_walking() -> void:
	is_walking = false
	set_physics_process(false)

	player.stop()
	player.frame = 0

	finish_cutscene()


func _unhandled_input(event: InputEvent) -> void:
	if not cutscene_active:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		skip_cutscene()


func skip_cutscene() -> void:
	cutscene_active = false
	is_walking = false
	set_physics_process(false)

	if dialogue_box.is_visible_in_tree():
		dialogue_box.call("end_dialogue")

	player.global_position = door_point.global_position

	player.stop()
	player.frame = 0

	finish_cutscene()


func finish_cutscene() -> void:
	if is_transitioning:
		return

	cutscene_active = false
	is_transitioning = true

	if dungeon_scene != null:
		get_tree().call_deferred(
			"change_scene_to_packed",
			dungeon_scene
		)
	else:
		print(
			"Opening cutscene complete. "
			+ "Dungeon scene not assigned."
		)
