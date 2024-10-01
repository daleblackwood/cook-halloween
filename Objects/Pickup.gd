class_name Pickup
extends RigidBody3D

@export var item_key := "pickup"

var target: Node3D
var speed := 0.0

func pickup(player: GhostPlayer) -> void:
	CookSave.increase_count(item_key, 1, player.index)
	queue_free()
	
func _process(delta: float) -> void:
	if not target:
		return
	var diff = target.global_transform.origin - transform.origin
	speed += delta
	var move = diff.clampf(-speed, speed)
	global_transform.origin += move

func _on_body_entered(body: Node3D) -> void:
	print("candy enter ", body)
	if body is GhostPlayer:
		target = body
