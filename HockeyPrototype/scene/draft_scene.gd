extends Node2D


const DRAFT_CARD_SCENE := preload("res://scene/draft_card.tscn")
const PLAYERS_DB_PATH := "res://data/players.json"
const DRAFT_CHOICES_COUNT := 3


var player_pool: Array = []          
var current_draft_choices: Array = []

var player_team_selected_players: Array = []
var opposing_team_selected_players: Array = []

@onready var card_container: HBoxContainer  = $CardContainer


func _ready() -> void:

	player_pool = load_players()
	player_pool.shuffle()
	show_new_draft_choices()
	



func show_new_draft_choices() -> void:
	clear_current_cards()

	current_draft_choices.clear()

	var number_to_draw = min(DRAFT_CHOICES_COUNT, player_pool.size())


	for i in range(number_to_draw):
		var player = player_pool.pop_front()
		current_draft_choices.append(player)

		var card = DRAFT_CARD_SCENE.instantiate()
		card_container.add_child(card)
		card.setup(player)
		card.card_clicked.connect(_on_card_clicked)

	print("Joueurs restants dans le pool :", player_pool.size())
	




func clear_current_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()



func load_players() -> Array:
	var file := FileAccess.open(PLAYERS_DB_PATH, FileAccess.READ)

	if file == null:
		push_error("Impossible d'ouvrir la DB de joueurs : " + PLAYERS_DB_PATH)
		return []

	var content := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(content)

	if error != OK:
		push_error("Erreur JSON : " + json.get_error_message())
		return []

	var data = json.data

	for player in data:
		if player.has("image_path"):
			player["image"] = load(player["image_path"])

	return data
	



func _on_card_clicked(selected_player: Dictionary) -> void:
	player_team_selected_players.append(selected_player)
	print("Joueur ajouté à ton équipe :", selected_player["pawn_name"])

	var remaining_choices := []

	for player in current_draft_choices:
		if player["id"] != selected_player["id"]:
			remaining_choices.append(player)

	if remaining_choices.size() > 0:
		remaining_choices.shuffle()
		var opposing_player = remaining_choices[0]
		opposing_team_selected_players.append(opposing_player)
		print("Joueur ajouté à l'équipe adverse :", opposing_player["pawn_name"])

	print("Ton équipe :", player_team_selected_players.size())
	print("Équipe adverse :", opposing_team_selected_players.size())

	show_new_draft_choices()