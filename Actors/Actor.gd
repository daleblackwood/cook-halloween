class_name Actor
extends CharacterBody3D

var stage: Stage

func _enter_tree() -> void:
	stage = get_parent()
	stage.register_actor(self)
