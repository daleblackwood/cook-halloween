class_name Stage
extends Node3D

@export var goal: Node3D
@export var players: Array[GhostPlayer]
@export var actors: Array[Actor]
@export var spawn_point: Node3D

func _ready() -> void:
	if spawn_point:
		spawn_actors(spawn_point.global_transform.origin)
	else:
		spawn_actors(Vector3.ZERO)


func register_actor(node: Actor) -> void:
	if node is GhostPlayer:
		players.append(node)
	actors.append(node)
	
	
func spawn_actors(origin: Vector3) -> void:
	var player_count:int = GhostGame.player_count
	origin.x -= player_count * 0.5
	for i in range(player_count):
		var player := GhostGame.prefab_player.instantiate() as GhostPlayer
		add_child(player)
		player.owner = self
		player.set_index(i)
		if i < GhostGame.players.size():
			GhostGame.players[i].node = player
		player.global_transform.origin = origin + global_transform.origin
		origin.x += 1.0
