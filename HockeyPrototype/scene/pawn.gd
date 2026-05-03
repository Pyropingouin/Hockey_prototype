extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var pawn_name: String
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var team_id: int = 0
@onready var sprite: Sprite2D = $Sprite2D
#DEBUG FOR TEAMS
@onready var puck_ring: Sprite2D = $PuckRing
@onready var active_team_ring: Sprite2D = $TeamRing

@onready var GameManager = $"../../GameManager"
@onready var IceMapLayer = $"../../IceMapLayer"
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
var _is_selected_pawn = false
var hue: float = 0.0




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
signal hitting_player(hit_cell: Vector2i, current_cell: Vector2i, pawn: Node2D)





func _ready():
	current_cell = start_cell

	call_deferred("_auto_connect_to_puck")
	call_deferred("_connect_to_other_pawns")
	
	GameManager.active_team_changed.connect(_on_active_team_changed)
	_on_active_team_changed(GameManager.active_team)
	
	GameManager.pawn_selected.connect(_on_pawn_selected)


	


	if bubbleHeadTexture:
		sprite.texture = bubbleHeadTexture
		
func _process(delta: float) -> void:
	if _is_selected_pawn:
		hue += delta * 0.5
		if hue > 1.0:
			hue -= 1.0
		
		active_team_ring.modulate = Color.from_hsv(hue, 1.0, 1.0, 1.0)
	else:
		if GameManager.active_team == team_id:
			active_team_ring.modulate = Color.BLUE
		else:
			active_team_ring.modulate = Color.RED		

func get_current_cell() -> Vector2i:
	return current_cell



func setup(player_data: Dictionary, pawn_team_id: int, pawn_start_cell: Vector2i) -> void:
	if player_data.has("pawn_name"):
		pawn_name = player_data["pawn_name"]
		name = pawn_name

	if player_data.has("move_range"):
		move_range = player_data["move_range"]

	if player_data.has("strength"):
		strength = player_data["strength"]

	if player_data.has("reflex"):
		reflex = player_data["reflex"]

	if player_data.has("image"):
		bubbleHeadTexture = player_data["image"]

	team_id = pawn_team_id
	start_cell = pawn_start_cell	
	
	
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
		
		
func _hit(hit_cell) -> void:
	if  not hasPuck:
		
	
		print(name, " tente un hit sur ", hit_cell)
		emit_signal("hitting_player", hit_cell, current_cell, self)
		
	else: 
		print("I have the puck, I can't hit")
		
		
func _being_hit(aggressorPawn: Node2D, origin_cell) -> void:
	print(name, " a été FRAPPÉ ✅")
	print(aggressorPawn.name, "aggressor")

	print(aggressorPawn.strength, "Strength")
	
	print("Cell d'origine", origin_cell)
	
	var push_direction: Vector2i = current_cell - origin_cell
	var new_position_after_hit : Vector2i  = current_cell + push_direction
	
	print("direction", push_direction)
	print("NewPos", new_position_after_hit)
	
	#Vérifier si il est possible de déplacer le joueur 

	if (IceMapLayer.can_push_pawn_to(self, new_position_after_hit)):
		current_cell = new_position_after_hit
		#Ne pas call Icemap, trouve autre façon à traver GameManager
		IceMapLayer.place_pawn_on_cell(self,current_cell)
		
	else:
		#TODO Trouver si stun ou déplacer ailleurs
		print("stun!")
	
	

func _on_other_pawn_hit_attempt(hit_cell: Vector2i, origin_cell: Vector2i, aggressorPawn: Node2D) -> void:
	# Le pawn qui reçoit décide si c'est lui qui est visé
	if current_cell != hit_cell:
		return

	_being_hit(aggressorPawn, origin_cell)

func _on_active_team_changed(active_team_id: int) -> void:
	if active_team_id == team_id:
		active_team_ring.modulate = Color.BLUE
	else: 	
		active_team_ring.modulate = Color.RED
		
func _on_pawn_selected(selected_pawn: Variant) -> void:
	if(selected_pawn == self):
		_is_selected_pawn = true
	else: 	
		_is_selected_pawn = false
	
	
	#Change color et pas remplacer le team ring !
	if _is_selected_pawn:
		active_team_ring.modulate = Color.YELLOW
	else:
		if GameManager.active_team == team_id:
			active_team_ring.modulate = Color.BLUE
		else: 	
			active_team_ring.modulate = Color.RED
			
					
		
func _connect_to_other_pawns() -> void:
	var container = get_parent() #PlayerContainer
	
	for p in container.get_children():
		if p == self:
			continue
		
		if p.has_method("_on_other_pawn_hit_attempt"):
			connect("hitting_player", Callable(p, "_on_other_pawn_hit_attempt"))
		
				
		
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
	
