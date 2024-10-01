extends Control

@export var seperation := 100.0
@export var centered := false

var counters = []

func _ready() -> void:
	var pos := Vector2.ZERO
	if centered:
		pos.x -= seperation * GhostGame.player_count * 0.5 - size.x * 0.5 * scale.y
		pos.y = size.y * -0.5 * scale.y
	for i in range(GhostGame.player_count):
		var counter := get_child(0) as UIPlayerCounter
		if i > 0:
			counter = counter.duplicate()
		counter.position = pos
		if counter.get_parent() == null:
			add_child(counter)
		pos.x += seperation
		counter.setup(i, GhostGame.colors[i])
		counters.append(counter)
		
	
