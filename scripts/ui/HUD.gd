extends CanvasLayer

signal item_chosen(item_index: int)
signal restart_requested

@onready var reward_panel: PanelContainer = $RewardPanel
@onready var item_summary: Label = $ItemSummary
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title: Label = $ResultPanel/Margin/VBox/Title
@onready var restart_button: Button = $ResultPanel/Margin/VBox/RestartButton
@onready var choice_buttons: Array[Button] = [
	$RewardPanel/Margin/VBox/Choices/Choice0,
	$RewardPanel/Margin/VBox/Choices/Choice1,
	$RewardPanel/Margin/VBox/Choices/Choice2,
]

var _offered_items: Array[ItemData] = []


func _ready() -> void:
	reward_panel.hide()
	result_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	set_item_summary([])


func set_item_summary(items: Array[ItemData]) -> void:
	if items.is_empty():
		item_summary.text = "构筑：暂无道具"
		return
	var summaries: PackedStringArray = []
	for item in items:
		var effect := item.description
		if effect.ends_with("。"):
			effect = effect.trim_suffix("。")
		summaries.append("%s：%s" % [item.display_name, effect])
	item_summary.text = "构筑：\n" + "\n".join(summaries)


func present_result(title: String, color: Color) -> void:
	result_title.text = title
	result_title.add_theme_color_override("font_color", color)
	result_panel.show()
	restart_button.grab_focus()


func present_rewards(items: Array[ItemData]) -> void:
	_offered_items = items.duplicate()
	for index in range(choice_buttons.size()):
		var button := choice_buttons[index]
		if index < _offered_items.size():
			var item := _offered_items[index]
			button.text = "%s\n\n%s" % [item.display_name, item.description]
			button.show()
			button.disabled = false
		else:
			button.hide()
	reward_panel.show()


func hide_rewards() -> void:
	reward_panel.hide()
	_offered_items.clear()


func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= _offered_items.size():
		return
	for button in choice_buttons:
		button.disabled = true
	reward_panel.hide()
	item_chosen.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not result_panel.visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_on_restart_pressed()


func _on_restart_pressed() -> void:
	if result_panel.visible:
		restart_requested.emit()
