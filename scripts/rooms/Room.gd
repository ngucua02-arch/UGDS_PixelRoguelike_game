extends Node2D

signal room_cleared

var player: Node2D
var living_enemies: int = 0
var has_cleared: bool = false


func configure(player_node: Node2D) -> void:
	player = player_node


func _ready() -> void:
	var enemies: Array[Node] = []
	_collect_enemies(self, enemies)
	living_enemies = enemies.size()
	for enemy in enemies:
		enemy.call("set_target", player)
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	if living_enemies == 0:
		_emit_room_cleared()


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
