extends Control

var counters = []

func _ready() -> void:
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
		var counter_container := get_child(0)
		if i > 0:
			counter_container = counter_container.duplicate()
		if counter_container.get_parent() == null:
			add_child(counter_container)
		var counter = (counter_container if is_instance_of(counter_container, UIPlayerCounter) else counter_container.get_child(0)) as UIPlayerCounter
		counter.setup(i, GhostGame.colors[i])
		counters.append(counter)
	#if has_method("queue_sort"):
	#	call("queue_sort")
	
