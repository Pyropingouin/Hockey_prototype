extends CharacterBody2D  

@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D
@export var fullBodyAnimation: SpriteFrames
@export var pawn_name: String
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var health: int = 2
@export var team_id: int = 0
@export var maxEnergy: int = 0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
#DEBUG FOR TEAMS
@onready var hover_area: Area2D = $HoverArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var energy_label: Label = $EnergyBar/EnergyLabel


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
		_update_puck_control_color()



var _start_cell: Vector2i = Vector2i.ZERO
var _is_selected_pawn = false
var hue: float = 0.0
var puck_color_tween: Tween

var _current_energy: int = 0

var current_energy: int:
	get:
		return _current_energy

	set(value):
		_current_energy = clampi(
			value,
			0,
			maxEnergy
		)

		if is_instance_valid(energy_bar):
			energy_bar.value = _current_energy

		if is_instance_valid(energy_label):
			energy_label.text = "%d/%d" % [
				_current_energy,
				maxEnergy
			]


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


#Higher = Stronger
const NO_ENERGY_STRENGH := 15.0
#Lower = Faster
const NO_ENERGY_SPEED := 0.04	
const SPEND_ENERGY_STRENGH := 1
const SPEND_ENERGY_SPEED := 0.04	

signal hold_puck_is_moving
signal shooting_puck
signal passing_puck
signal dropping_puck
signal hitting_player(hit_cell: Vector2i, current_cell: Vector2i, pawn: Node2D)
signal hovering_pawn(pawn: Node2D)





func _ready() -> void:
	current_cell = start_cell
	current_energy = maxEnergy
	initialize_energy()

	hover_area.mouse_entered.connect(_on_hover_area_mouse_entered)
	hover_area.mouse_exited.connect(_on_hover_area_mouse_exited)
	call_deferred("_auto_connect_to_puck")
	call_deferred("_connect_to_other_pawns")

	GameManager.active_team_changed.connect(_on_active_team_changed)
	_on_active_team_changed(GameManager.active_team)

	GameManager.pawn_selected.connect(_on_pawn_selected)

	_update_pawn_texture()

func _process(delta: float) -> void:
	pass
	## REMETTRE SI ON VEUT DE LA COULEUR SUR SELECTED PAWN
	# if _is_selected_pawn:
	# 	hue += delta * 0.5

	# 	if hue > 1.0:
	# 		hue -= 1.0

	# 	animated_sprite.modulate = Color.from_hsv(
	# 		hue,
	# 		1.0,
	# 		1.0,
	# 		1.0
	# 	)	

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
	maxEnergy =int(stats.get("maxEnergy", maxEnergy))

	fullBodyTexture = player_data.get("image", null)
	bubbleHeadTexture = player_data.get("bubblehead", null)
	fullBodyAnimation = player_data.get("fullBodyAnimation", null)

	

	
	team_id = pawn_team_id
	start_cell = pawn_start_cell

	# setup() peut être appelé avant ou après _ready()
	if is_node_ready():
		_update_pawn_texture()
		initialize_energy()


	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		"--- PAWN SETUP --- | Nom:  %s | Speed:  %s | Strength:  %s | Reflex:  %s | Health: %s  | maxEnergy: %s|  Sprite trouvé:  %s   " % [
			pawn_name,
			move_range,
			strength,
			reflex,
			health,
			maxEnergy,
			sprite != null
		]
	)			


func reset_board():
	current_cell = start_cell
	IceMapLayer.place_pawn_on_cell(self, current_cell)
	hasPuck = false



func _update_pawn_texture() -> void:
	if animated_sprite == null:
		push_error(
			"AnimatedSprite2D introuvable pour %s"
			% pawn_name
		)
		return

	if fullBodyAnimation == null:
		push_error(
			"SpriteFrames introuvable pour %s"
			% pawn_name
		)
		return

	animated_sprite.sprite_frames = fullBodyAnimation

	var animations := fullBodyAnimation.get_animation_names()

	if animations.is_empty():
		push_error(
			"Aucune animation disponible pour %s"
			% pawn_name
		)
		return

	var animation_name: StringName = animations[0]

	animated_sprite.play(animation_name)

	var frame_count: int = fullBodyAnimation.get_frame_count(
		animation_name
	)

	if frame_count > 0:
		animated_sprite.frame = randi_range(
			0,
			frame_count - 1
		)

	if sprite != null:
		sprite.visible = false

	animated_sprite.visible = true
	
	
func pick_up_puck(pawn) -> void:
	if pawn != self:
		return
	
	hasPuck = true
	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		"%s a ramassé la puck" % name
	)	
	
	if hasPuck == true:
		_update_puck_control_color()
		
func _on_current_cell_changed():
	if hasPuck:
		
		DebugLogger.log(
			DebugLogger.DebugType.PAWN,
			"hold_puck_is_moving %s" % _current_cell
		)		
	
	
func _update_puck_control_color() -> void:
	if puck_color_tween:
		puck_color_tween.kill()

	if hasPuck:
		puck_color_tween = create_tween()
		puck_color_tween.set_loops()
		puck_color_tween.set_trans(Tween.TRANS_SINE)
		puck_color_tween.set_ease(Tween.EASE_IN_OUT)

		puck_color_tween.tween_property(
			animated_sprite,
			"modulate",
			Color.RED,
			0.8
		)

		puck_color_tween.tween_property(
			animated_sprite,
			"modulate",
			_get_base_color(),
			0.4
		)

	else:
		animated_sprite.modulate = _get_base_color()


func _get_base_color() -> Color:
	if GameManager.active_team == team_id:
		return Color.WHITE

	return Color(0.65, 0.65, 0.65, 1.0)		

		
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
	if not hasPuck:
		
		DebugLogger.log(
			DebugLogger.DebugType.PAWN,
			"%s tente un hit sur %s" % [name, hit_cell]
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
		"%s a été FRAPPÉ ✅ par %s" % [name, aggressorPawn.name]
	)	
	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		" Force de l'agresseur %s" % aggressorPawn.strength
	)			

	
	
	var push_direction: Vector2i = current_cell - origin_cell
	var new_position_after_hit: Vector2i = current_cell + push_direction

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

func _on_active_team_changed(_active_team_id: int) -> void:
	if _is_selected_pawn:
		return

	if hasPuck:
		_update_puck_control_color()
	else:
		animated_sprite.modulate = _get_base_color()
		
func _on_pawn_selected(selected_pawn: Variant) -> void:
	_is_selected_pawn = selected_pawn == self

	if not _is_selected_pawn:
		if hasPuck:
			_update_puck_control_color()
		else:
			animated_sprite.modulate = _get_base_color()
					

func _on_hover_area_mouse_entered() -> void:
	
	hovering_pawn.emit(self)

func _on_hover_area_mouse_exited() -> void:

	hovering_pawn.emit(null)			


func regenEnergy() -> void:

	DebugLogger.log(
		DebugLogger.DebugType.PAWN,
		"Name: %s | current_energy : %s | maxEnergy : %s" % [
			pawn_name,
			current_energy,
			maxEnergy
		]
	)	

	current_energy += 1

	if current_energy > maxEnergy:
		current_energy = maxEnergy


func regenAllEnergy() -> void:
	current_energy = maxEnergy


func canSpendEnergy(energyAmount) -> bool:
	 
	if energyAmount > current_energy:
		shake_energy_bar(NO_ENERGY_STRENGH, NO_ENERGY_SPEED)
		return false

	else:
		return true	


func spendEnergy(spentEnergyAmount: int) -> bool:

	if  current_energy < 0:
		current_energy = 0

	if current_energy < spentEnergyAmount:
		print("not enough energy")
		return false


	shake_energy_bar(SPEND_ENERGY_STRENGH, SPEND_ENERGY_SPEED)
	current_energy -= spentEnergyAmount
	return true


func initialize_energy() -> void:
	current_energy = maxEnergy

	if not is_instance_valid(energy_bar):
		return

	energy_bar.min_value = 0
	energy_bar.max_value = maxEnergy
	energy_bar.step = 1
	energy_bar.value = current_energy



		
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


func shake_energy_bar(shake_strength, shake_speed) -> void:
	var original_position = energy_bar.position



	var tween = create_tween()

	tween.tween_property(
		energy_bar,
		"position",
		original_position + Vector2(-shake_strength, 0),
		shake_speed
	)

	tween.tween_property(
		energy_bar,
		"position",
		original_position + Vector2(shake_strength, 0),
		shake_speed
	)

	tween.tween_property(
		energy_bar,
		"position",
		original_position + Vector2(-shake_strength, 0),
		shake_speed
	)

	tween.tween_property(
		energy_bar,
		"position",
		original_position + Vector2(shake_strength, 0),
		shake_speed
	)

	tween.tween_property(
		energy_bar,
		"position",
		original_position,
		shake_speed
	)