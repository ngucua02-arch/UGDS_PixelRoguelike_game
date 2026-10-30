extends CanvasLayer

signal item_chosen(item_index: int)
signal restart_requested

const ItemDataScript = preload("res://resources/items/ItemData.gd")

@onready var reward_panel: PanelContainer = $RewardPanel
@onready var summary_backing: Panel = $SummaryBacking
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
var _owned_items: Array[ItemData] = []


func _ready() -> void:
	reward_panel.hide()
	result_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	set_item_summary([])
	_set_build_summary_visible(false)


func set_item_summary(items: Array[ItemData]) -> void:
	_owned_items = items.duplicate()
	if items.is_empty():
		item_summary.text = "构筑：暂无道具"
		return
	var route_counts := [0, 0, 0, 0]
	for item in items:
		route_counts[int(item.build_type)] += 1
	var routes: PackedStringArray = []
	for route_index in range(route_counts.size()):
		if route_counts[route_index] > 0:
			routes.append("%s ×%d" % [ItemDataScript.build_type_name(route_index), route_counts[route_index]])
	var summaries: PackedStringArray = []
	for item in items:
		var effect := item.description
		if effect.ends_with("。"):
			effect = effect.trim_suffix("。")
		summaries.append("%s：%s" % [item.display_name, effect])
	item_summary.text = "流派：" + " · ".join(routes) + "\n" + "\n".join(summaries)


func present_result(title: String, color: Color) -> void:
	_set_build_summary_visible(false)
	result_title.text = title
	result_title.add_theme_color_override("font_color", color)
	result_panel.show()
	restart_button.grab_focus()


func present_rewards(items: Array[ItemData]) -> void:
	_set_build_summary_visible(true)
	_offered_items = items.duplicate()
	for index in range(choice_buttons.size()):
		var button := choice_buttons[index]
		if index < _offered_items.size():
			var item := _offered_items[index]
			button.text = _build_item_card_text(item)
			button.show()
			button.disabled = false
		else:
			button.hide()
	reward_panel.show()


func _build_item_card_text(item: ItemData) -> String:
	var build_name := ItemDataScript.build_type_name(int(item.build_type))
	var hint := "路线起点：可发展「%s」" % build_name
	var preferred_type := ItemDataScript.preferred_build_type(_owned_items)
	if preferred_type >= 0:
		if int(item.build_type) == preferred_type:
			var matching_name := "已有道具"
			for owned_item in _owned_items:
				if owned_item.build_type == item.build_type:
					matching_name = owned_item.display_name
					break
			hint = "强化当前路线：与「%s」同属%s" % [matching_name, build_name]
		else:
			hint = "新路线：可转向「%s」" % build_name
	return "%s\n【%s】\n\n%s\n\n%s" % [item.display_name, build_name, item.description, hint]


func hide_rewards() -> void:
	reward_panel.hide()
	_offered_items.clear()
	_set_build_summary_visible(false)


func _on_choice_pressed(index: int) -> void:
	if index < 0 or index >= _offered_items.size():
		return
	for button in choice_buttons:
		button.disabled = true
	reward_panel.hide()
	item_chosen.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_TAB:
		if reward_panel.visible or result_panel.visible:
			return
		_set_build_summary_visible(not summary_backing.visible)
		return
	if result_panel.visible and key_event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_on_restart_pressed()


func _set_build_summary_visible(is_visible: bool) -> void:
	summary_backing.visible = is_visible
	item_summary.visible = is_visible


func _on_restart_pressed() -> void:
	if result_panel.visible:
		restart_requested.emit()
