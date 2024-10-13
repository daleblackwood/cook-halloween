class_name Goal
extends Node3D

@export var goo: Node3D

const goal_in_time := 2.0

var gooPower := 0.0
var time := 0.0
var initGooBasis: Basis
var stage: Stage

func _ready() -> void:
	initGooBasis = goo.transform.basis
	stage = (get_parent() as Stage)
	stage.goal = self
	

func _process(delta: float) -> void:
	time += delta
	var gooBasis = initGooBasis
	gooBasis = gooBasis.scaled(Vector3(1.0, (sin(time * 20.0) + 1.1) * max(gooPower, 0.01) * 2.0, 1.0))
	if gooPower > 0.0:
		gooPower -= delta
	goo.transform.basis = gooBasis
	

func _on_cauldron_area_entered(body) -> void:
	if not is_instance_of(body, GhostPlayer) and not is_instance_of(body, PlayerPlayback):
		return
	CookSFX.play("cauldron", global_transform.origin)
	gooPower = 1.0
	stage.set_player_in_goal((body as GhostPlayer).index, true)


func _on_cauldron_area_exited(body) -> void:
	if not is_instance_of(body, GhostPlayer) and not is_instance_of(body, PlayerPlayback):
		return
	gooPower = 1.0
	stage.set_player_in_goal((body as GhostPlayer).index, true)
