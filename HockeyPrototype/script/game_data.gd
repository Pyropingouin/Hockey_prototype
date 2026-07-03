extends Node

var player_team_selected_players: Array = []
var opposing_team_selected_players: Array = []


# Create default team if no draft is selected
func _ready() -> void:
	set_default_teams()
	set_default_opposing_team()


func set_default_teams() -> void:
	player_team_selected_players = [
		create_player(
			8,
			"Glorp Thorpe",
			"res://assets/personnage/GlorpThorpe.png",
			"res://assets/Bubble_head/GlorpThorpe_BubbleHead.png",
			3,
			3,
			6,
			4
		),
		create_player(
			30,
			"Zoran Dew-Fingers",
			"res://assets/personnage/ZoranDewFingers.png",
			"res://assets/Bubble_head/ZoranDewFingers_BubbleHead.png",
			3,
			3,
			6,
			4
		),
		create_player(
			15,
			"Josh Soup",
			"res://assets/personnage/JoshSoup.png",
			"res://assets/Bubble_head/JoshSoup_BubbleHead.png",
			3,
			3,
			6,
			4
		)
	]
	
func set_default_opposing_team() -> void:
	opposing_team_selected_players = [
		create_player(
			29,
			"Wale Deise",
			"res://assets/personnage/WaleDeise.png",
			"res://assets/Bubble_head/WaleDeise_BubbleHead.png",
			3,
			3,
			6,
			4
		),
		create_player(
			23,
			"Orian Maduro",
			"res://assets/personnage/OrianMaduro.png",
			"res://assets/Bubble_head/OrianMaduro_BubbleHead.png",
			3,
			3,
			6,
			4
		),
		create_player(
			11,
			"Henry Ducker",
			"res://assets/personnage/HenryDucker.png",
			"res://assets/Bubble_head/HenryDucker_BubbleHead.png",
			3,
			3,
			6,
			4
		)
	]

func create_player(
	id: int,
	pawn_name: String,
	image_path: String,
	bubblehead_path: String,
	move_range: int,
	strength: int,
	reflex: int,
	health: int
) -> Dictionary:
	return {
		"id": id,
		"pawn_name": pawn_name,
		"image_path": image_path,
		"bubblehead_path": bubblehead_path,
		"stats": {
			"move_range": move_range,
			"strength": strength,
			"reflex": reflex,
			"health": health
		},
		"image": load(image_path),
		"bubblehead": load(bubblehead_path)
	}
