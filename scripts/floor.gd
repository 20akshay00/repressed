extends StaticBody2D

var active := false
@export var lvl := 1
@export var hue: Color

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.velocity.y < 0 or body.global_position.y > global_position.y:
			active = true
			EventManager.level_changed.emit(lvl, hue)
			AudioManager.play_effect(AudioManager.lvl_change_sfx)
		else:
			EventManager.level_changed.emit(lvl-1, hue)
