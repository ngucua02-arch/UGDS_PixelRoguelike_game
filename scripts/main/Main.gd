extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const ROOM_SCENE: PackedScene = preload("res://scenes/rooms/Room.tscn")
const ROOM_ENEMY_COUNTS: Array[int] = [2, 3, 4]
const REWARD_PLACEHOLDER_SECONDS: float = 1.25

@onready var health_label: Label = $Overlay/HealthLabel
@onready var room_label: Label = $Overlay/RoomLabel
@onready var result_label: Label = $Overlay/ResultLabel

var player: CharacterBody2D
var room: Node2D
var current_room_index: int = 0
var selected_items: Array = []
var run_state: StringName = &"combat"
var run_ended: bool = false


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	add_child(player)
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
	result_label.text = "你被击败了\n按 R 重新开始"
	result_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.48, 1.0))


func _on_room_cleared() -> void:
	if run_ended or run_state != &"combat":
		return
	run_state = &"reward"
	result_label.text = "房间已清空\n奖励阶段（占位）"
	_advance_after_reward_placeholder()


func _advance_after_reward_placeholder() -> void:
	await get_tree().create_timer(REWARD_PLACEHOLDER_SECONDS).timeout
	if run_ended or run_state != &"reward":
		return
	if current_room_index == ROOM_ENEMY_COUNTS.size() - 1:
		run_state = &"victory"
		run_ended = true
		result_label.text = "原型流程胜利！\n奖励选择接入后，将在选择奖励后结算"
		return
	_start_room(current_room_index + 1)


func _start_room(room_index: int) -> void:
	current_room_index = room_index
	run_state = &"combat"
	result_label.text = ""
	room_label.text = "房间：%d / %d" % [current_room_index + 1, ROOM_ENEMY_COUNTS.size()]
	_clear_player_projectiles()
	if is_instance_valid(room):
		room.queue_free()
	player.velocity = Vector2.ZERO
	player.global_position = get_viewport_rect().size * 0.5
	room = ROOM_SCENE.instantiate()
	room.call("configure", player, ROOM_ENEMY_COUNTS[current_room_index])
	room.connect("room_cleared", Callable(self, "_on_room_cleared"))
	add_child(room)


func _clear_player_projectiles() -> void:
	for child in get_children():
		if child is Area2D and child.has_method("launch"):
			child.queue_free()
