extends CharacterBody2D

#TODO changer la valeur de isPickUp selon une variable getter setter
#TODO écouteur ce changer et faire apparaitre la puck kkpart 

@onready var ice_map: TileMapLayer = $"../IceMapLayer"
@onready var GameManager = $"../GameManager"

@export var start_cell: Vector2i = Vector2i(2, 0):
	set(value):
		start_cell = value
		current_cell = value
@export var isPickedUp: bool = false
@onready var sprite: Sprite2D = $Sprite2D

var current_cell = start_cell
var reset_puck_position: Vector2i = Vector2i(2, 0)

signal goal_scored(goal_type)

@export var team_id: int = 0


func _ready():
	add_to_group("puck")

func _process(_delta: float) -> void:
	#print(current_cell)
	pass
	

func get_current_cell() -> Vector2i:
	return current_cell


func _on_ice_map_layer_puck_is_picked_up(pawn: Variant) -> void:
	isPickedUp = true
	sprite.visible = false



func _on_pawn_hold_puck_is_moving(pawn_position: Vector2i) -> void:
	current_cell = pawn_position

func _on_pawn_shooting_puck(newShootPosition) -> void:
	print("IN PUCK SHOOT", newShootPosition)
	
	current_cell = newShootPosition
	isPickedUp = false
	## TODO modifier avec un getter/setter sur isPickedUp
	sprite.visible = true

	# S'il y a but
	_is_goal(current_cell)
	
	ice_map.place_puck_on_cell(self, current_cell)

	
	
func _on_pawn_passing_puck(newPassPosition) -> void:
	print("IN PUCK PASS", newPassPosition)
	
	current_cell = newPassPosition
	isPickedUp = false
		## TODO modifier avec un getter/setter sur isPickedUp
	sprite.visible = true


	# S'il y a but
	_is_goal(current_cell)
		
	ice_map.place_puck_on_cell(self, current_cell)


func _is_goal(puck_position):
	print("type de tuile: ", ice_map._get_type(puck_position))
	print("goal_type: ", ice_map._get_goal_type(puck_position))
	
	if ice_map._get_type(puck_position) == "goal":
		var goal_type = ice_map._get_goal_type(puck_position)
		goal_scored.emit(goal_type)
		return true
	else:
		return false	
		

func reset_board():
	current_cell = reset_puck_position
	ice_map.place_puck_on_cell(self, reset_puck_position)
