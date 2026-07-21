extends Node2D


const DRAFT_CARD_SCENE := preload("res://scene/player_card_template.tscn")
const PLAYERS_DB_PATH := "res://data/players.json"
const DRAFT_CHOICES_COUNT := 3
const DRAFT_CARDS_NUMBER_LIMIT:= 2


var player_pool: Array = []          
var current_draft_choices: Array = []

var player_team_selected_players: Array = []
var opposing_team_selected_players: Array = []

@onready var card_container: HBoxContainer  = $CardContainer
@onready var player_team_selected_players_container: HBoxContainer  = $HomeTeamContainer
@onready var pause_menu: Node = $"PauseMenuOverlay/PauseMenu"

func _ready() -> void:

	player_pool = load_players()
	player_pool.shuffle()
	show_new_draft_choices()
	


func show_new_draft_choices() -> void:
	clear_current_cards()

	current_draft_choices.clear()

	var number_to_draw = min(DRAFT_CHOICES_COUNT, player_pool.size())

	if player_team_selected_players.size() <= DRAFT_CARDS_NUMBER_LIMIT:

		for i in range(number_to_draw):
			var player = player_pool.pop_front()
			current_draft_choices.append(player)

			var card = DRAFT_CARD_SCENE.instantiate()
			card_container.add_child(card)
			card.setup(player)
			card.card_clicked.connect(_on_card_clicked)

	else:
		$EndDraftButton.visible = true

	DebugLogger.log(
					DebugLogger.DebugType.DRAFT,
					"Joueurs restants dans le pool : %s" % player_pool.size()
					)				

	




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

		if player.has("bubblehead_path"):
			player["bubblehead"] = load(player["bubblehead_path"])	

	return data
	



func _on_card_clicked(selected_player: Dictionary) -> void:
	player_team_selected_players.append(selected_player)

	DebugLogger.log(
					DebugLogger.DebugType.DRAFT,
					"Joueur ajouté à ton équipe : %s" % selected_player["pawn_name"]
					)	

	


	refresh_player_team_display()

	var remaining_choices := []

	for player in current_draft_choices:
		if player["id"] != selected_player["id"]:
			remaining_choices.append(player)

	if remaining_choices.size() > 0:
		remaining_choices.shuffle()
		var opposing_player = remaining_choices[0]
		opposing_team_selected_players.append(opposing_player)



		DebugLogger.log(
						DebugLogger.DebugType.DRAFT,
						"Joueur ajouté à l'équipe adverse : %s" % opposing_player["pawn_name"]
						)	


		DebugLogger.log(
			DebugLogger.DebugType.DRAFT,
			"Taille de ton équipe :: %s | Taille équipe adverse %s" % [
				player_team_selected_players.size(),
				opposing_team_selected_players.size()
			]
		)	

	show_new_draft_choices()

func refresh_player_team_display() -> void:
	for child in player_team_selected_players_container.get_children():
		child.queue_free()


# Pour le visuel du player container
	for player in player_team_selected_players:
		var image := TextureRect.new()
		image.texture = player["image"]
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.custom_minimum_size = Vector2(128, 128)

		player_team_selected_players_container.add_child(image)





func _on_end_draft_button_pressed() -> void:
	
	GameData.player_team_selected_players = player_team_selected_players
	GameData.opposing_team_selected_players = opposing_team_selected_players

	DebugLogger.log(
					DebugLogger.DebugType.DRAFT,
					"End Draft Button : %s" % player_team_selected_players
					)	




	

	get_tree().change_scene_to_file("res://scene/Game_Scene.tscn")


func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_cancel"):
		_pause_game()
		pause_menu.visible = true

func _pause_game() -> void:
	get_tree().paused = true
