extends CharacterBody2D

signal died

@export var max_health: float = 4.0
@export var move_speed: float = 105.0
@export var contact_range: float = 34.0
@export var contact_damage: float = 1.0
@export var attack_interval: float = 1.0

var health: float = 4.0
var target: Node2D
var attack_cooldown: float = 0.0
var hit_flash_left: float = 0.0
var is_dead: bool = false

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_text: Label = $HealthText
@onready var body_visual: Polygon2D = $Body


func _ready() -> void:
	max_health = maxf(1.0, max_health)
	health = max_health
	add_to_group("room_enemies")
	_update_health_bar()


func set_target(player: Node2D) -> void:
	target = player


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if hit_flash_left > 0.0:
		hit_flash_left = maxf(0.0, hit_flash_left - delta)
		if hit_flash_left == 0.0:
			body_visual.color = Color(1.0, 0.22, 0.38, 1.0)

	if not is_instance_valid(target) or target.get("is_dead") == true:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > contact_range:
		velocity = offset.normalized() * move_speed
	else:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0 and target.has_method("take_damage"):
			target.call("take_damage", contact_damage)
			attack_cooldown = maxf(0.1, attack_interval)
	move_and_slide()


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_update_health_bar()
	body_visual.color = Color.WHITE
	hit_flash_left = 0.12
	if health <= 0.0:
		is_dead = true
		velocity = Vector2.ZERO
		died.emit()
		queue_free()


func _update_health_bar() -> void:
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
	if is_instance_valid(health_text):
		health_text.text = "生命 %d / %d" % [ceili(health), ceili(max_health)]
