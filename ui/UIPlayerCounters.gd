extends Control

@export var seperation := 100.0
@export var centered := false

var counters = []

func _ready() -> void:
	var pos := Vector2.ZERO
	if centered:
		pos.x -= seperation * GhostGame.player_count * 0.5 - size.x * 0.5 * scale.y
		pos.y = size.y * -0.5 * scale.y
	var player_count = GhostGame.player_count
	var stage = get_parent()
	while stage != null and not is_instance_of(stage, Stage):
		stage = stage.get_parent()
	if stage != null:
		player_count = stage.player_count
	else:
		if CookSave.get_count("candy", 1) > 0:
			player_count = 2
	for i in range(player_count):
		var counter := get_child(0) as UIPlayerCounter
		if i > 0:
			counter = counter.duplicate()
		counter.position = pos
		if counter.get_parent() == null:
			add_child(counter)
		pos.x += seperation
		counter.setup(i, GhostGame.colors[i])
		counters.append(counter)
		
	
