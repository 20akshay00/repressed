extends Node2D

@export var search_interval := 5.0
@export var warning_duration := 1.5
@export var search_duration := 3.0
@export var push_force := 5000.0
@export var follow_speed := 1.5
@export var iris_limit := 100.0

var state := "CLOSED"
var timer := 0.0
var time := 0.0

@onready var beacon = $Beacon
@onready var ray = $RayCast2D
@onready var visual = $LightVisual
@onready var iris = $Sprites/Body/Iris
@export var player: Player

func _ready() -> void:
	timer = search_interval
	visual.visible = false

func _process(delta: float) -> void:
	time += delta
	var cam = get_viewport().get_camera_2d()
	if !cam: return
	
	global_position.y = lerp(global_position.y, cam.get_screen_center_position().y - 150, follow_speed * delta)
	global_position.x = cam.get_screen_center_position().x - 350

	if player:
		var dir = global_position.direction_to(player.global_position)
		iris.position = iris.position.lerp(dir * iris_limit, delta * 5.0)

	timer -= delta
	match state:
		"CLOSED":
			if timer <= 0:
				state = "WARNING"
				timer = warning_duration
				visual.visible = true
				visual.modulate.a = 0.2
		"WARNING":
			visual.modulate.a = 0.2 + (sin(Time.get_ticks_msec() * 0.02) * 0.1)
			if timer <= 0:
				state = "SEARCHING"
				timer = search_duration
				visual.modulate.a = 0.7
		"SEARCHING":
			beacon.rotation = sin(time * 2.0) * 0.4
			for body in beacon.get_overlapping_bodies():
				if body is CharacterBody2D:
					ray.target_position = ray.to_local(body.global_position)
					ray.force_raycast_update()
					if ray.get_collider() == body:
						body.velocity.y += push_force * delta
			if timer <= 0:
				state = "CLOSED"
				timer = search_interval
				visual.visible = false
