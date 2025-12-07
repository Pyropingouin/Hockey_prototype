extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var move_range: int = 2
@export var start_cell: Vector2i = Vector2i(0, 0)


var current_cell: Vector2i



@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	if bubbleHeadTexture:
		sprite.texture = bubbleHeadTexture
