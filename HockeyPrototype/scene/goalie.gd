class_name Goalie
extends CharacterBody2D

var goalie_name: String
var team_id: int
var save_power: int

var current_cell: Vector2i
var start_cell: Vector2i

var fullBodyTexture: Texture2D
var bubbleHeadTexture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D


func setup(
	goalie_data: Dictionary,
	new_team_id: int,
	new_start_cell: Vector2i
) -> void:
	goalie_name = goalie_data["goalie_name"]
	team_id = new_team_id

	start_cell = new_start_cell
	current_cell = new_start_cell

	save_power = goalie_data["save_power"]

	fullBodyTexture = goalie_data["image"]
	bubbleHeadTexture = goalie_data["bubblehead"]

	var goalie_sprite := get_node_or_null("Sprite2D") as Sprite2D

	if goalie_sprite == null:
		push_error("Le nœud Sprite2D est introuvable dans goalie.tscn.")
		return

	goalie_sprite.texture = bubbleHeadTexture


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


	



func reset_board() -> void:
	current_cell = start_cell

	var ice_map_layer = get_node("../../IceMapLayer")
	ice_map_layer.place_pawn_on_cell(self, start_cell)

func get_current_cell() -> Vector2i:
	return current_cell
