extends Node

enum DebugType {
	GENERAL,
	AI,
	PAWN,
	SETUP,
	PUCK,
	GOALIE,
	DRAFT,
	ACTION_MANAGER,
	GAME_MANAGER,
	ICE_MAP_LAYER
}

# Interrupteur principal pour tous les logs.
var enabled: bool = true

# Activation individuelle des catégories.
var enabled_types: Dictionary = {
	DebugType.GENERAL: false,
	DebugType.PAWN: false,
	DebugType.AI: false,
	DebugType.SETUP: false,
	DebugType.PUCK: false,
	DebugType.GOALIE: false,
	DebugType.DRAFT: false,
	DebugType.ACTION_MANAGER: false,
	DebugType.GAME_MANAGER: false,
	DebugType.ICE_MAP_LAYER: true
	
}


func log(type: DebugType, message: Variant) -> void:
	if not enabled:
		return

	if not enabled_types.get(type, false):
		return

	var type_name: String = DebugType.keys()[type]

	print("[%s] %s" % [
		type_name,
		str(message)
	])


func warning(type: DebugType, message: Variant) -> void:
	if not enabled:
		return

	if not enabled_types.get(type, false):
		return

	var type_name: String = DebugType.keys()[type]

	push_warning("[%s] %s" % [
		type_name,
		str(message)
	])


func set_type_enabled(type: DebugType, value: bool) -> void:
	enabled_types[type] = value


func enable_all() -> void:
	enabled = true

	for type in enabled_types:
		enabled_types[type] = true


func disable_all() -> void:
	enabled = false