@tool
extends AnimatableBody2D
class_name Memory

enum MemoryType { STANDARD, REPELLING }

@export_group("Settings")
@export var type: MemoryType = MemoryType.STANDARD :
	set(val):
		type = val
		queue_redraw()

@export var duration := 2.0
@export var rotation_speed := 1.0
@export var repel_force := 1500.0
@export var repel_radius := 350.0

var rotation_accum := randf() * TAU
var movement_tween: Tween
var notifier: VisibleOnScreenNotifier2D

func _ready():
	if Engine.is_editor_hint(): return
	
	_setup_visibility_optimization()
	_start_movement()

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func _setup_visibility_optimization():
	notifier = VisibleOnScreenNotifier2D.new()
	
	var target_node = get_node_or_null("Marker2D")
	# Fallback to a 200px box if no target or repel radius is set
	var max_dist = max(repel_radius, 200.0) 
	
	if target_node:
		max_dist = max(max_dist, target_node.position.length() + 100.0)
	
	notifier.rect = Rect2(-max_dist, -max_dist, max_dist * 2.0, max_dist * 2.0)
	
	notifier.screen_entered.connect(_on_screen_entered)
	notifier.screen_exited.connect(_on_screen_exited)
	add_child(notifier)
	
	if not notifier.is_on_screen():
		set_physics_process(false)

func _on_screen_entered():
	set_physics_process(true)
	if movement_tween:
		movement_tween.play()

func _on_screen_exited():
	set_physics_process(false)
	if movement_tween:
		movement_tween.pause()

func _start_movement():
	var target_node = get_node_or_null("Marker2D")
	if not target_node: return
	
	var start_pos = global_position
	var end_pos = target_node.global_position
	target_node.hide()
	
	movement_tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	movement_tween.tween_property(self, "global_position", end_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	movement_tween.tween_property(self, "global_position", start_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var random_phase = randf() * (duration * 2.0)
	movement_tween.custom_step(random_phase)
	
	if notifier and not notifier.is_on_screen():
		movement_tween.pause()

func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	# Rotation in-game
	rotation_accum += delta * rotation_speed
	rotation = rotation_accum
	
	if type == MemoryType.REPELLING:
		var player = get_tree().get_first_node_in_group("player")
		if player and "velocity" in player:
			var dist = global_position.distance_to(player.global_position)
			if dist < repel_radius:
				var dir = global_position.direction_to(player.global_position)
				var strength = (1.0 - (dist / repel_radius)) * repel_force
				player.velocity += dir * strength * delta

func _draw():
	if Engine.is_editor_hint():
		var target_node = get_node_or_null("Marker2D")
		if target_node:
			var color = Color.WHITE if type == MemoryType.STANDARD else Color.RED
			draw_line(Vector2.ZERO, to_local(target_node.global_position), color, 2.0)
			draw_circle(to_local(target_node.global_position), 5.0, color)

func _process(delta):
	if Engine.is_editor_hint():
		queue_redraw()

func set_grabbed():
	pass
