extends Node2D


const DRAFT_CARD_SCENE := preload("res://scene/draft_card.tscn")
const PLAYERS_DB_PATH := "res://data/players.json"

@onready var card_container: HBoxContainer  = $CardContainer


func _ready() -> void:

	var players = load_players()
	

	for player in players:
		var card = DRAFT_CARD_SCENE.instantiate()
		card_container.add_child(card)
		card.setup(player)
		card.card_clicked.connect(_on_card_clicked)



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
	



func _on_card_clicked(clicked_card_id: int) -> void:
	print("Carte cliquée :", clicked_card_id)
