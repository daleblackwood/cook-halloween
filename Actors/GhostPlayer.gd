extends Actor
class_name GhostPlayer

@export var index := 0
@export var speed := 7.5
@export var dash_speed := 9.5
@export var jump_power := 15.0
@export var dash_duration := 0.4
@export var base_material: Material

const GRAVITY := 40.0
const GROUND_POS_INTERVAL := 0.5

enum MoveState { Ground, Jump, AirCharge, UpDash, AirDash, MAX }

class MoveAnimData:
	var name: String
	var blend := 0.0
	func _init(name: String) -> void:
		self.name = name

var look_dir = Vector3.FORWARD
var time_in_air = 0.0
var time_charging := 0.0
var time_since_ground := 0.0
var downtime := 0.5
var move_state := MoveState.Ground
var spawn_pos = Vector3.ZERO
var anim: AnimationTree
var want_jump := false
var want_move := false
var want_dash := false
var jump_pressed := true
var dash_pressed := true
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
var color := Color(0, 0, 0)
var material: Material
var distance_to_step_sound := 1.0

func _ready():
	spawn_pos = global_transform.origin
	anim = $AnimationTree
	move_data.resize(MoveState.MAX)
	move_data[MoveState.Ground] = MoveAnimData.new("run")
	move_data[MoveState.Jump] = MoveAnimData.new("jump")
	move_data[MoveState.AirCharge] = MoveAnimData.new("air_charge")
	move_data[MoveState.UpDash] = MoveAnimData.new("up_dash")
	move_data[MoveState.AirDash] = MoveAnimData.new("air_dash")
	
	
func set_index(index: int) -> void:
	if index == self.index:
		return
	self.index = index
	var parts := ["GhostArms", "GhostBody", "GhostLegs"]
	material = GhostGame.player_mats[index]
	for part in parts:
		var node := get_node("GhostModel/GhostArmature/Skeleton3D/%s" % part) as MeshInstance3D
		if not node:
			continue
		node.set_surface_override_material(0, material)
	

func _physics_process(delta: float) -> void:
	var input := CookInput.get_input(index)
	var wanted_jump := want_jump
	want_jump = input.primary
	jump_pressed = want_jump and not wanted_jump
	var wanted_dash := want_dash
	want_dash = input.trigger
	dash_pressed = want_dash and not wanted_dash	
	input_dir = input.move
	
	var right = Vector3.RIGHT
	var forward = Vector3.FORWARD
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_basis = cam.global_transform.basis
		right = cam_basis.x
		forward = right.cross(Vector3.UP)
	move_dir = (right * input_dir.x + forward * input_dir.y)
	want_move = move_dir.length_squared() > 0.2
	if want_move:
		if move_dir.length_squared() > 1.0:
			move_dir = move_dir.normalized()
	else:
		move_dir = Vector3.ZERO
		
	if downtime > 0.0:
		downtime -= delta
		jump_pressed = false
		dash_pressed = false
		move_dir = Vector3.ZERO	
		
	if is_on_floor():
		time_since_ground = 0.0
	else:
		time_since_ground += delta
		
	move_velocity = Vector3.ZERO
	var prev_state := move_state
	move_state = update_move_state(delta)
	if move_state != prev_state:
		state_time = 0.0
	else:
		state_time += delta
	
	var velocity_to = move_velocity
	velocity_to.y += velocity.y
	velocity = velocity.lerp(velocity_to,  CookMath.dease(delta, 0.3))
	
	var anim_move := velocity
	anim_move.y = 0.0
	var move_speed = anim_move.length()
	
	if is_on_floor():
		distance_to_step_sound -= move_speed * delta
		if distance_to_step_sound < 0.0:
			CookSFX.play("step", global_transform.origin)
			distance_to_step_sound = 1.3
	
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
	transform.basis = transform.basis.slerp(Basis.looking_at(-look_dir), CookMath.dease(delta, 0.2))
	
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var body = collision.get_collider()
		var dir = collision.get_normal(0)
		if is_instance_of(body, Pickup):
			(body as Pickup).pickup(self)
		elif is_instance_of(body, Knockable):
			(body as Knockable).knock(velocity_to)
		if body is RigidBody3D:
			body.apply_impulse(velocity_to + Vector3.UP * 0.5)
	
	if global_transform.origin.y < -10.0:
		CookSave.increase_count("candy", -10, index)
		CookSFX.play("hurt", global_transform.origin)
		if time_since_ground > 2.0:
			global_transform.origin = ground_pos_b
		else:
			global_transform.origin = get_respawn_pos()
	
	
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
	
	
func get_respawn_pos() -> Vector3:
	var pc = clampf(ground_pos_time / GROUND_POS_INTERVAL, 0.0, 1.0)
	return ground_pos_b.lerp(ground_pos_a, pc)
	
		
func ground_update(delta: float) -> MoveState:
	time_in_air = 0.0
	dashes_remaining = dashes_total
	
	if not is_on_wall():
		ground_pos_time += delta
		if ground_pos_time > GROUND_POS_INTERVAL:
			ground_pos_b = ground_pos_a
			ground_pos_a = global_transform.origin
			ground_pos_time = 0.0

	update_forward_movement(delta)
		
	if jump_pressed and time_since_ground < 0.1:
		return jump_start()
		
	if not is_on_floor():
		return MoveState.Jump
		
	return MoveState.Ground
	
	
func jump_start() -> MoveState:
	CookSFX.play("jump", global_transform.origin)
	var applied_power = jump_power
	if want_dash:
		applied_power *= 1.2
	velocity.y = applied_power
	return MoveState.Jump
	
	
func jump_update(delta: float) -> MoveState:
	if is_on_floor():
		return MoveState.Ground
	
	if jump_pressed and time_since_ground < 0.2:
		return jump_start()
		
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
	CookSFX.play("dash", global_transform.origin)
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
	CookSFX.play("dash", global_transform.origin)
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
	

		
