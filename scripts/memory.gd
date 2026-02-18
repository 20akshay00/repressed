extends AnimatableBody2D

@export_group("Scripted Path")
@export var move_direction := Vector2(1, 0)
@export var amplitude := 300.0
@export var speed := 1.0 

@export_group("Drift Physics")
@export var friction := 0.95        
@export var return_strength := 1.5 

@export_group("Special Types")
@export var is_mirage := false
@export var is_timed := false
@export var break_time := 1.5

var time := 0.0
var initial_pos : Vector2
var drift_velocity := Vector2.ZERO
var rotation_accum := 0.0
var hook_timer := 0.0
var is_grabbed := false
var is_active := true
var tween: Tween

@onready var original_layer = collision_layer

func _ready() -> void:
	initial_pos = global_position
	modulate = Color.WHITE
	
	var mat = _get_mat()
	if mat:
		mat = mat.duplicate()
		_set_mat(mat)
		mat.set_shader_parameter("is_mirage_f", 1.0 if is_mirage else 0.0)
	
	if is_mirage: 
		collision_layer = 0
		original_layer = 0

func _get_mat() -> ShaderMaterial:
	if material is ShaderMaterial: return material
	for c in get_children():
		if c is CanvasItem and c.material is ShaderMaterial: return c.material
	return null

func _set_mat(mat: ShaderMaterial):
	if material is ShaderMaterial: material = mat
	for c in get_children():
		if c is CanvasItem and c.material is ShaderMaterial: c.material = mat

func _physics_process(delta: float) -> void:
	time += delta
	_update_timed_state(delta)
	
	var target = initial_pos + (move_direction.normalized() * sin(time * speed) * amplitude)
	drift_velocity = (drift_velocity + (target - global_position) * return_strength) * friction
	
	rotation_accum += delta
	global_transform = Transform2D(rotation_accum, global_position + (drift_velocity * delta))
	is_grabbed = false 

func _update_timed_state(delta: float) -> void:
	if !is_timed: return
	
	if !is_active:
		if is_grabbed: return
		hook_timer = move_toward(hook_timer, 0.0, delta * 0.5)
		modulate.a = lerp(0.0, 1.0, 1.0 - (hook_timer / break_time))
		if hook_timer <= 0:
			is_active = true
			collision_layer = original_layer
		return

	if is_grabbed:
		if tween: tween.kill()
		hook_timer = min(hook_timer + delta, break_time)
		modulate.a = 1.0 - (hook_timer / break_time) * 0.8
		if hook_timer >= break_time:
			is_active = false
			collision_layer = 0
			_play_fade(0.0, 0.1)
	else:
		hook_timer = move_toward(hook_timer, 0.0, delta * 0.8)
		modulate.a = 1.0 - (hook_timer / break_time) * 0.8

func _play_fade(target_a: float, duration: float) -> void:
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", target_a, duration)

func set_grabbed() -> void:
	if is_active: is_grabbed = true
