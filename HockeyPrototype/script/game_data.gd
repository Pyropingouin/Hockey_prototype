extends Node

var player_team_selected_players: Array = []
var opposing_team_selected_players: Array = []

var player_team_goalie: Dictionary = {}
var opposing_team_goalie: Dictionary = {}


func _ready() -> void:
	set_default_teams()
	set_default_opposing_team()
	set_default_player_goalie()
	set_default_opposing_goalie()


func set_default_teams() -> void:
	player_team_selected_players = [
		create_player(
			8,
			"Glorp Thorpe",
			"res://assets/FullBody/DougDogAway.png",
			"res://assets/Bubble_head/GlorpThorpe_BubbleHead.png",
			"res://assets/fullBodyAnimation/DougDog_idle.tres",
			3,
			3,
			6,
			4
		),
		create_player(
			30,
			"Zoran Dew-Fingers",
			"res://assets/FullBody/DougDogAway.png",
			"res://assets/Bubble_head/ZoranDewFingers_BubbleHead.png",
			"res://assets/fullBodyAnimation/DougDog_idle.tres",
			3,
			3,
			6,
			4
		),
		create_player(
			15,
			"Josh Soup",
			"res://assets/FullBody/DougDogAway.png",
			"res://assets/Bubble_head/JoshSoup_BubbleHead.png",
			"res://assets/fullBodyAnimation/DougDog_idle.tres",
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
			"res://assets/FullBody/DougDogAway.png",
			"res://assets/Bubble_head/WaleDeise_BubbleHead.png",
			"res://assets/fullBodyAnimation/DougDog_idle.tres",
			3,
			3,
			6,
			4
		),
		create_player(
			23,
			"Orian Maduro",
			"res://assets/FullBody/DougDogAway.png",
			"res://assets/Bubble_head/OrianMaduro_BubbleHead.png",
			"res://assets/fullBodyAnimation/DougDog_idle.tres",
			3,
			3,
			6,
			4
		),
		create_player(
			11,
			"Henry Ducker",
			"res://assets/FullBody/DougDogAway.png",
			"res://assets/Bubble_head/HenryDucker_BubbleHead.png",
			"res://assets/fullBodyAnimation/DougDog_idle.tres",
			3,
			3,
			6,
			4
		)
	]


func set_default_player_goalie() -> void:
	player_team_goalie = create_goalie(
		100,
		"Glove Johnson",
		"res://assets/personnage/HenryDucker.png",
		"res://assets/Bubble_head/HenryDucker_BubbleHead.png",
		8
	)


func set_default_opposing_goalie() -> void:
	opposing_team_goalie = create_goalie(
		101,
		"Blocko",
		"res://assets/personnage/HenryDucker.png",
		"res://assets/Bubble_head/HenryDucker_BubbleHead.png",
		8
	)


func create_player(
	id: int,
	pawn_name: String,
	image_path: String,
	bubblehead_path: String,
	fullBodyAnimation_path: String,
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
		"fullBodyAnimation_path": fullBodyAnimation_path,

		"stats": {
			"move_range": move_range,
			"strength": strength,
			"reflex": reflex,
			"health": health
		},

		"image": load(image_path),
		"bubblehead": load(bubblehead_path),
		"fullBodyAnimation": load(fullBodyAnimation_path)
	}


func create_goalie(
	id: int,
	goalie_name: String,
	image_path: String,
	bubblehead_path: String,
	save_power: int
) -> Dictionary:
	return {
		"id": id,
		"goalie_name": goalie_name,
		"save_power": save_power,
		"image": load(image_path),
		"bubblehead": load(bubblehead_path)
	}