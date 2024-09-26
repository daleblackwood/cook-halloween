class_name Knockable
extends RigidBody3D

enum State { Idle, Knocked, Exploded }

var state := State.Idle
	
	
func knock(dir: Vector3) -> void:
	if state >= State.Knocked:
		return
	var impulse := dir.normalized() * 10.0
	apply_impulse(impulse)
	state = State.Knocked


func explode() -> void:
	CookGFX.fire_bodies(2, "candy", global_transform.origin, 5.0, 8.0)
	CookGFX.fire_bodies(6, "pumpkinfrag", global_transform.origin, 10.0, 16.0)
	queue_free()


func _on_body_entered(body: Node) -> void:
	if state != State.Knocked:
		return
	explode()
