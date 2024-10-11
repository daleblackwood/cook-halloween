class_name Stage
extends Node3D

@export var goal: Node3D
@export var players: Array[GhostPlayer]
@export var actors: Array[Actor]
@export var spawn_point: Node3D

enum PlaybackStatus { Init, PlayerWon, ReplayWon }

var players_in_goal: Array[int] = []
var seconds_in_goal := 0.0
var time_to_pentaly := 0.0
var recorder: PlayerRecorder
var playback: PlayerPlayback
var player_count := 0
var game_ui: Node
var targets: Array[Node3D] = []
var lead_target: Node3D = null
var respawn_pos: Vector3

func _ready() -> void:
	CookMusic.play("GhostGameplay")
	CookSFX.play("lightning", CookSFX.NO_SOURCE, 0.4)
	if spawn_point:
		spawn_actors(spawn_point.global_transform.origin)
	else:
		spawn_actors(Vector3.ZERO)
	recorder = null
	playback = null
	player_count = GhostGame.player_count
	if player_count == 1:
		recorder = PlayerRecorder.new()
		add_child(recorder)
		recorder.start(players[0])
		var playback_index = GhostGame.level_index
		if PlayerPlayback.get_replay_path(playback_index) != null:
			playback = GhostGame.prefab_playback.instantiate() as PlayerPlayback
			add_child(playback)
			playback.play(playback_index)
			player_count = 2
	game_ui = GhostGame.prefab_game_ui.instantiate()
	add_child(game_ui)
	
		
func _process(delta: float) -> void:
	var in_goal := players_in_goal.size() > 0
	if playback != null:
		if playback.is_done:
			in_goal = true
					
	if in_goal:
		seconds_in_goal += delta
	else:
		seconds_in_goal = 0.0
		time_to_pentaly = 0.0
		
	if seconds_in_goal > 2.0:
		time_to_pentaly -= delta
		if time_to_pentaly < 0.0:
			time_to_pentaly = 0.5
			var one_outside = false
			for p in players:
				if not is_in_goal(p.index):
					CookSave.increase_count("candy", -1, p.index)
					one_outside = true
			if not one_outside:
				if recorder != null:
					if CookSave.get_count("candy", 0) > CookSave.get_count("candy", 1):
						recorder.save()
				GhostGame.end_level()
	
	targets = []
	for player in players:
		if not is_in_goal(player.index):
			targets.append(player)
	var closest_sq := INF
	lead_target = null
	for target in targets:
		if target == null:
			continue
		if goal:
			var dist_sq = (goal.global_transform.origin - target.global_transform.origin).length_squared()
			if dist_sq < closest_sq:
				lead_target = target
				closest_sq = dist_sq
				
	if lead_target:
		respawn_pos = (lead_target as GhostPlayer).get_respawn_pos()
		for target in targets:
			if target == lead_target:
				continue
			var max_dist := 32.0
			var diff := target.global_transform.origin - lead_target.global_transform.origin
			if diff.length_squared() > max_dist * max_dist:
				target.global_transform.origin = respawn_pos
	

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


func set_player_in_goal(index: int, inside: bool) -> void:
	var existing = -1
	for i in range(players_in_goal.size()):
		if players_in_goal[i] == index:
			existing = i
			break
	if inside and existing < 0:
		players_in_goal.append(index)
	elif not inside and existing >= 0:
		players_in_goal.remove_at(index)
		
		
func is_in_goal(index: int) -> bool:
	for i in range(players_in_goal.size()):
		if players_in_goal[i] == index:
			return true
	return false
