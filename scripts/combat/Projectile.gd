extends Area2D

@export var lifetime: float = 2.0
@export var viewport_margin: float = 32.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var speed: float = 600.0
var elapsed: float = 0.0
var owner_player: Node2D
var remaining_pierces: int = 0
var ricochet_range: float = 0.0
var has_ricocheted: bool = false
var splash_radius: float = 0.0
var splash_damage: float = 0.0
var chain_range: float = 0.0
var chain_damage: float = 0.0
var hit_instance_ids: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(launch_direction: Vector2, launch_damage: float, launch_speed: float, launch_owner: Node2D = null, pierces: int = 0, ricochet_distance: float = 0.0, launch_splash_radius: float = 0.0, launch_splash_damage: float = 0.0, launch_chain_range: float = 0.0, launch_chain_damage: float = 0.0) -> void:
	direction = launch_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	damage = maxf(0.0, launch_damage)
	speed = maxf(0.0, launch_speed)
	owner_player = launch_owner
	remaining_pierces = maxi(0, pierces)
	ricochet_range = maxf(0.0, ricochet_distance)
	splash_radius = maxf(0.0, launch_splash_radius)
	splash_damage = maxf(0.0, launch_splash_damage)
	chain_range = maxf(0.0, launch_chain_range)
	chain_damage = maxf(0.0, launch_chain_damage)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	elapsed += delta
	if elapsed >= lifetime or _is_outside_viewport():
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	var instance_id := body.get_instance_id()
	if hit_instance_ids.has(instance_id):
		return
	hit_instance_ids[instance_id] = true
	if is_instance_valid(owner_player) and owner_player.has_method("apply_projectile_hit"):
		owner_player.call("apply_projectile_hit", body, damage, splash_radius, splash_damage, chain_range, chain_damage)
	else:
		body.call("take_damage", damage)
	if not has_ricocheted and ricochet_range > 0.0:
		var next_target := _find_ricochet_target(body)
		if is_instance_valid(next_target):
			has_ricocheted = true
			direction = (next_target.global_position - global_position).normalized()
			rotation = direction.angle()
			return
	if remaining_pierces > 0:
		remaining_pierces -= 1
		return
	queue_free()


func _find_ricochet_target(hit_body: Node2D) -> Node2D:
	var nearest: Node2D
	var nearest_distance := ricochet_range
	for candidate in get_tree().get_nodes_in_group("room_enemies"):
		if not is_instance_valid(candidate) or candidate == hit_body or candidate.get("is_dead") == true:
			continue
		if hit_instance_ids.has(candidate.get_instance_id()):
			continue
		var candidate_distance := global_position.distance_to(candidate.global_position)
		if candidate_distance <= nearest_distance:
			nearest = candidate
			nearest_distance = candidate_distance
	return nearest


func _is_outside_viewport() -> bool:
	var canvas_position := get_viewport().get_canvas_transform() * global_position
	var viewport_bounds := Rect2(Vector2.ZERO, get_viewport_rect().size).grow(viewport_margin)
	return not viewport_bounds.has_point(canvas_position)
