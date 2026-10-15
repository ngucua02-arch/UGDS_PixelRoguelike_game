extends CharacterBody2D

@export var move_speed: float = 240.0
@export var max_health: int = 5

var health: int = 5


func _ready() -> void:
	health = max_health
	global_position = get_viewport_rect().size * 0.5


func _physics_process(_delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = movement * move_speed
	move_and_slide()


func _process(_delta: float) -> void:
	var aim_direction := get_global_mouse_position() - global_position
	if not aim_direction.is_zero_approx():
		rotation = aim_direction.angle() + PI * 0.5
