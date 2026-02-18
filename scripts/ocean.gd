extends Area2D

@onready var rect = $CollisionShape2D.shape
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if (body is Player):
		body.external_acceleration += gravity * gravity_direction

func _on_body_exited(body: Node2D) -> void:
	if (body is Player):
		body.external_acceleration -= gravity * gravity_direction
