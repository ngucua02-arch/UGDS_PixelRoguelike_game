extends Node2D

const SHARD_COUNT: int = 6
const DURATION: float = 0.16
const BURST_DISTANCE: float = 20.0
const SHARD_COLORS: Array[Color] = [
	Color(0.25, 1.0, 0.9, 1.0),
	Color(1.0, 0.35, 0.7, 1.0),
	Color(1.0, 0.82, 0.25, 1.0),
]

var _elapsed: float = 0.0
var _shards: Array[Polygon2D] = []
var _directions: Array[Vector2] = []


func _ready() -> void:
	for index in range(SHARD_COUNT):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0)
		])
		shard.color = SHARD_COLORS[index % SHARD_COLORS.size()]
		add_child(shard)
		_shards.append(shard)
		var angle := TAU * float(index) / float(SHARD_COUNT)
		_directions.append(Vector2.from_angle(angle))


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	for index in range(_shards.size()):
		_shards[index].position = _directions[index] * lerpf(2.0, BURST_DISTANCE, progress)
		_shards[index].modulate.a = 1.0 - progress
	if progress >= 1.0:
		queue_free()
