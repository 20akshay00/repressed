extends CharacterBody2D
class_name Eye

@export_group("Control")
@export var is_active := true : set = set_active
@export var passive_mode := false

@export_group("Settings")
@export var min_interval := 3.0
@export var gaze_duration := 1.2
@export var warning_duration := 1.5
@export var stun_duration := 4.0
@export var struggle_duration := 1.5
@export var iris_limit := 3.0
@export var player: Player

@export_group("Hover Settings")
@export var bob_speed := 2.5
@export var bob_amp := 40.0
@export var move_speed := 6.0 

var state := "IDLE"
var timer := 0.0
var time := 0.0
var side := -1.0
var gaze_dir := Vector2.ZERO
var original_layer := 1
var entrance_offset := Vector2.ZERO

var visual_tween: Tween
var current_visual_node: Node2D

@onready var visual: Polygon2D = $LightVisual
@onready var gaze_area = $GazeArea
@onready var collision_poly: CollisionPolygon2D = $GazeArea/CollisionPolygon2D

@onready var sprites_normal = $Sprites
@onready var sprites_enraged = $EnragedSprites
@onready var sprites_closed = $ClosedEyelids
@onready var aim_sfx = $AimSFX

func _ready() -> void:
	timer = min_interval
	original_layer = collision_layer
	visual.visible = false
	gaze_area.monitoring = false
	
	for s in [sprites_normal, sprites_enraged, sprites_closed]:
		s.modulate.a = 0.0
		s.visible = false

	var points = PackedVector2Array([Vector2.ZERO, Vector2(3000, 400), Vector2(3000, -400)])
	visual.polygon = points
	collision_poly.polygon = points
	
	if not is_active:
		modulate.a = 0.0
		entrance_offset = Vector2(2000 * side, 0)
		set_physics_process(false)
		hide()
	
	_update_visual_states()
	

func set_active(val: bool):
	is_active = val
	if not is_inside_tree(): return
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_active:
		set_physics_process(true)
		show()
		tween.tween_property(self, "modulate:a", 1.0, 1.0)
		tween.tween_property(self, "entrance_offset", Vector2.ZERO, 1.0)
	else:
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.tween_property(self, "entrance_offset", Vector2(2000 * side, 0), 1.0)
		tween.set_parallel(false)
		tween.tween_callback(func(): 
			set_physics_process(false)
			hide()
		)

func _physics_process(delta: float) -> void:
	time += delta
	var cam = get_viewport().get_camera_2d()
	if !cam or !player: return
	
	_update_visual_states()
	
	var current_iris = _get_active_iris()
	if current_iris:
		var to_player = global_position.direction_to(player.global_position)
		current_iris.position = current_iris.position.lerp(to_player * iris_limit, delta * 5.0)

	var cam_center = cam.get_screen_center_position()
	var bobbing = sin(time * bob_speed) * bob_amp

	match state:
		"IDLE", "STUNNED":
			if randf() < 0.008: side *= -1.0
			var target_pos = Vector2(cam_center.x + (220 * side), cam_center.y - 180 + bobbing) + entrance_offset
			velocity = (target_pos - global_position) * move_speed
		"STRUGGLE":
			velocity.y = 900.0
			velocity.x = (player.global_position.x - global_position.x) * 3.0
		"WARNING", "GAZE":
			var target_y = cam_center.y - 200 + bobbing
			velocity.y = (target_y - global_position.y) * move_speed
			velocity.x = lerp(velocity.x, 0.0, delta * 5.0)

	timer -= delta
	_update_state_logic()
	move_and_slide()

func _update_visual_states():
	var target: Node2D
	match state:
		"IDLE": target = sprites_normal
		"WARNING", "GAZE", "STRUGGLE": target = sprites_enraged
		"STUNNED": target = sprites_closed
	
	if target == current_visual_node: return
	current_visual_node = target
	
	if visual_tween: visual_tween.kill()
	visual_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	for s in [sprites_normal, sprites_enraged, sprites_closed]:
		if s == target:
			s.visible = true
			visual_tween.tween_property(s, "modulate:a", 1.0, 0.3)
		else:
			visual_tween.tween_property(s, "modulate:a", 0.0, 0.3)
	
	visual_tween.set_parallel(false)
	visual_tween.tween_callback(func():
		for s in [sprites_normal, sprites_enraged, sprites_closed]:
			if s != current_visual_node: s.visible = false
	)

func _get_active_iris():
	if not current_visual_node: return null
	return current_visual_node.get_node_or_null("Body/Iris")

func _update_state_logic():
	var dt = get_physics_process_delta_time()
	match state:
		"IDLE":
			collision_layer = original_layer
			visual.visible = false
			gaze_area.monitoring = false
			visual.scale = Vector2.ONE
			modulate = modulate.lerp(Color.WHITE, dt * 5.0)
			gaze_dir = global_position.direction_to(player.global_position)
			if timer <= 0 and is_active and not passive_mode:
				state = "WARNING"
				timer = warning_duration
		"WARNING":
			if not aim_sfx.playing: aim_sfx.play()
			visual.visible = true
			var to_player = global_position.direction_to(player.global_position)
			gaze_dir = gaze_dir.lerp(to_player, dt * 5.0).normalized()
			visual.rotation = gaze_dir.angle()
			visual.modulate.a = 0.4 + (sin(time * 40.0) * 0.3)
			visual.scale.y = 1.0 + sin(time * 50.0) * 0.1
			if timer <= 0:
				aim_sfx.stop()
				AudioManager.play_effect(AudioManager.eye_shoot_sfx)
				state = "GAZE"
				timer = gaze_duration
		"GAZE":
			gaze_area.monitoring = true
			visual.rotation = gaze_dir.angle()
			gaze_area.rotation = gaze_dir.angle()
			visual.scale.y = move_toward(visual.scale.y, 0.15, dt * 20.0)
			gaze_area.scale.y = visual.scale.y
			visual.modulate.a = 1.0
			for body in gaze_area.get_overlapping_bodies():
				if body == player and player.is_hooked:
					player.release_hook()
					player.velocity.y += 1500.0
			if timer <= 0:
				state = "IDLE"
				timer = min_interval
		"STRUGGLE":
			visual.visible = false
			modulate = Color(2.5, 0.4, 0.4, 1.0)
			if not player.is_hooked or player.hook_node != self:
				_end_struggle(false)
			elif timer <= 0:
				_end_struggle(true)
		"STUNNED":
			collision_layer = 0
			visual.visible = false
			gaze_area.monitoring = false
			modulate = modulate.lerp(Color(0.4, 0.4, 0.4, 0.8), dt * 5.0)
			if timer <= 0:
				state = "IDLE"
				timer = min_interval

func _end_struggle(success: bool):
	var ui = get_tree().get_first_node_in_group("ui")
	if ui: ui.set_nightmare(false)
	if success:
		state = "STUNNED"
		timer = stun_duration
		player.release_hook()
	else:
		state = "IDLE"
		timer = 1.5

func set_grabbed() -> void:
	if state != "STUNNED" and state != "STRUGGLE":
		state = "STRUGGLE"
		timer = struggle_duration
		var ui = get_tree().get_first_node_in_group("ui")
		if ui: ui.set_nightmare(true)
