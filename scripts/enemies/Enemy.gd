extends CharacterBody2D

signal died

const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/EnemyProjectile.tscn")
const RANGED_KEEP_DISTANCE: float = 220.0
const RANGED_DISTANCE_TOLERANCE: float = 28.0
const RANGED_TELEGRAPH_TIME: float = 0.75

@export var max_health: float = 4.0
@export var move_speed: float = 105.0
@export var contact_range: float = 34.0
@export var contact_damage: float = 1.0
@export var attack_interval: float = 1.0
@export var is_ranged: bool = false
@export var ranged_move_speed: float = 90.0
@export var ranged_projectile_speed: float = 250.0
@export var ranged_projectile_damage: float = 1.0

var health: float = 4.0
var target: Node2D
var attack_cooldown: float = 0.0
var telegraph_left: float = 0.0
var telegraph_direction: Vector2 = Vector2.RIGHT
var hit_flash_left: float = 0.0
var is_dead: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_text: Label = $HealthText
@onready var melee_visual: Polygon2D = $MeleeBody
@onready var ranged_visual: Polygon2D = $RangedBody
@onready var telegraph_line: Line2D = $AttackTelegraph


func _ready() -> void:
	max_health = maxf(1.0, max_health)
	health = max_health
	add_to_group("room_enemies")
	melee_visual.visible = not is_ranged
	ranged_visual.visible = is_ranged
	telegraph_line.visible = false
	_update_health_bar()


func set_target(player: Node2D) -> void:
	target = player


func set_ranged_mode(ranged: bool) -> void:
	is_ranged = ranged
	if is_node_ready():
		melee_visual.visible = not is_ranged
		ranged_visual.visible = is_ranged
		_cancel_telegraph()
		_restore_body_color()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if hit_flash_left > 0.0:
		hit_flash_left = maxf(0.0, hit_flash_left - delta)
		if hit_flash_left == 0.0:
			_restore_body_color()

	if not is_instance_valid(target) or target.get("is_dead") == true:
		velocity = Vector2.ZERO
		_cancel_telegraph()
		move_and_slide()
		return

	if is_ranged:
		_process_ranged(delta)
	else:
		_process_melee()
	move_and_slide()


func _process_melee() -> void:
	_cancel_telegraph()
	var offset := target.global_position - global_position
	if offset.length() > contact_range:
		velocity = offset.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0 and target.has_method("take_damage"):
			target.call("take_damage", contact_damage)
			attack_cooldown = maxf(0.1, attack_interval)


func _process_ranged(delta: float) -> void:
	var offset := target.global_position - global_position
	var distance := offset.length()
	if telegraph_left > 0.0:
		velocity = Vector2.ZERO
		telegraph_left = maxf(0.0, telegraph_left - delta)
		if distance > 0.001:
			telegraph_direction = offset.normalized()
		_update_telegraph()
		if telegraph_left == 0.0:
			_fire_ranged(telegraph_direction)
			attack_cooldown = maxf(0.1, attack_interval)
			_cancel_telegraph()
		return

	if distance < RANGED_KEEP_DISTANCE - RANGED_DISTANCE_TOLERANCE:
		velocity = -offset.normalized() * ranged_move_speed
	elif distance > RANGED_KEEP_DISTANCE + RANGED_DISTANCE_TOLERANCE:
		velocity = offset.normalized() * ranged_move_speed
	else:
		velocity = Vector2.ZERO

	if attack_cooldown <= 0.0:
		telegraph_left = RANGED_TELEGRAPH_TIME
		telegraph_direction = offset.normalized() if distance > 0.001 else Vector2.RIGHT
		_update_telegraph()


func _update_telegraph() -> void:
	telegraph_line.visible = true
	telegraph_line.points = PackedVector2Array([Vector2.ZERO, telegraph_direction * 360.0])


func _cancel_telegraph() -> void:
	telegraph_left = 0.0
	if is_instance_valid(telegraph_line):
		telegraph_line.visible = false


func _fire_ranged(direction: Vector2) -> void:
	if direction.is_zero_approx() or not is_instance_valid(get_parent()):
		return
	var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + direction.normalized() * 20.0
	projectile.call("launch", direction, ranged_projectile_damage, ranged_projectile_speed)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_update_health_bar()
	_set_body_color(Color.WHITE)
	hit_flash_left = 0.12
	if health <= 0.0:
		is_dead = true
		_cancel_telegraph()
		velocity = Vector2.ZERO
		died.emit()
		queue_free()


func _restore_body_color() -> void:
	_set_body_color(Color(0.20, 0.96, 1.0, 1.0) if is_ranged else Color(1.0, 0.22, 0.38, 1.0))


func _set_body_color(color: Color) -> void:
	melee_visual.color = color
	ranged_visual.color = color


func _update_health_bar() -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
	if is_instance_valid(health_text):
		health_text.text = "生命 %d / %d" % [ceili(health), ceili(max_health)]
