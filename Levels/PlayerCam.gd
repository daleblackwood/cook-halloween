extends Camera3D

@export var targets: Array[Node3D] = []
@export var distance := 15.0
@export var height_multi := 0.6

var stage: Stage

func _ready() -> void:
	stage = get_parent_node_3d() 

func _process(delta: float) -> void:
	var target_pos := Vector3.ZERO
	var target_count := 0.0
	if targets.size() < 1 and stage.players.size() > 0:
		for player in stage.players:
			targets.append(player)
	for target in targets:
		if target == null:
			continue
		target_count += 1.0
		target_pos += target.global_transform.origin
		
	if target_count < 1.0:
		return
		
	target_pos /= target_count
	
	target_pos += Vector3.UP
	
	var cam_pos := target_pos
	cam_pos += Vector3.BACK * distance + Vector3.UP * distance * height_multi
	
	var move = cam_pos - global_transform.origin
	move *= 1.0 - CookMath.dease(delta, 0.9)
	
	global_transform.origin += move
	global_transform.basis = Basis.looking_at(target_pos - cam_pos)
