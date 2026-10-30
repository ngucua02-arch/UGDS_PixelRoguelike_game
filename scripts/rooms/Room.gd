extends Node2D

signal room_cleared

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/Enemy.tscn")
const EXTRA_ENEMY_POSITIONS: Array[Vector2] = [
	Vector2(576, 170),
	Vector2(300, 478),
	Vector2(852, 170),
]

var player: Node2D
var living_enemies: int = 0
var has_cleared: bool = false
var configured_archetypes: PackedInt32Array = PackedInt32Array([0, 0])


func configure(player_node: Node2D, archetypes: PackedInt32Array = PackedInt32Array([0, 0])) -> void:
	player = player_node
	configured_archetypes = archetypes.slice(0, 5)


func _ready() -> void:
	_ensure_enemy_composition()
	var enemies: Array[Node] = []
	_collect_enemies(self, enemies)
	living_enemies = enemies.size()
	for index in range(enemies.size()):
		var enemy := enemies[index]
		enemy.call("set_target", player)
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	if living_enemies == 0:
		_emit_room_cleared()


func _ensure_enemy_composition() -> void:
	var enemies: Array[Node] = []
	_collect_enemies(self, enemies)
	var total_count := configured_archetypes.size()
	while enemies.size() < total_count:
		var enemy := ENEMY_SCENE.instantiate()
		var spawn_index := enemies.size() - 2
		if spawn_index < 0 or spawn_index >= EXTRA_ENEMY_POSITIONS.size():
			break
		enemy.position = EXTRA_ENEMY_POSITIONS[spawn_index]
		add_child(enemy)
		enemies.append(enemy)
	while enemies.size() > total_count:
		enemies.pop_back().queue_free()
	for index in range(enemies.size()):
		enemies[index].call("configure_archetype", configured_archetypes[index])


func _collect_enemies(parent: Node, result: Array[Node]) -> void:
	for child in parent.get_children():
		# Bosses share this group so room-wide item effects can hit them, but
		# only regular enemies participate in room composition and clear counts.
		if child.is_in_group("room_enemies") and child.has_method("set_ranged_mode"):
			result.append(child)
		else:
			_collect_enemies(child, result)


func _on_enemy_died() -> void:
	if has_cleared:
		return
	living_enemies = maxi(0, living_enemies - 1)
	if living_enemies == 0:
		_emit_room_cleared()


func _emit_room_cleared() -> void:
	if has_cleared:
		return
	has_cleared = true
	room_cleared.emit()
