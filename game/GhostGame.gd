extends Node

const MAX_PLAYER_COUNT = 4

@export var player_count: int = 1
@export var levels: Array[PackedScene]
@export var prefab_player: PackedScene
@export var colors: Array[Color]
@export var scene_title: PackedScene
@export var scene_settings: PackedScene
@export var scene_controls: PackedScene
@export var scene_end_level: PackedScene
@export var scene_end_game: PackedScene
@export var player_mats: Array[Material]
@export var prefab_playback: PackedScene
@export var prefab_game_ui: PackedScene


class Player:
	var node: GhostPlayer
	var index := 0

var players: Array[Player] = []
var level_index := -1
var current_scene: Node
var previous_scene: Node
var time: float = 0.0
var level_time: float = 0.0


func _process(delta: float) -> void:
	time += delta
	level_time += delta


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
		
		
func start(count := -1) -> void:
	if count > 0:
		set_players(count)
	reset_scores()
	start_level(0)
	
	
func start_level(index: int) -> void:
	level_index = index
	if player_count < 2:
		reset_scores()
	var level = levels[level_index]
	set_scene(level)
	level_time = 0.0
	
	
func set_scene(scene: Variant) -> void:
	set_paused(false)
	if scene is PackedScene:
		scene = scene.instantiate()
	if current_scene != null:
		if current_scene != previous_scene:
			previous_scene = current_scene
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
		
		
func restart_level() -> void:
	var prev_candy := 0
	start_level(level_index)
	
	
func reset_scores() -> void:
	for i in range(4):
		CookSave.set_count("candy", 0, i)
		
		
func to_title() -> void:
	set_scene(scene_title)
	

func to_controls() -> void:
	set_scene(scene_controls)
	

func to_settings() -> void:
	set_scene(scene_settings)
	
	
func back_scene() -> void:
	if previous_scene != null:
		set_scene(previous_scene)


func set_paused(on: bool) -> void:
	get_tree().paused = on
