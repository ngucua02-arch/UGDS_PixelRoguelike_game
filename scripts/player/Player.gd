extends CharacterBody2D

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/Projectile.tscn")

@export var move_speed: float = 240.0
@export var max_health: int = 5
@export var fire_rate: float = 5.0
@export var projectile_damage: float = 1.0
@export var projectile_speed: float = 600.0
@export var muzzle_offset: float = 18.0

var health: int = 5
var fire_cooldown: float = 0.0


func _ready() -> void:
	health = max_health
	global_position = get_viewport_rect().size * 0.5


func _physics_process(_delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = movement * move_speed
	move_and_slide()


func _process(delta: float) -> void:
	var aim_direction := get_global_mouse_position() - global_position
	if not aim_direction.is_zero_approx():
		rotation = aim_direction.angle() + PI * 0.5

	if Input.is_action_pressed("fire"):
		var shot_interval := 1.0 / maxf(0.1, fire_rate)
		fire_cooldown -= delta
		while fire_cooldown <= 0.0:
			_fire(aim_direction)
			fire_cooldown += shot_interval
	else:
		fire_cooldown = 0.0


func _fire(aim_direction: Vector2) -> void:
	if aim_direction.is_zero_approx():
		return
	var shot_direction := aim_direction.normalized()
	var projectile := PROJECTILE_SCENE.instantiate()
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	scene_root.add_child(projectile)
	projectile.global_position = global_position + shot_direction * muzzle_offset
	projectile.call("launch", shot_direction, projectile_damage, projectile_speed)
