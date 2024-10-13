class_name Knockable
extends RigidBody3D

enum State { Idle, Knocked, Exploded }

var state := State.Idle
	
	
func knock(dir: Vector3) -> void:
	if state >= State.Knocked:
		return
	CookSFX.play("kick", global_transform.origin)
	var impulse := dir.normalized() * 10.0
	apply_impulse(impulse)
	state = State.Knocked


func explode() -> void:
	CookSFX.play("smash", global_transform.origin)
	CookGFX.fire_bodies(4, "candy", global_transform.origin, 5.0, 8.0)
	CookGFX.fire_bodies(6, "pumpkinfrag", global_transform.origin, 6.0, 8.0)
	queue_free()


func _on_body_entered(body: Node) -> void:
	if state != State.Knocked:
		return
	explode()
