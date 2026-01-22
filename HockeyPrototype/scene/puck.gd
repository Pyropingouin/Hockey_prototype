extends CharacterBody2D

@export var start_cell: Vector2i = Vector2i(0, 0):
	set(value):
		start_cell = value
		current_cell = value
@export var isPickedUp: bool = false
@onready var sprite: Sprite2D = $Sprite2D

var current_cell = start_cell

@export var team_id: int = 0

func _process(_delta: float) -> void:
	pass
	#print(current_cell)

func get_current_cell() -> Vector2i:
	return current_cell


func _on_ice_map_layer_puck_is_picked_up(pawn: Variant) -> void:
	isPickedUp = true
	sprite.visible = false



func _on_pawn_hold_puck_is_moving(pawn_position: Vector2i) -> void:
	current_cell = pawn_position
	
