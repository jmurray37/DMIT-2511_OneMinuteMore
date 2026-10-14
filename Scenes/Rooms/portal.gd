
extends Area2D

var is_activated: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return

	if not body.is_in_group("player") and body.name != "Player":
		return

	var game: Node = get_tree().current_scene

	if not game.has_method("advance_room"):
		push_error("Game scene does not have advance_room()")
		return

	is_activated = true

	print("PLAYER ENTERED PORTAL!")

	# Prevent the portal from activating again.
	set_deferred("monitoring", false)

	# Advance after the current physics processing finishes.
	game.call_deferred("advance_room")

	# Remove the old portal.
	queue_free()
