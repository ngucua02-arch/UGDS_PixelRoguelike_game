extends Area2D

@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var speed: float = 250.0
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
	if elapsed >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.get("is_dead") == true:
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
	queue_free()
