extends CharacterBody3D
class_name GhostPlayer

@export var speed := 7.5
@export var dash_speed := 9.5
@export var jump_power := 15.0
@export var dash_duration := 0.4

const GRAVITY = 40.0

enum MoveState { Ground, Jump, AirCharge, UpDash, AirDash, MAX }

class MoveAnimData:
	var name: String
	var blend := 0.0
	func _init(name: String) -> void:
		self.name = name

var look_dir = Vector3.FORWARD
var time_in_air = 0.0
var time_charging := 0.0
var move_state := MoveState.Ground
var spawn_pos = Vector3.ZERO
var anim: AnimationTree
var want_jump := false
var want_move := false
var want_dash := false
var jump_pressed := false
var dash_pressed := false
var move_dir := Vector3.ZERO
var move_velocity := Vector3.ZERO
var input_dir := Vector2.ZERO
var move_data: Array[MoveAnimData] = []
var state_time := 0.0
var dashes_total := 1
var dashes_remaining := 0
var ground_pos_a := Vector3.ZERO
var ground_pos_b := Vector3.ZERO
var ground_pos_c := Vector3.ZERO
var ground_pos_time = 0.0

func _ready():
	spawn_pos = global_transform.origin
	anim = $AnimationTree
	move_data.resize(MoveState.MAX)
	move_data[MoveState.Ground] = MoveAnimData.new("run")
	move_data[MoveState.Jump] = MoveAnimData.new("jump")
	move_data[MoveState.AirCharge] = MoveAnimData.new("air_charge")
	move_data[MoveState.UpDash] = MoveAnimData.new("up_dash")
	move_data[MoveState.AirDash] = MoveAnimData.new("air_dash")
	

func _physics_process(delta: float) -> void:
	var wanted_jump := want_jump
	want_jump = Input.is_action_pressed("ui_accept")
	jump_pressed = want_jump and not wanted_jump
	var wanted_dash := want_dash
	want_dash = Input.is_key_pressed(KEY_SHIFT)
	dash_pressed = want_dash and not wanted_dash	
	input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	var right = Vector3.RIGHT
	var forward = Vector3.FORWARD
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_basis = cam.global_transform.basis
		right = cam_basis.x
		forward = right.cross(Vector3.UP)
	move_dir = (right * input_dir.x + forward * input_dir.y).clampf(-1.0, 1.0)
	want_move = move_dir.length_squared() > 0.2
	if not want_move:
		move_dir = Vector3.ZERO
		
	move_velocity = Vector3.ZERO
	var prev_state := move_state
	move_state = update_move_state(delta)
	if move_state != prev_state:
		state_time = 0.0
	else:
		state_time += delta
	
	var velocity_to = move_velocity
	velocity_to.y += velocity.y
	velocity = velocity.lerp(velocity_to,  Maths.dease(delta, 0.3))
	
	var anim_move := velocity
	anim_move.y = 0.0
	var move_speed = anim_move.length()
	
	for i in range(MoveState.MAX):
		var data = move_data[i]
		var blend_inc = delta * 10.0
		if i != move_state:
			blend_inc = -blend_inc
		data.blend = clampf(data.blend + blend_inc, 0.0, 1.0)
		anim.set("parameters/%s_blend/blend_amount" % data.name, clampf(data.blend, 0.0, 1.0))

	anim.set("parameters/run_blend/blend_amount", clampf(move_speed, 0.0, 1.0))
	anim.set("parameters/run_fast_blend/blend_amount", 1.0 if want_dash else 0.0)
	anim.set("parameters/run_speed/scale", clampf(move_speed * 0.3, 0.0, 3.0))
	
	move_and_slide()
	transform.basis = transform.basis.slerp(Basis.looking_at(-look_dir), Maths.dease(delta, 0.2))
	
	if global_transform.origin.y < -10.0:
		global_transform.origin = ground_pos_b
	
	
func update_move_state(delta: float) -> MoveState:
	match move_state:
		MoveState.AirDash:
			return air_dash_update(delta)
		MoveState.UpDash:
			return up_dash_update(delta)
		MoveState.AirCharge:
			return air_charge_update(delta)
		MoveState.Jump:
			return jump_update(delta)
	return ground_update(delta)
	
		
func ground_update(delta: float) -> MoveState:
	time_in_air = 0.0
	dashes_remaining = dashes_total
	
	if not is_on_wall():
		ground_pos_time += delta
		if ground_pos_time > 0.5:
			ground_pos_b = ground_pos_a
			ground_pos_a = global_transform.origin
			ground_pos_time = 0.0

	update_forward_movement(delta)
		
	if jump_pressed and time_in_air < 0.1:
		return jump_start()
		
	if not is_on_floor():
		return MoveState.Jump
		
	return MoveState.Ground
	
	
func jump_start() -> MoveState:
	var applied_power = jump_power
	if want_dash:
		applied_power *= 1.2
	velocity.y = applied_power
	return MoveState.Jump
	
	
func jump_update(delta: float) -> MoveState:
	if is_on_floor():
		return MoveState.Ground
		
	update_air_movement(delta, GRAVITY)
	if not want_jump and velocity.y > 0.0:
		velocity.y = 0.0
		
	if jump_pressed and dashes_remaining > 0:
		if want_dash:
			return air_dash_start()
		return air_charge_update(delta)
		
	return MoveState.Jump
	
	
func air_charge_update(delta: float) -> MoveState:
	velocity.y = -2.0
	
	if want_move:
		move_velocity = move_dir * speed * 0.5
		look_dir = move_dir.normalized()
		
	if not want_jump:
		return jump_update(delta)
		
	if dash_pressed and dashes_remaining > 0:
		return up_dash_start()
		
	return MoveState.AirCharge
	
	
func air_dash_start() -> MoveState:
	dashes_remaining -= 1
	return MoveState.AirDash
		
	
func air_dash_update(delta: float) -> MoveState:
	if is_on_floor() or is_on_ceiling():
		return MoveState.Ground
	update_air_movement(delta, 0.0, speed * 2.0)
	velocity.y = 0.0
	if state_time > dash_duration:
		return MoveState.Jump
		
	if jump_pressed:
		return up_dash_update(delta)
		
	return MoveState.AirDash
	
	
func up_dash_start() -> MoveState:
	dashes_remaining -= 1
	return MoveState.UpDash
		
	
func up_dash_update(delta: float) -> MoveState:
	if is_on_floor() or is_on_ceiling():
		return MoveState.Ground
	update_air_movement(delta, GRAVITY * -0.3, 0.0)
	velocity.y = 10.0
	if state_time > dash_duration:
		return MoveState.Jump
		
	return MoveState.UpDash
	
	
func update_air_movement(delta: float, gravity: float, move_speed := 0.0) -> void:
	time_in_air += delta
	update_forward_movement(delta, move_speed)
	velocity.y -= max(gravity * delta, -30.0)
	
	
func update_forward_movement(delta: float, move_speed := 0.0) -> void:
	if want_move:
		if move_speed == 0.0:
			move_speed = dash_speed if want_dash else speed
		move_velocity = move_dir * move_speed
		look_dir = move_dir.normalized()
	

		
