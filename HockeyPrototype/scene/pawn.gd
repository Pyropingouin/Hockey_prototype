extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var start_cell: Vector2i = Vector2i(0, 0):
	set(value):
		start_cell = value
		current_cell = value
@export var team_id: int = 0

var current_cell = start_cell


@onready var sprite: Sprite2D = $Sprite2D

#DEBUG FOR TEAMS
@onready var ring: Sprite2D = $Ring



func _ready():

	if bubbleHeadTexture:
		sprite.texture = bubbleHeadTexture
		
	#DEBUG FOR TEAMS
	if team_id == 1:
		ring.modulate = Color.RED
	#DEBUG FOR TEAMS
	else:
		ring.modulate = Color.BLUE	
		

func get_current_cell() -> Vector2i:
	return current_cell
	
	
	
