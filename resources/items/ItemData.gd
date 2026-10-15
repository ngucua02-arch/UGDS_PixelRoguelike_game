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
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var effect_type: EffectType = EffectType.TRIPLE_SHOT
@export var value_primary: float = 0.0
@export var value_secondary: float = 0.0
