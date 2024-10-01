class_name Goal
extends Node3D

@export var goo: Node3D

const goal_in_time := 2.0

var gooPower := 0.0
var time := 0.0
var initGooBasis: Basis
var goal_countdown := 0.0

func _ready() -> void:
	initGooBasis = goo.transform.basis
	

func _process(delta: float) -> void:
	time += delta
	var gooBasis = initGooBasis
	gooBasis = gooBasis.scaled(Vector3(1.0, (sin(time * 20.0) + 1.1) * max(gooPower, 0.01) * 2.0, 1.0))
	if gooPower > 0.0:
		gooPower -= delta
	goo.transform.basis = gooBasis
	if goal_countdown > 0.0:
		goal_countdown -= delta
		if goal_countdown <= 0.0:
			GhostGame.end_level()
	

func _on_cauldron_area_entered(body) -> void:
	if not is_instance_of(body, GhostPlayer):
		return
	print("in goal")
	gooPower = 1.0
	goal_countdown = goal_in_time


func _on_cauldron_area_exited(body) -> void:
	if not is_instance_of(body, GhostPlayer):
		return
	print("out of goal")
	gooPower = 1.0
	goal_countdown = 0.0
