class_name Pickup
extends RigidBody3D

@export var item_key := "pickup"

func pickup(player: GhostPlayer) -> void:
	CookSave.increase_count(item_key, 1, player.index)
	queue_free()
