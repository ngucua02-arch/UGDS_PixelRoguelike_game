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
var configured_enemy_count: int = 2


func configure(player_node: Node2D, enemy_count: int = 2) -> void:
	player = player_node
	configured_enemy_count = clampi(enemy_count, 0, 5)


func _ready() -> void:
	_ensure_enemy_count()
	var enemies: Array[Node] = []
	_collect_enemies(self, enemies)
	living_enemies = enemies.size()
	for enemy in enemies:
		enemy.call("set_target", player)
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	if living_enemies == 0:
		_emit_room_cleared()


func _ensure_enemy_count() -> void:
	var enemies: Array[Node] = []
	_collect_enemies(self, enemies)
	while enemies.size() < configured_enemy_count:
		var enemy := ENEMY_SCENE.instantiate()
		var spawn_index := enemies.size() - 2
		if spawn_index < 0 or spawn_index >= EXTRA_ENEMY_POSITIONS.size():
			break
		enemy.position = EXTRA_ENEMY_POSITIONS[spawn_index]
		add_child(enemy)
		enemies.append(enemy)
	while enemies.size() > configured_enemy_count:
		enemies.pop_back().queue_free()


func _collect_enemies(parent: Node, result: Array[Node]) -> void:
	for child in parent.get_children():
		if child.is_in_group("room_enemies"):
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
