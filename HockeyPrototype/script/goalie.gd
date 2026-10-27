class_name Goalie
extends CharacterBody2D

var goalie_name: String
var team_id: int
var save_power: int


var _hasPuck: bool = false
var flash_tween: Tween

var hasPuck: bool:
	get:
		return _hasPuck
	set(value):
		if _hasPuck == value:
			return

		_hasPuck = value

		if not is_node_ready():
			return

		if _hasPuck:
			start_red_flash()
		else:
			stop_red_flash()

var current_cell: Vector2i
var move_range: int = 1


var fullBodyTexture: Texture2D
var bubbleHeadTexture: Texture2D


var net_position: Vector2i
var front_position: Vector2i
var up_position: Vector2i
var down_position: Vector2i

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if hasPuck:
		start_red_flash()


func setup(
	goalie_data: Dictionary,
	new_team_id: int,
	new_start_cell: Vector2i
) -> void:
	goalie_name = goalie_data["goalie_name"]
	team_id = new_team_id

	current_cell = new_start_cell

	save_power = goalie_data["save_power"]

	bubbleHeadTexture = goalie_data["bubblehead"]

	var goalie_sprite := get_node_or_null("Sprite2D") as Sprite2D

	if goalie_sprite == null:
		push_error("Le nœud Sprite2D est introuvable dans goalie.tscn.")
		return

	goalie_sprite.texture = bubbleHeadTexture



func pick_up_puck(pawn: Node2D) -> void:
	if pawn != self:
		return

	hasPuck = true

	DebugLogger.log(
		DebugLogger.DebugType.GOALIE,
		"%s récupère la puck" % goalie_name
	)	


func attempt_save(shooter_reflex: int) -> bool:
	var save_difference: int = save_power - shooter_reflex


	
	DebugLogger.log(
	DebugLogger.DebugType.GOALIE,
	"%s tente un arrêt. Save Power:  %s |  Reflex du tireur:  %s | Différence: %s  " % [
		goalie_name,
		save_power,
		shooter_reflex,
		save_difference
	]
)		

	# Le goalie n'a aucune chance si son save_power
	# n'est pas supérieur au reflex du tireur.
	if save_difference < 1:
		return false

	var save_chance: float = min(
		float(save_difference) * 0.20,
		0.90
	)

	var random_roll: float = randf()
	var save_successful: bool = random_roll < save_chance


	DebugLogger.log(
	DebugLogger.DebugType.GOALIE,
	"Chance d'arrêt: %s%% | Jet:  %s  | Réussite:  %s" % [
		save_chance * 100.0,
		random_roll,
		save_successful
		]
	)		


	return save_successful


func set_goalie_positions(positions: Dictionary) -> void:
	net_position = positions["net"]
	front_position = positions["front"]
	up_position = positions["up"]
	down_position = positions["down"]


func reset_board() -> void:
	current_cell = front_position

	var ice_map_layer = get_node("../../IceMapLayer")
	ice_map_layer.place_pawn_on_cell(self, current_cell)

func get_current_cell() -> Vector2i:
	return current_cell



func move_goalie_prototype() -> void:
	var roll = randi_range(1,3)
	var target_cell: Vector2i
	var ice_map_layer = get_node("../../IceMapLayer")

	print(goalie_name, "roll: ", roll)

	
	if roll == 1:
		target_cell = front_position

	elif roll == 2:
		target_cell = up_position

	else:
		target_cell = down_position

	if current_cell == target_cell:
		return

	if ice_map_layer.can_move_pawn_to(self, current_cell, target_cell):
		ice_map_layer.apply_move(self, current_cell, target_cell)

	

	

#### TEMPORAIRE

func start_red_flash() -> void:
	if flash_tween:
		flash_tween.kill()

	sprite.modulate = Color.WHITE

	flash_tween = create_tween()
	flash_tween.set_loops()

	flash_tween.tween_property(
		sprite,
		"modulate",
		Color.RED,
		0.35
	)

	flash_tween.tween_property(
		sprite,
		"modulate",
		Color.WHITE,
		0.35
	)


func stop_red_flash() -> void:
	if flash_tween:
		flash_tween.kill()

	sprite.modulate = Color.WHITE