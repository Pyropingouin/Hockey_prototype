extends CharacterBody2D

@export var start_cell: Vector2i = Vector2i(0, 0):
	set(value):
		start_cell = value
		current_cell = value
@export var isPickedUp: bool = false
@export var carrier: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

var current_cell = start_cell

@export var team_id: int = 0


## TODO à changer, parce que c'est souvent que ça trigger

func _process(_delta: float) -> void:
	if not isPickedUp or carrier == null:
		return

	# 1) Mettre à jour la cellule logique
	if carrier.has_method("get_current_cell"):
		current_cell = carrier.get_current_cell()
		print(current_cell)



func get_current_cell() -> Vector2i:
	return current_cell


func _on_ice_map_layer_puck_is_picked_up(pawn: Variant) -> void:
	isPickedUp = true
	sprite.visible = false
	carrier = pawn
