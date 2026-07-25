extends Node

const PLAYER_JSON_PATH := "res://data/players.json"

var player_team_selected_players: Array = []
var opposing_team_selected_players: Array = []

var player_team_goalie: Dictionary = {}
var opposing_team_goalie: Dictionary = {}




func _ready() -> void:
	var players := load_players()

	print("Nombre de joueurs : ", players.size())

	if not players.is_empty():
		print(players[0])


	set_random_quickplay_teams()
	set_default_player_goalie()
	set_default_opposing_goalie()		



func load_players() -> Array:
	if not FileAccess.file_exists(PLAYER_JSON_PATH):
		push_error(
			"Player.json introuvable : %s"
			% PLAYER_JSON_PATH
		)
		return []

	var file := FileAccess.open(
		PLAYER_JSON_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("Impossible d'ouvrir Player.json")
		return []

	var json_text := file.get_as_text()
	var players = JSON.parse_string(json_text)

	if players == null:
		push_error("Erreur lors de la lecture de Player.json")
		return []

	if not players is Array:
		push_error("Player.json doit contenir un Array")
		return []

	var prepared_players: Array = []

	for player_data in players:
		if player_data is Dictionary:
			prepared_players.append(
				prepare_player(player_data)
			)

	return prepared_players	



func prepare_player(player_data: Dictionary) -> Dictionary:
	var player := player_data.duplicate(true)

	var image_path: String = player.get(
		"image_path",
		""
	)

	var bubblehead_path: String = player.get(
		"bubblehead_path",
		""
	)

	var animation_path: String = player.get(
		"fullBodyAnimation_path",
		""
	)

	if not image_path.is_empty():
		player["image"] = load(image_path)

	if not bubblehead_path.is_empty():
		player["bubblehead"] = load(bubblehead_path)

	if not animation_path.is_empty():
		player["fullBodyAnimation"] = load(animation_path)

	return player



func set_random_quickplay_teams() -> void:
	var players: Array = load_players()

	if players.size() < 6:
		push_error(
			"Il faut au moins 6 joueurs pour le Quick Play"
		)
		return

	players.shuffle()

	player_team_selected_players = [
		players[0],
		players[1],
		players[2]
	]

	opposing_team_selected_players = [
		players[3],
		players[4],
		players[5]
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