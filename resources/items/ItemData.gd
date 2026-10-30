extends Resource
class_name ItemData

enum EffectType {
	TRIPLE_SHOT,
	PIERCE,
	RICOCHET,
	FIRE_RATE,
	DAMAGE_SPEED,
	DODGE_COOLDOWN,
	MAX_HEALTH_HEAL,
	DEATH_EXPLOSION,
	FOURTH_SHOT_VOLLEY,
	FIFTH_SHOT_CRIT,
	EXPLOSIVE_ROUNDS,
	CHAIN_ARC,
	HIT_REPAIR,
	DODGE_PULSE,
}

enum BuildType {
	VOLLEY,
	PIERCE,
	CHAIN,
	SURVIVAL,
}

const BUILD_TYPE_NAMES: Array[String] = ["弹幕流", "穿透流", "连锁流", "生存流"]

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_type: EffectType = EffectType.TRIPLE_SHOT
@export var build_type: BuildType = BuildType.VOLLEY
@export var value_primary: float = 0.0
@export var value_secondary: float = 0.0


static func preferred_build_type(items: Array[ItemData]) -> int:
	var counts := [0, 0, 0, 0]
	for item in items:
		var type_index := int(item.build_type)
		if type_index >= 0 and type_index < counts.size():
			counts[type_index] += 1
	var preferred_type := -1
	var highest_count := 0
	for type_index in range(counts.size()):
		if counts[type_index] > highest_count:
			highest_count = counts[type_index]
			preferred_type = type_index
	return preferred_type


static func build_type_name(type_index: int) -> String:
	if type_index < 0 or type_index >= BUILD_TYPE_NAMES.size():
		return "未定路线"
	return BUILD_TYPE_NAMES[type_index]
