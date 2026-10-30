extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/EnemyProjectile.tscn")

@export var max_health: float = 40.0
@export var fan_projectile_speed: float = 320.0
@export var fan_projectile_damage: float = 1.0
@export var charge_speed: float = 520.0
@export var charge_damage: float = 1.0
@export var charge_telegraph_duration: float = 0.7

var health: float = 40.0
var target: Node2D
var is_dead: bool = false
var _attack_state: StringName = &"fan_warning"
var _state_time: float = 0.0
var _aim_direction: Vector2 = Vector2.RIGHT
var _charge_direction: Vector2 = Vector2.RIGHT
var _charge_hit_player: bool = false
var _hit_flash_left: float = 0.0

@onready var character_sprite: Sprite2D = $CharacterSprite
@onready var attack_telegraph: Line2D = $AttackTelegraph
@onready var fan_telegraph: Line2D = $FanTelegraph

var _visual_clock: float = 0.0
var _base_sprite_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	max_health = maxf(1.0, max_health)
	health = max_health
	_state_time = 0.65
	add_to_group("room_enemies")
	_base_sprite_scale = character_sprite.scale
	attack_telegraph.visible = false
	fan_telegraph.visible = _attack_state == &"fan_warning"
	health_changed.emit(ceili(health), ceili(max_health))


func set_target(player: Node2D) -> void:
	target = player


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _hit_flash_left > 0.0:
		_hit_flash_left = maxf(0.0, _hit_flash_left - delta)
		if _hit_flash_left == 0.0:
				character_sprite.modulate = Color.WHITE
	if not is_instance_valid(target) or target.get("is_dead") == true:
		velocity = Vector2.ZERO
		_update_boss_visual(delta)
		move_and_slide()
		return
	match _attack_state:
		&"fan_warning":
			velocity = Vector2.ZERO
			_state_time -= delta
			_update_aim()
			_update_telegraph(280.0, Color(1.0, 0.3, 0.55, 0.9))
			_update_fan_telegraph()
			if _state_time <= 0.0:
				_fire_fan()
				_enter_state(&"fan_recovery", 0.95)
		&"fan_recovery":
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_update_aim()
				_charge_direction = _aim_direction
				_charge_hit_player = false
				_enter_state(&"charge_warning", charge_telegraph_duration)
		&"charge_warning":
			velocity = Vector2.ZERO
			_state_time -= delta
			_update_telegraph(460.0, Color(1.0, 0.75, 0.2, 0.95))
			if _state_time <= 0.0:
				_enter_state(&"charging", 0.9)
		&"charging":
			velocity = _charge_direction * charge_speed
			_state_time -= delta
			move_and_slide()
			_check_charge_collision()
			if get_slide_collision_count() > 0 or _state_time <= 0.0:
				velocity = Vector2.ZERO
				_enter_state(&"charge_recovery", 1.0)
			_update_boss_visual(delta)
			return
		&"charge_recovery":
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_enter_state(&"fan_warning", 0.65)
	_update_boss_visual(delta)
	move_and_slide()


func _update_aim() -> void:
	var offset := target.global_position - global_position
	if offset.length_squared() > 0.001:
		_aim_direction = offset.normalized()


func _enter_state(state: StringName, duration: float) -> void:
	_attack_state = state
	_state_time = maxf(0.0, duration)
	attack_telegraph.visible = state == &"fan_warning" or state == &"charge_warning"
	fan_telegraph.visible = state == &"fan_warning"


func _update_telegraph(length: float, color: Color) -> void:
	attack_telegraph.visible = true
	attack_telegraph.default_color = color
	var direction := _aim_direction if _attack_state == &"fan_warning" else _charge_direction
	attack_telegraph.points = PackedVector2Array([Vector2.ZERO, direction * length])


func _update_fan_telegraph() -> void:
	var points := PackedVector2Array()
	for angle_degrees in [-40.0, -20.0, 20.0, 40.0]:
		points.append(Vector2.ZERO)
		points.append(_aim_direction.rotated(deg_to_rad(angle_degrees)) * 280.0)
	fan_telegraph.points = points


func _update_boss_visual(delta: float) -> void:
	_visual_clock += delta
	var facing := _aim_direction
	if _attack_state in [&"charge_warning", &"charging", &"charge_recovery"]:
		facing = _charge_direction
	var target_rotation := facing.angle() - PI * 0.5
	var pose_scale := Vector2.ONE
	var pulse := 1.0 + sin(_visual_clock * 2.8) * 0.025
	var bob := sin(_visual_clock * 2.8) * 1.5
	match _attack_state:
		&"fan_warning":
			pulse += absf(sin(_visual_clock * 17.0)) * 0.055
		&"charge_warning":
			pulse += absf(sin(_visual_clock * 22.0)) * 0.04
			pose_scale = Vector2(1.08, 0.88)
		&"charging":
			pose_scale = Vector2(0.9, 1.2)
			bob = 0.0
		&"fan_recovery", &"charge_recovery":
			pose_scale = Vector2(1.08, 0.94)
			bob = sin(_visual_clock * 18.0) * 1.0
	character_sprite.rotation = lerp_angle(character_sprite.rotation, target_rotation, clampf(delta * 12.0, 0.0, 1.0))
	character_sprite.scale = character_sprite.scale.lerp(_base_sprite_scale * pose_scale * pulse, clampf(delta * 10.0, 0.0, 1.0))
	character_sprite.position.y = bob


func _fire_fan() -> void:
	if not is_instance_valid(get_parent()):
		return
	for angle_degrees in [-40.0, -20.0, 0.0, 20.0, 40.0]:
		var direction := _aim_direction.rotated(deg_to_rad(angle_degrees))
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position + direction * 32.0
		projectile.call("launch", direction, fan_projectile_damage, fan_projectile_speed)


func _check_charge_collision() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if collision.get_collider() == target and not _charge_hit_player:
			_charge_hit_player = true
			if target.has_method("take_damage"):
				target.call("take_damage", charge_damage)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(ceili(health), ceili(max_health))
	character_sprite.modulate = Color(2.7, 2.7, 3.0, 1.0)
	_hit_flash_left = 0.1
	if health <= 0.0:
		is_dead = true
		velocity = Vector2.ZERO
		attack_telegraph.visible = false
		died.emit()
		queue_free()
