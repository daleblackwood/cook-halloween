class_name PlayerPlayback
extends Node3D

var recorder: CookRecorder
var time := 0.0
var look_dir := Vector3.FORWARD
var index := 1
var prev_score := 0
var score_offset := 0
var stage: Stage

func _ready() -> void:
	stage = get_parent_node_3d()
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
		path = "res://data/replay%d.dat" % level_index
		if not FileAccess.file_exists(path):
			return ""
	return path


func _process(delta: float) -> void:
	if recorder == null:
		return
		
	time += delta
		
	var snapshot := recorder.retrieve(time)
	if snapshot == null:
		return
	
	if snapshot.score > prev_score:
		prev_score = snapshot.score
		CookSFX.play("coin", global_transform.origin, 0.5)
	CookSave.set_count("candy", snapshot.score + score_offset, 1)
	
	var target_pos := snapshot.position
	var pos := global_transform.origin
	if is_nan(target_pos.x + target_pos.y + target_pos.z):
		target_pos = pos
	var diff := target_pos - pos
	diff.y = 0.0
	if diff.length_squared() > 0.01:
		look_dir = diff
		look_dir.y = 0.0
		look_dir = look_dir.normalized()
	
	global_transform.origin = target_pos
	transform.basis = transform.basis.slerp(Basis.looking_at(-look_dir), CookMath.dease(delta, 0.2))
	
	var goal_diff := stage.goal.global_transform.origin - global_transform.origin
	goal_diff.y = 0.0
	var in_goal := snapshot.time < time or goal_diff.length_squared() < 2.0
	stage.set_player_in_goal(index, in_goal)
