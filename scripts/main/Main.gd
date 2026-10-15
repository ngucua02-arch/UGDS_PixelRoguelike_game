extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const ROOM_SCENE: PackedScene = preload("res://scenes/rooms/Room.tscn")

@onready var health_label: Label = $Overlay/HealthLabel
@onready var result_label: Label = $Overlay/ResultLabel

var player: CharacterBody2D
var room: Node2D
var run_ended: bool = false


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	add_child(player)

	room = ROOM_SCENE.instantiate()
	room.call("configure", player)
	room.connect("room_cleared", Callable(self, "_on_room_cleared"))
	add_child(room)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func _on_player_health_changed(current: int, maximum: int) -> void:
	health_label.text = "生命：%d / %d" % [current, maximum]


func _on_player_died() -> void:
	if run_ended:
		return
	run_ended = true
	result_label.text = "你被击败了\n按 R 重新开始"
	result_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.48, 1.0))


func _on_room_cleared() -> void:
	if run_ended:
		return
	run_ended = true
	result_label.text = "房间已清空！\n按 R 重新开始"
