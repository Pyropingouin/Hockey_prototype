extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var hasPuck: bool = false
@export var team_id: int = 0
@onready var sprite: Sprite2D = $Sprite2D
#DEBUG FOR TEAMS
@onready var ring: Sprite2D = $Ring

var _start_cell: Vector2i = Vector2i.ZERO


@export var start_cell: Vector2i:
	get:
		return _start_cell
	set(value):
		_start_cell = value
		current_cell = value   # passe par le setter de current_cell
		
		
		
var _current_cell: Vector2i = Vector2i.ZERO
var current_cell: Vector2i:
	get:
		return _current_cell
	set(value):
		if _current_cell == value:
			return
		_current_cell = value
		_on_current_cell_changed()

signal hold_puck_is_moving




func _ready():
	current_cell = start_cell


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
	
	
func pick_up_puck(pawn) -> void:
	if pawn != self:
		return
	
	hasPuck = true
	print(name, " a ramassé la puck")	
	
	if hasPuck == true:
		ring.modulate = Color.YELLOW
		
func _on_current_cell_changed():
	if hasPuck:
		emit_signal("hold_puck_is_moving", _current_cell)
	
	
