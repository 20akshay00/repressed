extends CharacterBody2D

@export_group("Physics")
@export var gravity := 2600.0
@export var fall_gravity_mult := 0.8
@export var release_boost := 1.1
@export var whip_power := 0.9
@export var grace_time := 0.8
@export var max_velocity := 2000.0

@export_group("Pendulum")
@export var max_dist := 1100.0
@export var min_length := 50.0
@export var max_length := 300.0
@export var reel_speed := 1100.0
@export var manual_reel_speed := 100.0

var is_hooked := false
var hook_node: Node2D = null
var hook_offset := Vector2.ZERO
var rope_length := 0.0
var target_rope_length := 200.0 
var last_anchor_pos := Vector2.ZERO
var last_mouse_pos := Vector2.ZERO
var grace_timer := 0.0

@onready var rope: Line2D = $Rope
@onready var target_line: Line2D = $TargetLine
@onready var target_reticle: Node2D = $TargetReticle
@onready var camera: Camera2D = $Camera2D
@onready var bg_material: ShaderMaterial = $"../CanvasLayer/Background".material

func _physics_process(delta: float) -> void:
	var mouse_vel = (get_viewport().get_mouse_position() - last_mouse_pos)
	last_mouse_pos = get_viewport().get_mouse_position()

	if Input.is_action_just_pressed("fire"): fire_hook()
	if Input.is_action_just_released("fire"): release_hook()

	var current_gravity = gravity
	if not is_hooked:
		grace_timer -= delta
		if grace_timer > 0 or velocity.y < 0:
			current_gravity *= fall_gravity_mult
	
	velocity.y += current_gravity * delta

	if is_hooked and is_instance_valid(hook_node):
		if hook_node.has_method("set_grabbed"):
			hook_node.set_grabbed()
			
		if hook_node.collision_layer == 0:
			is_hooked = false
			return
		
		grace_timer = grace_time 
		var anchor = hook_node.to_global(hook_offset)
		var anchor_vel = (anchor - last_anchor_pos) / delta
		last_anchor_pos = anchor

		if Input.is_action_pressed("extend"):
			target_rope_length = move_toward(target_rope_length, min_length, manual_reel_speed * delta)
		elif Input.is_action_pressed("retract"):
			target_rope_length = move_toward(target_rope_length, max_length, manual_reel_speed * delta)
		
		var prev_length = rope_length
		rope_length = move_toward(rope_length, target_rope_length, reel_speed * delta)
		
		var to_anchor = (anchor - global_position).normalized()
		var tangent = Vector2(-to_anchor.y, to_anchor.x)
		
		if rope_length < prev_length and velocity.length() > 10.0:
			velocity += tangent * (prev_length - rope_length) * 15.0

		velocity += tangent * mouse_vel.dot(tangent) * whip_power

		var dist = global_position.distance_to(anchor)
		if dist > rope_length:
			global_position += to_anchor * (dist - rope_length)
			
			var rel_vel = velocity - anchor_vel
			var dot = rel_vel.dot(to_anchor)
			if dot < 0:
				velocity = (rel_vel - to_anchor * dot) + anchor_vel
		
		rope.width = move_toward(rope.width, 4.0 + clamp(abs(mouse_vel.length() * 0.1), 0, 12), delta * 50)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 1.5)
		rope.width = move_toward(rope.width, 0, delta * 30)

	if velocity.length() > max_velocity:
		velocity = velocity.limit_length(max_velocity)

	move_and_slide()
	
	if bg_material:
		bg_material.set_shader_parameter("world_pos", camera.get_screen_center_position())

func fire_hook():
	var dir = global_position.direction_to(get_global_mouse_position())
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + dir * max_dist)
	query.exclude = [get_rid()]
	var res = get_world_2d().direct_space_state.intersect_ray(query)
	
	if res:
		is_hooked = true
		hook_node = res.collider
		hook_offset = hook_node.to_local(res.position)
		last_anchor_pos = res.position
		rope_length = global_position.distance_to(res.position)

func release_hook():
	if is_hooked:
		velocity *= release_boost
		grace_timer = grace_time
	is_hooked = false

func _process(delta: float) -> void:
	rope.visible = is_hooked
	if is_hooked and is_instance_valid(hook_node):
		rope.points = [Vector2.ZERO, to_local(hook_node.to_global(hook_offset))]
		target_line.visible = false
		target_reticle.visible = false
	else:
		update_preview_indicator(delta)

func update_preview_indicator(delta: float) -> void:
	var dir = global_position.direction_to(get_global_mouse_position())
	var ray_end = global_position + (dir * max_dist)
	var query = PhysicsRayQueryParameters2D.create(global_position, ray_end)
	query.exclude = [get_rid()]
	var res = get_world_2d().direct_space_state.intersect_ray(query)
	
	target_line.visible = true
	target_reticle.visible = true
	target_line.clear_points()
	target_line.add_point(Vector2.ZERO)
	
	var hit_pos = res.position if res else ray_end
	var local_hit = to_local(hit_pos)
	
	target_line.add_point(local_hit)
	target_reticle.position = local_hit
	
	var alpha = 0.6 if res else 0.1
	target_line.modulate.a = move_toward(target_line.modulate.a, alpha, delta * 4)
	target_reticle.modulate.a = move_toward(target_reticle.modulate.a, alpha, delta * 4)
	target_reticle.rotation += delta * (10.0 if res else 2.0)
