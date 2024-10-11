class_name PlayerRecorder
extends Node

@export var player: GhostPlayer

var recorder: CookRecorder
var time := 0.0
var basename := ""
	
func start(player: GhostPlayer) -> void:
	recorder = CookRecorder.new()
	self.player = player
	time = 0.0	
	basename = "replay%d" % GhostGame.level_index
	
	
func save() -> void:
	var path = "user://%s.dat" % CookStrings.to_tag(basename)
	recorder.save(path)
	

func _process(delta: float) -> void:
	if not player:
		return
	time += delta
	var position = player.global_transform.origin
	var score = CookSave.get_count("candy", player.index)
	recorder.record(time, position, score)
