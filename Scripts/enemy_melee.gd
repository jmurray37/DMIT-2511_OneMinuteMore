extends CharacterBody2D

@export var speed: float = 50.0
@export var stopping_distance: float = 5.0

@onready var player: CharacterBody2D = get_node("../Player")
@onready var melee_timer: Timer = $Melee_Enemy/MeleeTimer

func _ready() -> void:
	melee_timer.wait_time = 2.0 #delay for enemy's melee attacks
	melee_timer.one_shot = false #???
	melee_timer.timeout.connect(attack)
	melee_timer.start()

	print("MELEE TIMER STARTED")

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

func attack() -> void:
	print("ENEMY GUY ATTACKS")
	
	$AnimationPlayer.play("Attack_Melee")

	if player == null:
		return
