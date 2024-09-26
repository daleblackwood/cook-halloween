class_name Goal
extends Node3D


func _on_cauldron_area_entered(area) -> void:
	print("in goal")


func _on_cauldron_area_exited(area) -> void:
	print("out of goal")
