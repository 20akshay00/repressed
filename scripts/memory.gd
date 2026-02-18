extends AnimatableBody2D
class_name Memory

@export var move_direction := Vector2.ZERO
@export var amplitude := 300.0
@export var speed := 0.4
@export var smooth_speed := 3.0
@export var prob_mirage := 0.2
@export var prob_timed := 0.2
@export var break_time := 4.5

var is_mirage := false
var is_timed := false
var is_active := true
var is_grabbed := false
var time := randf() * 100.0
var rotation_accum := randf() * TAU
var hook_timer := 0.0

@onready var initial_pos := global_position
@onready var current_pos := global_position
@onready var init_scale := scale
@onready var original_layer := collision_layer

func _ready():
	if move_direction == Vector2.ZERO: 
		move_direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	var roll = randf()
	is_mirage = roll < prob_mirage
	is_timed = !is_mirage and roll < (prob_mirage + prob_timed)
	
	_setup_material()
	
	if is_mirage:
		collision_layer = 0
		original_layer = 0

func _setup_material():
	var target_node: CanvasItem = self
	var mat = material as ShaderMaterial
	
	if !mat:
		for c in get_children():
			if c is CanvasItem and c.material is ShaderMaterial:
				target_node = c
				mat = c.material
				break
	
	if !mat: return
	
	var new_mat = mat.duplicate()
	target_node.material = new_mat
	new_mat.set_shader_parameter("is_mirage_f", 1.0 if is_mirage else 0.0)

func _physics_process(delta):
	time += delta
	_process_timed_logic(delta)
	
	var target = initial_pos + (move_direction.normalized() * sin(time * speed) * amplitude)
	current_pos = current_pos.lerp(target, delta * smooth_speed)
	
	rotation_accum += delta
	global_transform = Transform2D(rotation_accum, current_pos).scaled(init_scale)
	is_grabbed = false

func _process_timed_logic(delta):
	if not is_timed: return
	
	if not is_active:
		hook_timer = move_toward(hook_timer, 0.0, delta * 0.5)
		modulate.a = 1.0 - (hook_timer / break_time)
		if hook_timer <= 0:
			is_active = true
			collision_layer = original_layer
		return

	if is_grabbed:
		hook_timer = min(hook_timer + delta, break_time)
		if hook_timer >= break_time:
			is_active = false
			collision_layer = 0
			modulate.a = 0
	else:
		hook_timer = move_toward(hook_timer, 0.0, delta * 0.8)
	
	if is_active:
		modulate.a = 1.0 - (hook_timer / break_time) * 0.8

func set_grabbed():
	if is_active: is_grabbed = true
