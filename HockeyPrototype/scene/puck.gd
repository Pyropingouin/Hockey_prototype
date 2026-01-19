extends CharacterBody2D

@export var start_cell: Vector2i = Vector2i(0, 0):
	set(value):
		start_cell = value
		current_cell = value
@export var isPickedUp: bool = false

@onready var sprite: Sprite2D = $Sprite2D

var current_cell = start_cell




@export var team_id: int = 0


func _process(delta):
	if isPickedUp == true:
		sprite.visible = false
	else:
		sprite.visible = true		
	



func get_current_cell() -> Vector2i:
	return current_cell
