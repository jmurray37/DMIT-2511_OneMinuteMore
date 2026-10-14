
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

	if game == null:
		push_error("Could not find the current game scene.")
		return

	if not game.has_method("advance_room"):
		push_error("Game scene does not have advance_room()")
		return

	# Read the destination assigned by EnemySpawner.
	var portal_type: String = String(
		get_meta("portal_type", "normal")
	)

	if portal_type not in [
		"normal",
		"hard",
		"peaceful",
		"boss"
	]:
		push_warning(
			"Unknown portal type: " + portal_type
		)
		portal_type = "normal"

	# Prevent any other portal from being selected.
	for portal: Node in get_tree().get_nodes_in_group(
		"room_portals"
	):
		if not is_instance_valid(portal):
			continue

		portal.set("is_activated", true)

		if portal is Area2D:
			portal.set_deferred("monitoring", false)

	is_activated = true

	# Remember which destination was selected.
	game.set_meta("selected_portal_type", portal_type)

	print("PLAYER ENTERED PORTAL: ", portal_type)

	# Advance after the current physics processing finishes.
	game.call_deferred("advance_room")

	# Remove the selected portal.
	queue_free()
