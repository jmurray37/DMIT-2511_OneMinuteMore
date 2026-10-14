
extends Node2D

var time_left: float = 60.0
var is_dead: bool = false

var combat_room: int = 1
var current_room_type: String = "normal"
var is_transitioning: bool = false
var player_start_position: Vector2 = Vector2.ZERO

var normal_encounter_budget: int = 5

var peaceful_recovery_tween: Tween = null

# Hourglass Reset progression.
var hourglass_reset_unlocked: bool = false
var hourglass_reset_active: bool = false
var hourglass_cooldown_remaining: int = 0
var room_five_reward_claimed: bool = false

@export var hard_budget_multiplier: float = 1.5
@export var hard_time_reward_multiplier: float = 2.0

@export var peaceful_recovery_duration: float = 1.5
@export var hourglass_reset_duration: float = 1.5

const MAX_TIME: float = 60.0
const PEACEFUL_MIN_TIME: float = 30.0
const HOURGLASS_FRAMES: int = 13
const HOURGLASS_COOLDOWN_ROOMS: int = 5

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

	normal_encounter_budget = int(
		enemy_spawner.get("encounter_budget")
	)

	# Award the Room 5 reward when its encounter is cleared.
	if enemy_spawner.has_signal("encounter_cleared"):
		enemy_spawner.connect(
			"encounter_cleared",
			Callable(self, "_on_encounter_cleared")
		)

	death_fade.color = Color(0.0, 0.0, 0.0, 0.0)

	death_message.visible = false
	death_message.modulate.a = 0.0
	death_message.text = "The Sands of Time Have Claimed Another"

	print("COMBAT ROOM: ", combat_room)
	print("ROOM TYPE: ", current_room_type)


func _process(delta: float) -> void:
	if is_dead:
		return

	# Do not drain time while resting or flipping.
	if (
		current_room_type == "peaceful"
		or hourglass_reset_active
	):
		timer_label.text = "%.1f" % time_left
		update_hourglass()
		return

	time_left -= delta

	if time_left <= 0.0:
		die()
		return

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func update_hourglass() -> void:
	if time_left <= 0.0:
		hourglass.frame = 12
		return

	var progress: float = 1.0 - (
		time_left / MAX_TIME
	)

	var frame_index: int = int(progress * 12.0)

	frame_index = clamp(frame_index, 0, 11)

	hourglass.frame = frame_index


func add_time(amount: float) -> void:
	if is_dead:
		return

	# Ordinary healing cannot exceed 60 seconds.
	# However, it must never erase bonus time
	# already earned from clearing Room 5.
	if time_left < MAX_TIME:
		time_left = min(
			time_left + amount,
			MAX_TIME
		)

	timer_label.text = "%.1f" % time_left
	update_hourglass()


func drain_time(amount: float) -> void:
	if is_dead:
		return

	# Invulnerability during Hourglass Reset.
	if hourglass_reset_active:
		return

	# Time cannot be drained in peaceful rooms.
	if current_room_type == "peaceful":
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


func try_start_hourglass_reset() -> bool:
	if is_dead or is_transitioning:
		return false

	if not hourglass_reset_unlocked:
		print("HOURGLASS RESET IS NOT UNLOCKED")
		return false

	if hourglass_reset_active:
		return false

	if player.is_dying or player.is_flipping:
		return false

	# Never allow the reset to reduce time.
	if time_left >= MAX_TIME:
		print("HOURGLASS RESET: ALREADY AT 60 OR ABOVE")
		return false

	if hourglass_cooldown_remaining > 0:
		print(
			"HOURGLASS RESET COOLDOWN: ",
			hourglass_cooldown_remaining,
			" COMBAT ROOMS REMAINING"
		)
		return false

	# The reset is committed as soon as it begins.
	hourglass_reset_active = true
	hourglass_cooldown_remaining = (
		HOURGLASS_COOLDOWN_ROOMS
	)

	player.begin_hourglass_flip()

	print("HOURGLASS RESET ACTIVATED!")

	animate_hourglass_reset()

	return true


func animate_hourglass_reset() -> void:
	# The player's lifespan counts upward visibly.
	# Natural time drain and incoming damage are
	# disabled while this tween is active.
	var reset_tween: Tween = create_tween()

	reset_tween.tween_property(
		self,
		"time_left",
		MAX_TIME,
		max(hourglass_reset_duration, 0.01)
	).set_trans(
		Tween.TRANS_LINEAR
	)

	await reset_tween.finished

	if not is_instance_valid(self):
		return

	time_left = MAX_TIME

	timer_label.text = "%.1f" % time_left
	update_hourglass()

	hourglass_reset_active = false

	if is_instance_valid(player):
		player.end_hourglass_flip()

	print("HOURGLASS RESET COMPLETE!")
	print(
		"COOLDOWN: ",
		hourglass_cooldown_remaining,
		" COMBAT ROOMS"
	)


func _on_encounter_cleared() -> void:
	if is_dead:
		return

	# Room 5 grants its reward exactly once per run.
	if combat_room != 5:
		return

	if room_five_reward_claimed:
		return

	if current_room_type != "hard":
		return

	room_five_reward_claimed = true

	if not hourglass_reset_unlocked:
		# First-time unlock.
		hourglass_reset_unlocked = true

		print("HOURGLASS RESET UNLOCKED!")
		print("PRESS R BELOW 60 SECONDS TO ACTIVATE!")

	else:
		# Subsequent runs award +30 seconds.
		# This intentionally bypasses the normal 60 cap.
		time_left += 30.0

		timer_label.text = "%.1f" % time_left
		update_hourglass()

		print("ROOM 5 BONUS: +30 SECONDS!")
		print("CURRENT LIFESPAN: ", time_left)


func advance_room() -> void:
	if is_dead or is_transitioning:
		return

	# Do not transition during a committed reset.
	if hourglass_reset_active:
		return

	is_transitioning = true

	var destination_type: String = String(
		get_meta("selected_portal_type", "normal")
	)

	if has_meta("selected_portal_type"):
		remove_meta("selected_portal_type")

	# Mandatory progression.
	if combat_room == 4:
		destination_type = "hard"

	elif combat_room == 9:
		destination_type = "boss"

	if destination_type not in [
		"normal",
		"hard",
		"peaceful",
		"boss"
	]:
		destination_type = "normal"

	print("SELECTED PORTAL: ", destination_type)

	# Finish peaceful-room healing if the player
	# leaves before its animation completes.
	if current_room_type == "peaceful":
		if peaceful_recovery_tween != null:
			if peaceful_recovery_tween.is_valid():
				peaceful_recovery_tween.kill()

			peaceful_recovery_tween = null

		time_left = max(
			time_left,
			PEACEFUL_MIN_TIME
		)

		timer_label.text = "%.1f" % time_left
		update_hourglass()

	# Only combat rooms advance progression
	# and recharge the Hourglass Reset.
	if destination_type != "peaceful":
		combat_room += 1

		if hourglass_cooldown_remaining > 0:
			hourglass_cooldown_remaining -= 1

			print(
				"HOURGLASS COOLDOWN: ",
				hourglass_cooldown_remaining,
				" COMBAT ROOMS REMAINING"
			)

	current_room_type = destination_type

	print("COMBAT ROOM: ", combat_room)
	print("ENTERING ROOM TYPE: ", current_room_type)

	if enemy_spawner.has_method("clear_existing_portals"):
		enemy_spawner.call("clear_existing_portals")

	# Remove enemies and corpses from the previous room.
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

	if is_dead:
		return

	match current_room_type:
		"normal":
			start_combat_encounter(false)

		"hard":
			start_combat_encounter(true)

		"peaceful":
			start_peaceful_room()

		"boss":
			start_boss_room()

	print("REMAINING LIFESPAN: ", time_left)

	is_transitioning = false


func start_combat_encounter(is_hard: bool) -> void:
	if not enemy_spawner.has_method("spawn_encounter"):
		push_error("EnemySpawner is missing spawn_encounter()")
		return

	var budget: int = normal_encounter_budget

	if is_hard:
		budget = max(
			1,
			int(ceil(
				float(normal_encounter_budget)
				* hard_budget_multiplier
			))
		)

	enemy_spawner.set("encounter_budget", budget)
	enemy_spawner.call("spawn_encounter")

	var reward_multiplier: float = 1.0

	if is_hard:
		reward_multiplier = hard_time_reward_multiplier

	var enemies_value: Variant = enemy_spawner.get(
		"spawned_enemies"
	)

	if enemies_value is Array:
		var enemies: Array = enemies_value as Array

		for entry: Variant in enemies:
			var enemy: Enemy = entry as Enemy

			if enemy == null:
				continue

			if not is_instance_valid(enemy):
				continue

			if enemy.get("time_reward_multiplier") != null:
				enemy.set(
					"time_reward_multiplier",
					reward_multiplier
				)

	if is_hard:
		print("HARD ENCOUNTER STARTED!")
		print("ENCOUNTER BUDGET: ", budget)
		print("TIME REWARD MULTIPLIER: ", reward_multiplier)
	else:
		print("NORMAL ENCOUNTER STARTED!")
		print("ENCOUNTER BUDGET: ", budget)


func start_peaceful_room() -> void:
	print("ENTERING PEACEFUL ROOM!")

	enemy_spawner.set("encounter_started", false)
	enemy_spawner.set("room_cleared", true)

	if peaceful_recovery_tween != null:
		if peaceful_recovery_tween.is_valid():
			peaceful_recovery_tween.kill()

		peaceful_recovery_tween = null

	if time_left < PEACEFUL_MIN_TIME:
		print(
			"RECOVERING TIME FROM ",
			time_left,
			" TO ",
			PEACEFUL_MIN_TIME
		)

		peaceful_recovery_tween = create_tween()

		peaceful_recovery_tween.tween_property(
			self,
			"time_left",
			PEACEFUL_MIN_TIME,
			peaceful_recovery_duration
		).set_trans(
			Tween.TRANS_SINE
		).set_ease(
			Tween.EASE_OUT
		)

	else:
		print(
			"NO RECOVERY NEEDED. CURRENT TIME: ",
			time_left
		)

	timer_label.text = "%.1f" % time_left
	update_hourglass()

	print("PEACEFUL ROOM: COUNTDOWN PAUSED")

	if enemy_spawner.has_method("spawn_portals"):
		enemy_spawner.call("spawn_portals")
	else:
		push_error("EnemySpawner is missing spawn_portals()")


func start_boss_room() -> void:
	print("ENTERING ROOM 10: GOD OF TIME!")

	enemy_spawner.set("encounter_started", false)
	enemy_spawner.set("room_cleared", true)

	print("BOSS ENCOUNTER NOT IMPLEMENTED YET.")


func die() -> void:
	if is_dead:
		return

	time_left = 0.0
	is_dead = true

	timer_label.text = "0.0"
	update_hourglass()

	print("TIME HAS RUN OUT")

	await player.begin_death()

	if not is_instance_valid(death_fade):
		return

	print("PLAYER HAS TURNED TO SAND")

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

	death_message.visible = true
	death_message.modulate.a = 0.0

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
