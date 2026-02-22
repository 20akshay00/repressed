extends CanvasItem

func _ready() -> void:
	EventManager.level_changed.connect(_on_level_changed)
	
func _on_level_changed(lvl: int, hue: Color) -> void:
	
	pass
