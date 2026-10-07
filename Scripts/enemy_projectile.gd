extends Area2D

@export var speed: float = 120.0
@export var lifetime: float = 5.0
@export var time_penalty: float = 2.0

var direction: Vector2 = Vector2.ZERO
var shooter: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	print("PROJECTILE READY")

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if shooter != null and (body == shooter or shooter.is_ancestor_of(body)):
		return

	if body.is_in_group("enemy"):
		return

	print("PROJECTILE HIT: ", body.name)

	if body.is_in_group("player"):
		var game := get_tree().current_scene
		if game.has_method("drain_time"):
			game.drain_time(time_penalty)
			print("TIME DRAINED: ", time_penalty)
		else:
			print("current scene has no drain_time function")

	queue_free()
