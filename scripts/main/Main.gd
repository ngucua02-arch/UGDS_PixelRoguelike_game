extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const ROOM_SCENE: PackedScene = preload("res://scenes/rooms/Room.tscn")
const BOSS_SCENE: PackedScene = preload("res://scenes/enemies/Boss.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/HUD.tscn")
const ROOM_MELEE_COUNTS: Array[int] = [2, 2, 2]
const ROOM_RANGED_COUNTS: Array[int] = [0, 1, 2]
const ITEM_POOL: Array[ItemData] = [
	preload("res://resources/items/triple_shot.tres"),
	preload("res://resources/items/pierce.tres"),
	preload("res://resources/items/ricochet.tres"),
	preload("res://resources/items/fire_rate.tres"),
	preload("res://resources/items/damage_speed.tres"),
	preload("res://resources/items/dodge_cooldown.tres"),
	preload("res://resources/items/max_health_heal.tres"),
	preload("res://resources/items/death_explosion.tres"),
]

@onready var health_label: Label = $Overlay/HealthLabel
@onready var room_label: Label = $Overlay/RoomLabel
@onready var boss_health_bar: ProgressBar = $Overlay/BossHealthBar
@onready var boss_health_label: Label = $Overlay/BossHealthLabel

var player: CharacterBody2D
var room: Node2D
var hud: CanvasLayer
var current_room_index: int = 0
var selected_items: Array[ItemData] = []
var reward_items: Array[ItemData] = []
var run_state: StringName = &"combat"
var run_ended: bool = false


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	add_child(player)
	hud = HUD_SCENE.instantiate()
	hud.item_chosen.connect(_on_item_chosen)
	hud.restart_requested.connect(_restart_run)
	add_child(hud)
	hud.call("set_item_summary", selected_items)
	_start_room(0)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_label.text = "生命：%d / %d" % [current, maximum]


func _on_player_died() -> void:
	if run_ended:
		return
	run_ended = true
	run_state = &"defeat"
	_stop_combat()
	hud.call("present_result", "本局失败\n玩家已被击败", Color(1.0, 0.35, 0.48, 1.0))


func _on_room_cleared() -> void:
	if run_ended or run_state != &"combat":
		return
	run_state = &"reward"
	player.set("damage_enabled", false)
	_clear_player_projectiles()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(room):
		room.process_mode = Node.PROCESS_MODE_DISABLED
	reward_items = _draw_reward_items()
	hud.call("present_rewards", reward_items)


func _draw_reward_items() -> Array[ItemData]:
	var available_items: Array[ItemData] = []
	for item in ITEM_POOL:
		var already_owned := false
		for selected_item in selected_items:
			if selected_item.id == item.id:
				already_owned = true
				break
		if not already_owned:
			available_items.append(item)
	available_items.shuffle()
	var choices: Array[ItemData] = []
	for index in range(mini(3, available_items.size())):
		choices.append(available_items[index])
	return choices


func _on_item_chosen(item_index: int) -> void:
	if run_ended or run_state != &"reward" or item_index < 0 or item_index >= reward_items.size():
		return
	var selected_item := reward_items[item_index]
	selected_items.append(selected_item)
	player.call("apply_item", selected_item)
	hud.call("set_item_summary", selected_items)
	reward_items.clear()
	if current_room_index == ROOM_MELEE_COUNTS.size() - 1:
		hud.call("hide_rewards")
		_start_boss_room()
		return
	hud.call("hide_rewards")
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.set("damage_enabled", true)
	_start_room(current_room_index + 1)


func _start_room(room_index: int) -> void:
	current_room_index = room_index
	run_state = &"combat"
	room_label.text = "房间：%d / %d" % [current_room_index + 1, ROOM_MELEE_COUNTS.size()]
	_clear_player_projectiles()
	if is_instance_valid(room):
		room.queue_free()
	player.velocity = Vector2.ZERO
	player.global_position = get_viewport_rect().size * 0.5
	room = ROOM_SCENE.instantiate()
	room.call("configure", player, ROOM_MELEE_COUNTS[current_room_index], ROOM_RANGED_COUNTS[current_room_index])
	room.connect("room_cleared", Callable(self, "_on_room_cleared"))
	add_child(room)
	boss_health_bar.hide()
	boss_health_label.hide()


func _start_boss_room() -> void:
	current_room_index = ROOM_MELEE_COUNTS.size()
	run_state = &"boss"
	room_label.text = "最终战：霓虹守卫"
	_clear_player_projectiles()
	if is_instance_valid(room):
		room.queue_free()
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.set("damage_enabled", true)
	player.velocity = Vector2.ZERO
	player.global_position = get_viewport_rect().size * 0.5
	room = ROOM_SCENE.instantiate()
	room.call("configure", player, 0, 0)
	var boss := BOSS_SCENE.instantiate()
	boss.position = Vector2(576, 210)
	boss.call("set_target", player)
	boss.died.connect(_on_boss_died)
	boss.health_changed.connect(_on_boss_health_changed)
	room.add_child(boss)
	add_child(room)
	boss_health_bar.max_value = 40.0
	boss_health_bar.value = 40.0
	boss_health_bar.show()
	boss_health_label.text = "首领生命：40 / 40"
	boss_health_label.show()


func _on_boss_health_changed(current: int, maximum: int) -> void:
	boss_health_bar.max_value = maximum
	boss_health_bar.value = current
	boss_health_label.text = "首领生命：%d / %d" % [current, maximum]


func _on_boss_died() -> void:
	if run_ended:
		return
	run_ended = true
	run_state = &"victory"
	_stop_combat()
	hud.call("present_result", "胜利！\n霓虹守卫已被击败", Color(0.35, 1.0, 0.85, 1.0))
	boss_health_bar.hide()
	boss_health_label.hide()


func _stop_combat() -> void:
	if is_instance_valid(player):
		player.set("damage_enabled", false)
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if is_instance_valid(room):
		room.process_mode = Node.PROCESS_MODE_DISABLED
		for child in room.get_children():
			if child is Area2D and (child.collision_layer & 16) != 0:
				child.set_deferred("monitoring", false)
				child.set_deferred("monitorable", false)
				child.queue_free()


func _clear_player_projectiles() -> void:
	for child in get_children():
		if child is Area2D and child.has_method("launch"):
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
			child.queue_free()


func _restart_run() -> void:
	get_tree().reload_current_scene()
