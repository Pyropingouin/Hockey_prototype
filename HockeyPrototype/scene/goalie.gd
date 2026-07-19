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



func reset_board() -> void:
	current_cell = start_cell

	var ice_map_layer = get_node("../../IceMapLayer")
	ice_map_layer.place_pawn_on_cell(self, start_cell)

func get_current_cell() -> Vector2i:
	return current_cell