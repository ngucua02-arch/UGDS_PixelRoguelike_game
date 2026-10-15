extends CanvasLayer

signal item_chosen(item_index: int)

@onready var reward_panel: PanelContainer = $RewardPanel
@onready var choice_buttons: Array[Button] = [
	$RewardPanel/Margin/VBox/Choices/Choice0,
	$RewardPanel/Margin/VBox/Choices/Choice1,
	$RewardPanel/Margin/VBox/Choices/Choice2,
]

var _offered_items: Array[ItemData] = []


func _ready() -> void:
	reward_panel.hide()
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))


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
