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
	GAME_MANAGER
}

# Interrupteur principal pour tous les logs.
var enabled: bool = true

# Activation individuelle des catégories.
var enabled_types: Dictionary = {
	DebugType.GENERAL: false,
	DebugType.PAWN: true,
	DebugType.AI: true,
	DebugType.SETUP: true,
	DebugType.PUCK: true,
	DebugType.GOALIE: true,
	DebugType.DRAFT: true,
	DebugType.ACTION_MANAGER: true,
	DebugType.GAME_MANAGER: true
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