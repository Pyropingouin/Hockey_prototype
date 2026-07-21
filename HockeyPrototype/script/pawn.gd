extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var pawn_name: String
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var health: int = 2
@export var team_id: int = 0
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
#DEBUG FOR TEAMS
@onready var puck_ring: Sprite2D = $PuckRing
@onready var active_team_ring: Sprite2D = $TeamRing
@onready var hover_area: Area2D = $HoverArea


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
signal dropping_puck
signal hitting_player(hit_cell: Vector2i, current_cell: Vector2i, pawn: Node2D)
signal hovering_pawn(pawn: Node2D)





func _ready() -> void:
	current_cell = start_cell

	hover_area.mouse_entered.connect(_on_hover_area_mouse_entered)
	hover_area.mouse_exited.connect(_on_hover_area_mouse_exited)
	call_deferred("_auto_connect_to_puck")
	call_deferred("_connect_to_other_pawns")

	GameManager.active_team_changed.connect(_on_active_team_changed)
	_on_active_team_changed(GameManager.active_team)

	GameManager.pawn_selected.connect(_on_pawn_selected)

	_update_pawn_texture()

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



func setup(
	player_data: Dictionary,
	pawn_team_id: int,
	pawn_start_cell: Vector2i
) -> void:
	pawn_name = player_data.get("pawn_name", "Unnamed Pawn")
	name = pawn_name

	var stats: Dictionary = player_data.get("stats", {})

	move_range = int(stats.get("move_range", move_range))
	strength = int(stats.get("strength", strength))
	reflex = int(stats.get("reflex", reflex))
	health = int(stats.get("health", health))

	fullBodyTexture = player_data.get("image", null)
	bubbleHeadTexture = player_data.get("bubblehead", null)

	team_id = pawn_team_id
	start_cell = pawn_start_cell

	# setup() peut être appelé avant ou après _ready()
	if is_node_ready():
		_update_pawn_texture()


	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		"--- PAWN SETUP --- | Nom:  %s | Speed:  %s | Strength:  %s | Reflex:  %s | Health: %s  |  Sprite trouvé:  %s   " % [
			pawn_name,
			move_range,
			strength,
			reflex,
			health,
			sprite != null
		]
	)			


func reset_board():
	current_cell = start_cell
	IceMapLayer.place_pawn_on_cell(self, current_cell)
	hasPuck = false



func _update_pawn_texture() -> void:
	if sprite == null:
		push_error(
			"Le Sprite2D du pawn est introuvable. Vérifie son chemin dans pawn.tscn."
		)
		return

	if bubbleHeadTexture != null:
		sprite.texture = bubbleHeadTexture
	elif fullBodyTexture != null:
		sprite.texture = fullBodyTexture
	else:
		push_warning("Aucune texture trouvée pour le pawn : " + pawn_name)	
	
	
func pick_up_puck(pawn) -> void:
	if pawn != self:
		return
	
	hasPuck = true
	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		"%s a ramassé la puck" % name
	)
	
	if hasPuck == true:
		_update_ring_color()
		
func _on_current_cell_changed():
	if hasPuck:
		
		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					"hold_puck_is_moving %s" % _current_cell
					)		
	
	
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
		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					"_shoot player!"
					)		
		


		
		emit_signal("shooting_puck", shootPosition)
		
	else: 
		DebugLogger.log(
						DebugLogger.DebugType.PAWN,
						"I dont have the puck" 
						)			
		

func _pass(passPosition) -> void:
	if hasPuck:
		hasPuck = false
		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					"_pass player! "
					)		
		
		emit_signal("passing_puck", passPosition)
		
	else: 
		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					"I dont have the puck"
					)		
		
		
		
func _hit(hit_cell) -> void:
	if  not hasPuck:
		
		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
				name %  " tente un hit sur %s" % hit_cell
					)		
		emit_signal("hitting_player", hit_cell, current_cell, self)
		
	else: 
		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					"I have the puck, I can't hit" 
					)		
		
		
func _being_hit(aggressorPawn: Node2D, origin_cell) -> void:

	DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					name % " a été FRAPPÉ ✅  par %s" % aggressorPawn.name
					)	
	DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					" Force de l'agresseur %s" % aggressorPawn.strength
					)			

	
	
	var push_direction: Vector2i = current_cell - origin_cell
	var new_position_after_hit : Vector2i  = current_cell + push_direction

	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		"direction: %s | NewPos : %s" % [
			push_direction,
			new_position_after_hit
		]
	)	


	#Vérifier si il est possible de déplacer le joueur 

	if (IceMapLayer.can_push_pawn_to(self, new_position_after_hit)):
		var drop_puck_position = current_cell
		current_cell = new_position_after_hit
		#Ne pas call Icemap, trouve autre façon à traver GameManager
		IceMapLayer.place_pawn_on_cell(self,current_cell)

		if hasPuck:
			hasPuck = false
			emit_signal("dropping_puck", drop_puck_position)

	
	else:
		#TODO Trouver si stun ou déplacer ailleurs

		DebugLogger.log(
					DebugLogger.DebugType.PAWN,
					"stun!" 
					)		
	
		
		## TODO POTENTIEL BUG
		if hasPuck:
			hasPuck = false
			emit_signal("dropping_puck", origin_cell)

	

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
			
					

func _on_hover_area_mouse_entered() -> void:
	
	hovering_pawn.emit(self)

func _on_hover_area_mouse_exited() -> void:

	hovering_pawn.emit(null)			
		
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

	# dropping_puck -> puck
	if has_signal("dropping_puck") and puck.has_method("_on_pawn_dropping_puck"):
		connect("dropping_puck", Callable(puck, "_on_pawn_dropping_puck"))	
	
