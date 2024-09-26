class_name Stage
extends Node3D

@export var goal: Node3D
@export var players: Array[GhostPlayer]

func _ready() -> void:
	players = []
	for i in range(get_child_count()):
		var child := get_child(i)
		if is_instance_of(child, GhostPlayer):
			players.append(child)
		if is_instance_of(child, Goal):
			goal = child
