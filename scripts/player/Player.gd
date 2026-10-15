extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/Projectile.tscn")

@export var move_speed: float = 240.0
@export var max_health: int = 5
@export var dodge_speed: float = 720.0
@export var dodge_duration: float = 0.18
@export var dodge_cooldown: float = 0.8
@export var fire_rate: float = 5.0
@export var projectile_damage: float = 1.0
@export var projectile_speed: float = 600.0
@export var muzzle_offset: float = 18.0

var health: int = 5
var fire_cooldown: float = 0.0
var dodge_time_left: float = 0.0
var dodge_cooldown_left: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO
var is_dead: bool = false


func _ready() -> void:
	max_health = maxi(1, max_health)
	health = max_health
	global_position = get_viewport_rect().size * 0.5
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	if dodge_time_left > 0.0:
		dodge_time_left = maxf(0.0, dodge_time_left - delta)
		if dodge_time_left == 0.0:
			modulate = Color.WHITE

	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not is_dead and Input.is_action_just_pressed("dodge") and dodge_cooldown_left == 0.0:
		_start_dodge(movement)

	if is_dead:
		velocity = Vector2.ZERO
	elif dodge_time_left > 0.0:
		velocity = dodge_direction * dodge_speed
	else:
		velocity = movement * move_speed
	move_and_slide()


func _process(delta: float) -> void:
	var aim_direction := get_global_mouse_position() - global_position
	if not aim_direction.is_zero_approx():
		rotation = aim_direction.angle() + PI * 0.5

	if not is_dead and Input.is_action_pressed("fire"):
		var shot_interval := 1.0 / maxf(0.1, fire_rate)
		fire_cooldown -= delta
		while fire_cooldown <= 0.0:
			_fire(aim_direction)
			fire_cooldown += shot_interval
	else:
		fire_cooldown = 0.0


func take_damage(amount: float) -> void:
	if is_dead or dodge_time_left > 0.0 or amount <= 0.0:
		return

	health = maxi(0, health - maxi(1, roundi(amount)))
	health_changed.emit(health, max_health)
	if health == 0:
		is_dead = true
		died.emit()


func _start_dodge(movement: Vector2) -> void:
	if dodge_duration <= 0.0:
		return
	dodge_direction = movement
	if dodge_direction.is_zero_approx():
		dodge_direction = Vector2.RIGHT.rotated(rotation - PI * 0.5)
	if dodge_direction.is_zero_approx():
		dodge_direction = Vector2.RIGHT
	dodge_direction = dodge_direction.normalized()
	dodge_time_left = dodge_duration
	dodge_cooldown_left = maxf(0.0, dodge_cooldown)
	modulate = Color(0.35, 0.9, 1.0, 0.55)


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
