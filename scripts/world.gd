extends Node2D

@export var eye: Node2D 
@onready var title = $Title
var idle_tween: Tween

func _ready():
	_start_idle_animation()
	EventManager.level_changed.connect(_on_level_changed)

func _start_idle_animation():
	if not is_instance_valid(title):
		return
		
	idle_tween = create_tween().set_loops().bind_node(title)
	idle_tween.tween_property(title, "scale", Vector2(1.05, 1.05), 1.1).set_trans(Tween.TRANS_SINE)
	idle_tween.tween_property(title, "scale", Vector2(0.95, 0.95), 1.1).set_trans(Tween.TRANS_SINE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		remove_title()

func remove_title():
	if not is_instance_valid(title):
		return
	
	if idle_tween:
		idle_tween.kill()
		
	var exit_tween = create_tween().set_parallel(true).bind_node(title)
	
	exit_tween.tween_property(title, "modulate:a", 0.0, 0.4)
	exit_tween.tween_property(title, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	exit_tween.set_parallel(false)
	exit_tween.tween_callback(title.queue_free)

	
func _on_level_changed(lvl: int, hue: Color) -> void:
	if lvl > 4:
		eye.is_active = true
		eye.passive_mode = true
		if lvl > 5:
			eye.passive_mode = false
	else:
		eye.is_active = false
