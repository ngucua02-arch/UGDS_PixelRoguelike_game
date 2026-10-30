extends CharacterBody2D

signal died

const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/EnemyProjectile.tscn")
const CHARACTER_SHEET: Texture2D = preload("res://art/generated/characters_sprite_sheet_chromakey.png")
const CHROMA_KEY_SHADER: Shader = preload("res://shaders/sprite_chroma_key.gdshader")
const RANGED_KEEP_DISTANCE: float = 220.0
const RANGED_DISTANCE_TOLERANCE: float = 28.0
const RANGED_TELEGRAPH_TIME: float = 0.75

enum Archetype { MELEE, RANGED, CHARGER, BURST_RANGED }

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
var archetype: Archetype = Archetype.MELEE
var _attack_state: StringName = &"approach"
var _state_time: float = 0.0
var _locked_direction: Vector2 = Vector2.RIGHT
var _dash_hit_target: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_text: Label = $HealthText
@onready var melee_visual: Polygon2D = $MeleeBody
@onready var ranged_visual: Polygon2D = $RangedBody
@onready var telegraph_line: Line2D = $AttackTelegraph
@onready var melee_outline: Line2D = $MeleeOutline
@onready var ranged_outline: Line2D = $RangedOutline
@onready var character_sprite: Sprite2D = $CharacterSprite


func _ready() -> void:
	max_health = maxf(1.0, max_health)
	health = max_health
	add_to_group("room_enemies")
	archetype = Archetype.RANGED if is_ranged else Archetype.MELEE
	character_sprite.texture = CHARACTER_SHEET
	var sprite_material := ShaderMaterial.new()
	sprite_material.shader = CHROMA_KEY_SHADER
	character_sprite.material = sprite_material
	_update_archetype_visuals()
	telegraph_line.visible = false
	_update_health_bar()


func set_target(player: Node2D) -> void:
	target = player


func set_ranged_mode(ranged: bool) -> void:
	configure_archetype(Archetype.RANGED if ranged else Archetype.MELEE)


func configure_archetype(type: int) -> void:
	archetype = clampi(type, Archetype.MELEE, Archetype.BURST_RANGED) as Archetype
	is_ranged = archetype in [Archetype.RANGED, Archetype.BURST_RANGED]
	if is_node_ready():
		_update_archetype_visuals()
		_cancel_telegraph()
		_restore_body_color()


func _update_archetype_visuals() -> void:
	# Polygon placeholders must remain hidden; archetype switching used to
	# re-enable these nodes and cover the imported pixel-art sprite.
	melee_visual.visible = false
	ranged_visual.visible = false
	melee_outline.visible = false
	ranged_outline.visible = false
	match archetype:
		Archetype.MELEE:
			character_sprite.region_rect = Rect2(390, 105, 420, 450)
			character_sprite.scale = Vector2(0.10, 0.10)
		Archetype.RANGED:
			character_sprite.region_rect = Rect2(830, 130, 300, 415)
			character_sprite.scale = Vector2(0.13, 0.13)
		Archetype.CHARGER:
			character_sprite.region_rect = Rect2(1180, 75, 450, 500)
			character_sprite.scale = Vector2(0.095, 0.095)
		Archetype.BURST_RANGED:
			character_sprite.region_rect = Rect2(1600, 70, 450, 510)
			character_sprite.scale = Vector2(0.10, 0.10)
	var body_color := _archetype_color()
	melee_visual.color = body_color
	ranged_visual.color = body_color
	melee_outline.default_color = body_color.darkened(0.82)
	ranged_outline.default_color = body_color.darkened(0.82)


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

	match archetype:
		Archetype.MELEE:
			_process_melee()
		Archetype.RANGED:
			_process_ranged(delta)
		Archetype.CHARGER:
			_process_charger(delta)
		Archetype.BURST_RANGED:
			_process_burst_ranged(delta)
	move_and_slide()
	if archetype == Archetype.CHARGER and _attack_state == &"charging":
		_check_charger_collision()
		if get_slide_collision_count() > 0 or _state_time <= 0.0:
			velocity = Vector2.ZERO
			_attack_cooldown_after_special()
			_enter_state(&"recovery", 0.72)


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
		telegraph_line.default_color = Color(1.0, 0.68, 0.18, 0.58)
		_update_telegraph()


func _process_charger(delta: float) -> void:
	var offset := target.global_position - global_position
	var distance := offset.length()
	match _attack_state:
		&"approach":
			if distance > 150.0:
				velocity = offset.normalized() * move_speed * 1.25
			elif attack_cooldown <= 0.0:
				velocity = Vector2.ZERO
				_locked_direction = offset.normalized() if distance > 0.001 else Vector2.RIGHT
				_dash_hit_target = false
				_enter_state(&"warning", 0.58)
				_update_charger_telegraph(Color(1.0, 0.72, 0.18, 0.72))
			else:
				velocity = offset.normalized() * move_speed * 0.55
		&"warning":
			velocity = Vector2.ZERO
			_state_time -= delta
			_update_charger_telegraph(Color(1.0, 0.72, 0.18, 0.72))
			if _state_time <= 0.0:
				_enter_state(&"charging", 0.34)
		&"charging":
			_state_time -= delta
			velocity = _locked_direction * 560.0
		&"recovery":
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				_enter_state(&"approach", 0.0)


func _process_burst_ranged(delta: float) -> void:
	var offset := target.global_position - global_position
	var distance := offset.length()
	if telegraph_left > 0.0:
		velocity = Vector2.ZERO
		telegraph_left = maxf(0.0, telegraph_left - delta)
		if distance > 0.001:
			telegraph_direction = offset.normalized()
		_update_telegraph()
		if telegraph_left == 0.0:
			_fire_burst(telegraph_direction)
			attack_cooldown = 1.8
			_cancel_telegraph()
		return
	if distance < RANGED_KEEP_DISTANCE - RANGED_DISTANCE_TOLERANCE:
		velocity = -offset.normalized() * ranged_move_speed
	elif distance > RANGED_KEEP_DISTANCE + RANGED_DISTANCE_TOLERANCE:
		velocity = offset.normalized() * ranged_move_speed
	else:
		velocity = Vector2.ZERO
	if attack_cooldown <= 0.0:
		telegraph_left = 0.62
		telegraph_direction = offset.normalized() if distance > 0.001 else Vector2.RIGHT
		telegraph_line.default_color = Color(0.78, 0.38, 1.0, 0.72)
		_update_telegraph()


func _update_telegraph() -> void:
	telegraph_line.visible = true
	telegraph_line.points = PackedVector2Array([Vector2.ZERO, telegraph_direction * 360.0])


func _update_charger_telegraph(color: Color) -> void:
	telegraph_line.visible = true
	telegraph_line.default_color = color
	telegraph_line.points = PackedVector2Array([Vector2.ZERO, _locked_direction * 300.0])


func _enter_state(state: StringName, duration: float) -> void:
	_attack_state = state
	_state_time = duration
	telegraph_line.visible = state == &"warning"


func _attack_cooldown_after_special() -> void:
	attack_cooldown = 1.0


func _check_charger_collision() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if collision.get_collider() == target and not _dash_hit_target:
			_dash_hit_target = true
			if target.has_method("take_damage"):
				target.call("take_damage", contact_damage)


func _fire_burst(direction: Vector2) -> void:
	if not is_instance_valid(get_parent()):
		return
	for angle_degrees in [-18.0, 0.0, 18.0]:
		var projectile := ENEMY_PROJECTILE_SCENE.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position + direction.rotated(deg_to_rad(angle_degrees)) * 20.0
		projectile.call("launch", direction.rotated(deg_to_rad(angle_degrees)), ranged_projectile_damage, ranged_projectile_speed * 0.9)


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
	_set_body_color(_archetype_color())


func _archetype_color() -> Color:
	match archetype:
		Archetype.RANGED:
			return Color(0.20, 0.96, 1.0, 1.0)
		Archetype.CHARGER:
			return Color(1.0, 0.70, 0.18, 1.0)
		Archetype.BURST_RANGED:
			return Color(0.77, 0.40, 1.0, 1.0)
		_:
			return Color(1.0, 0.22, 0.38, 1.0)


func _set_body_color(color: Color) -> void:
	melee_visual.color = color
	ranged_visual.color = color
	if is_instance_valid(character_sprite):
		character_sprite.modulate = color


func _update_health_bar() -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
	if is_instance_valid(health_text):
		health_text.text = "生命 %d / %d" % [ceili(health), ceili(max_health)]
