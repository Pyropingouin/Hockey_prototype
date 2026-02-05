extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var team_id: int = 0
@onready var sprite: Sprite2D = $Sprite2D
#DEBUG FOR TEAMS
@onready var puck_ring: Sprite2D = $PuckRing
@onready var active_team_ring: Sprite2D = $TeamRing

@onready var GameManager = $"../../GameManager"
@onready var redXLabel = $RedX
@onready var downLabel = $downLabel

var downCounter: int = 0




# --- hasPuck avec setter ---
var _hasPuck: bool = false
@export var hasPuck: bool:
	get:
		return _hasPuck
	set(value):
		if _hasPuck == value:
			return
		_hasPuck = value
		_update_ring_color()



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
signal shooting_puck
signal passing_puck
signal hitting_player




func _ready():
	current_cell = start_cell
	call_deferred("_auto_connect_to_puck")
	
	GameManager.active_team_changed.connect(_on_active_team_changed)
	_on_active_team_changed(GameManager.active_team)
	


	if bubbleHeadTexture:
		sprite.texture = bubbleHeadTexture
		

func get_current_cell() -> Vector2i:
	return current_cell
	
	
func pick_up_puck(pawn) -> void:
	if pawn != self:
		return
	
	hasPuck = true
	print(name, " a ramassé la puck")	
	
	if hasPuck == true:
		puck_ring.modulate = Color.YELLOW
		
func _on_current_cell_changed():
	if hasPuck:
		emit_signal("hold_puck_is_moving", _current_cell)
	
	
func _update_ring_color() -> void:
	if puck_ring == null:
		return

	if hasPuck:
		puck_ring.modulate = Color.YELLOW
	else:
		puck_ring.modulate = Color.BLACK
		
func _shoot(shootPosition) -> void:
	if hasPuck:
		hasPuck = false
		print("_shoot player!")
	
		emit_signal("shooting_puck", shootPosition)
		
	else: 
		print("I dont have the puck")	
		

func _pass(passPosition) -> void:
	if hasPuck:
		hasPuck = false
		print("_pass player!")
		emit_signal("passing_puck", passPosition)
		
	else: 
		print("I dont have the puck")
		
		
func _hit(hitPosition) -> void:
	if  not hasPuck:
		
		print("_hit player!")
		emit_signal("hitting_player", hitPosition)
		
	else: 
		print("I have the puck, I can't hit")
		
		
func _being_hit() -> void:
	downCounter = 2
	redXLabel.visible = true
	downLabel.visible = true
	
	downLabel.text = str(downCounter) + " tours"
	
	
	
	
func _on_active_team_changed(active_team_id: int) -> void:
	if active_team_id == team_id:
		active_team_ring.modulate = Color.BLUE
	else: 	
		active_team_ring.modulate = Color.RED
		
				
		
func _auto_connect_to_puck() -> void:
	var pucks := get_tree().get_nodes_in_group("puck")
	if pucks.is_empty():
		return
		
		

	var puck := pucks[0]

	# hold_puck_is_moving -> puck
	if has_signal("hold_puck_is_moving") and puck.has_method("_on_pawn_hold_puck_is_moving"):
		connect("hold_puck_is_moving", Callable(puck, "_on_pawn_hold_puck_is_moving"))

	# shooting_puck -> puck
	if has_signal("shooting_puck") and puck.has_method("_on_pawn_shooting_puck"):
		connect("shooting_puck", Callable(puck, "_on_pawn_shooting_puck"))
		
	# passing_puck -> puck
	if has_signal("passing_puck") and puck.has_method("_on_pawn_passing_puck"):
		connect("passing_puck", Callable(puck, "_on_pawn_passing_puck"))
		
	# hitting_player -> ???
	#if has_signal("hitting_player") and pawn.has_method("_being_hit"):
		#connect("hitting_player", Callable(pawn, "_being_hit"))		
		
