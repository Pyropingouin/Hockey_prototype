extends Node

const PLAYER_JSON_PATH := "res://data/players.json"
const GOALIE_JSON_PATH := "res://data/goalies.json"

var player_team_selected_players: Array = []
var opposing_team_selected_players: Array = []

var player_team_goalie: Dictionary = {}
var opposing_team_goalie: Dictionary = {}




func _ready() -> void:
	var players := load_players()


	if not players.is_empty():
		DebugLogger.log(
					DebugLogger.DebugType.SETUP,
					"SETUP: %s" % players[0]
					)	
	


	# set_random_quickplay_teams()
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

	var image_path: String = player.get("image_path", "")
	var bubblehead_path: String = player.get("bubblehead_path", "")
	var animation_path: String = player.get("animationResourcePath", "")



	if not image_path.is_empty():
		player["image"] = load(image_path)

	if not bubblehead_path.is_empty():
		player["bubblehead"] = load(bubblehead_path)

	if not animation_path.is_empty():
		var animation_resource = load(animation_path)

		if animation_resource is SpriteFrames:
			player["animationResource"] = animation_resource
		else:
			push_error(
				"L'animation de %s n'est pas un SpriteFrames : %s"
				% [
					player.get("pawn_name", "Unknown"),
					animation_path
				]
			)

	return player


	
func load_goalies() -> Array:
	if not FileAccess.file_exists(GOALIE_JSON_PATH):
		push_error("Goalies.json introuvable : %s" % GOALIE_JSON_PATH)
		return []

	var file := FileAccess.open(GOALIE_JSON_PATH, FileAccess.READ)

	if file == null:
		push_error("Impossible d'ouvrir Goalies.json")
		return []



	var goalies = JSON.parse_string(file.get_as_text())

	if not goalies is Array:
		push_error("Goalies.json doit contenir un Array")
		return []

	var prepared_goalies: Array = []

	for goalie_data in goalies:
		if goalie_data is Dictionary:
			prepared_goalies.append(prepare_goalie(goalie_data))

	return prepared_goalies			



func prepare_goalie(goalie_data: Dictionary) -> Dictionary:
	var goalie: Dictionary = goalie_data.duplicate(true)

	
	goalie["save_power"] = int(goalie.get("stats", {}).get("reflex", 0))

	var bubblehead_path: String = goalie.get("bubblehead_path", "")

	if not bubblehead_path.is_empty():
		goalie["bubblehead"] = load(bubblehead_path)

	return goalie	



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




# func set_TEST_quickplay_teams() -> void:
# 	var players: Array = load_players()

# 	if players.size() < 6:
# 		push_error(
# 			"Il faut au moins 6 joueurs pour le Quick Play"
# 		)
# 		return

# 	player_team_selected_players = [
# 		players[0],
# 		players[2],
# 		players[3]
# 	]

# 	opposing_team_selected_players = [
# 		players[4],
# 		players[5],
# 		players[6]
# 	]		



func set_default_player_goalie() -> void:
	var goalies: Array = load_goalies()
	
	for goalie in goalies:
		if int(goalie["id"]) == 102:
			player_team_goalie = goalie
			return

	push_error("Gardien HOME introuvable.")		
	


func set_default_opposing_goalie() -> void:
	var goalies: Array = load_goalies()
	
	for goalie in goalies:
		if int(goalie["id"]) == 104:
			opposing_team_goalie = goalie
			return

	push_error("Gardien AWAY introuvable.")		
