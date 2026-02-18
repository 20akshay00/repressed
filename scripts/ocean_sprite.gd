extends Node2D

@export var amp := 15.0
@export var wave_len := 700.0
@export var speed := 0.2
@export var width := 5000.0
@export var points := 100

var curve := []
var noise := FastNoiseLite.new()

func _ready():
	curve.resize(points)
	noise.seed = randi()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

func _process(_delta):
	var t = Time.get_ticks_msec() / 1000.0 * speed
	for i in range(points):
		var x = i * width / (points - 1) - width/2
		var phase = t + x / wave_len
		var y = amp * sin(phase * TAU)
		curve[i] = Vector2(x, y)

	var poly = curve.duplicate()
	poly.append(Vector2(width/2, 6000)) # bottom right
	poly.append(Vector2(-width/2, 6000))     # bottom left
	$Polygon2D.polygon = poly
	$Line2D.points = curve
