extends Node

const MAX_PLAYER_COUNT = 4

@export var player_count: int = 1
@export var levels: Array[PackedScene]
@export var prefab_player: PackedScene
@export var colors: Array[Color]
@export var scene_title: PackedScene
@export var scene_end_level: PackedScene
@export var scene_end_game: PackedScene
@export var player_mats: Array[Material]


class Player:
	var node: GhostPlayer
	var index := 0

var players: Array[Player] = []
var level_index := 0
var current_scene: Node


func set_players(count: int) -> void:
	player_count = count
	CookInput.player_count = count
	while players.size() < count:
		var player := Player.new()
		player.index = players.size()
		players.append(player)
	while players.size() > count:
		var player = players.pop_back()
		player.queue_free()
		
		
func start(player_count := -1) -> void:
	if player_count > 0:
		set_players(player_count)
	start_level(0)
	
	
func start_level(index: int) -> void:
	level_index = index
	var level = levels[level_index]
	set_scene(level)
	
	
func set_scene(scene: Variant) -> void:
	if scene is PackedScene:
		scene = scene.instantiate()
	if current_scene != null:
		#current_scene.queue_free()
		get_tree().root.remove_child(current_scene)
	current_scene = scene
	if current_scene.get_parent() == null:
		get_tree().root.add_child(current_scene)
		
		
func end_level() -> void:
	set_scene(scene_end_level)
	
	
func end_level_next() -> void:
	if level_index < levels.size() - 1:
		start_level(level_index + 1)
	else:
		set_scene(scene_end_game)
		
		
func to_title() -> void:
	set_scene(scene_title)
