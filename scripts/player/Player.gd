extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/Projectile.tscn")
const ItemDataScript = preload("res://resources/items/ItemData.gd")

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
var hit_flash_left: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO
var is_dead: bool = false
var damage_enabled: bool = true
var _applied_item_ids: Dictionary = {}
var _triple_shot: bool = false
var _pierce_count: int = 0
var _ricochet_range: float = 0.0
var _death_explosion_radius: float = 0.0
var _death_explosion_damage: float = 0.0


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
	if hit_flash_left > 0.0:
		hit_flash_left = maxf(0.0, hit_flash_left - delta)
		if hit_flash_left == 0.0:
			modulate = Color.WHITE

	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not is_dead and Input.is_action_just_pressed("dodge") and dodge_cooldown_left == 0.0 and dodge_time_left <= 0.0:
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
	if not damage_enabled or is_dead or dodge_time_left > 0.0 or amount <= 0.0:
		return

	health = maxi(0, health - maxi(1, roundi(amount)))
	modulate = Color(4.0, 0.55, 0.25, 1.0)
	hit_flash_left = 0.12
	health_changed.emit(health, max_health)
	if health == 0:
		is_dead = true
		died.emit()


func apply_item(item: ItemData) -> void:
	if item == null or item.id == &"" or _applied_item_ids.has(item.id):
		return
	_applied_item_ids[item.id] = true
	match item.effect_type:
		ItemDataScript.EffectType.TRIPLE_SHOT:
			_triple_shot = true
			projectile_damage = maxf(0.1, projectile_damage * clampf(item.value_primary, 0.1, 1.0))
		ItemDataScript.EffectType.PIERCE:
			_pierce_count += maxi(0, roundi(item.value_primary))
		ItemDataScript.EffectType.RICOCHET:
			_ricochet_range = maxf(_ricochet_range, maxf(0.0, item.value_primary))
		ItemDataScript.EffectType.FIRE_RATE:
			fire_rate = maxf(0.1, fire_rate * maxf(0.1, item.value_primary))
		ItemDataScript.EffectType.DAMAGE_SPEED:
			projectile_damage = maxf(0.1, projectile_damage * maxf(0.1, item.value_primary))
			projectile_speed = maxf(80.0, projectile_speed * maxf(0.1, item.value_secondary))
		ItemDataScript.EffectType.DODGE_COOLDOWN:
			var previous_cooldown := maxf(0.1, dodge_cooldown)
			dodge_cooldown = maxf(0.1, dodge_cooldown * maxf(0.1, item.value_primary))
			dodge_cooldown_left = maxf(0.0, dodge_cooldown_left * dodge_cooldown / previous_cooldown)
		ItemDataScript.EffectType.MAX_HEALTH_HEAL:
			var health_increase := maxi(0, roundi(item.value_primary))
			max_health += health_increase
			health = mini(max_health, health + maxi(0, roundi(item.value_secondary)))
			health_changed.emit(health, max_health)
		ItemDataScript.EffectType.DEATH_EXPLOSION:
			_death_explosion_radius = maxf(0.0, item.value_primary)
			_death_explosion_damage = maxf(0.0, item.value_secondary)


func apply_projectile_hit(target: Node2D, amount: float) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	var death_centers: Array[Vector2] = []
	_damage_enemy(target, amount, death_centers)
	while not death_centers.is_empty():
		var center: Vector2 = death_centers.pop_front()
		if _death_explosion_radius <= 0.0 or _death_explosion_damage <= 0.0:
			continue
		for enemy in get_tree().get_nodes_in_group("room_enemies"):
			if not is_instance_valid(enemy) or enemy.get("is_dead") == true:
				continue
			if enemy.global_position.distance_to(center) <= _death_explosion_radius:
				_damage_enemy(enemy, _death_explosion_damage, death_centers)


func _damage_enemy(enemy: Node2D, amount: float, death_centers: Array[Vector2]) -> void:
	if enemy.get("is_dead") == true:
		return
	var health_before: float = float(enemy.get("health"))
	enemy.call("take_damage", amount)
	if enemy.get("is_dead") == true or float(enemy.get("health")) <= 0.0:
		if health_before > 0.0:
			death_centers.append(enemy.global_position)


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
	if _triple_shot:
		for angle_degrees in [-12.0, 0.0, 12.0]:
			_spawn_projectile(shot_direction.rotated(deg_to_rad(angle_degrees)))
	else:
		_spawn_projectile(shot_direction)


func _spawn_projectile(shot_direction: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var projectile := PROJECTILE_SCENE.instantiate()
	scene_root.add_child(projectile)
	projectile.global_position = global_position + shot_direction * muzzle_offset
	projectile.call("launch", shot_direction, projectile_damage, projectile_speed, self, _pierce_count, _ricochet_range)
