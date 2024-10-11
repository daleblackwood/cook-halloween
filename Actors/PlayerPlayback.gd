class_name PlayerPlayback
extends CharacterBody3D

var recorder: CookRecorder
var time = 0.0
var look_dir = Vector3.FORWARD
var index = 1
var is_done = false
var prev_score = 0

func _ready() -> void:
	play(0)
	
	
func play(level_index: int) -> bool:
	var path = get_replay_path(level_index)
	if not FileAccess.file_exists(path):
		queue_free()
		return false
	recorder = CookRecorder.new()
	recorder.load(path)
	return true
	
	
static func get_replay_path(level_index: int) -> String:
	var path = "user://replay%d.dat" % level_index
	if not FileAccess.file_exists(path):
		return ""
	return path


func _physics_process(delta: float) -> void:
	if recorder == null:
		return
		
	time += delta
		
	var snapshot := recorder.retrieve(time)
	if snapshot == null:
		return
		
	is_done = snapshot.time < time
	
	if snapshot.score > prev_score:
		prev_score = snapshot.score
		CookSFX.play("coin", global_transform.origin, 0.5)
	CookSave.set_count("candy", snapshot.score, 1)
	
	var target_pos := snapshot.position
	var pos := global_transform.origin
	if is_nan(target_pos.x + target_pos.y + target_pos.z):
		target_pos = pos
	var diff := target_pos - pos
	if diff.length_squared() > 0.01:
		look_dir = diff
		look_dir.y = 0.0
		look_dir = look_dir.normalized()
	
	if diff.length_squared() > 4.0:
		global_transform.origin = target_pos
	else:
		velocity = diff / delta
		move_and_slide()
	transform.basis = transform.basis.slerp(Basis.looking_at(-look_dir), CookMath.dease(delta, 0.2))
