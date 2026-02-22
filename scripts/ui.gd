extends CanvasLayer

@onready var score_label := $ScoreLabel
@onready var high_score_label := $HighScoreLabel 
@onready var material = $ColorRect.material
@onready var level_label = $LevelLabel

@export var player: Player
@export var climb_distance := 10000.0
@export var start_color: Color = Color.WHITE
@export var target_color: Color = Color.BLUE

var start_y := 0.0
var score: int = 0
var high_score: int = 0
var invert_target := 0.0
var level_tween: Tween = null
var lvl_names := [
	"First Cut",
	"Long Shot",
	"Choking Hazard",
	"Soft Spot",
	"Cold Cuts",
	"Sweet Ache",
	"Deadbeat",
	"Entrapped",
	"Freedom"
]

func _ready() -> void:
	EventManager.level_changed.connect(_on_level_changed)
	add_to_group("ui")
	if is_instance_valid(player):
		start_y = player.global_position.y
	
	_on_level_changed(1, Color(0., 0., 0.))
	
func set_nightmare(active: bool) -> void:
	invert_target = 1.0 if active else 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	
	score = int((start_y - player.global_position.y) / 10.0)
	if score < 0: score = 0
	score_label.text = "%d" % score
	
	if score > high_score:
		high_score = score
		high_score_label.text = "%d" % high_score
	
	var world = clamp((start_y - player.global_position.y) / climb_distance, 0.0, 1.0)
	var current_color = start_color.lerp(target_color, world)
	
	if material is ShaderMaterial:
		material.set_shader_parameter("shift_color", current_color)
		
		var cur_inv = material.get_shader_parameter("invert_amount")
		var next_inv = move_toward(cur_inv, invert_target, delta * 3.0)
		material.set_shader_parameter("invert_amount", next_inv)

func _on_level_changed(lvl: int, hue: Color):
	level_label.pivot_offset = level_label.size / 2
	level_label.scale = Vector2.ONE
	
	if level_tween: level_tween.kill()
	level_tween = get_tree().create_tween()
	level_tween.tween_property(level_label, "scale", Vector2(1.2, 1.2), 0.2)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	level_tween.tween_callback(func(): level_label.text = lvl_names[lvl-1])
	level_tween.tween_property(level_label, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
