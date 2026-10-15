extends Area2D

@export var lifetime: float = 2.0
@export var viewport_margin: float = 32.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var speed: float = 600.0
var elapsed: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(launch_direction: Vector2, launch_damage: float, launch_speed: float) -> void:
	direction = launch_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	damage = maxf(0.0, launch_damage)
	speed = maxf(0.0, launch_speed)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	elapsed += delta
	if elapsed >= lifetime or _is_outside_viewport():
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()


func _is_outside_viewport() -> bool:
	var canvas_position := get_viewport().get_canvas_transform() * global_position
	var viewport_bounds := Rect2(Vector2.ZERO, get_viewport_rect().size).grow(viewport_margin)
	return not viewport_bounds.has_point(canvas_position)
