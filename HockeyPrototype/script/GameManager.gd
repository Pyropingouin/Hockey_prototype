# ActionFlow

#shoot#
# start shoot
# pre eligible  ----> IceMapLayer.highlight_shoot_target + Devient ActionMode Shoot
# handle action click
# do_shoot
# _shoot player!
# IN PUCK SHOOT
# type de tuile
# goal_type
# active_team_action_counter
# Card_display.GD Selected Pawn ---- MEANING _on_game_manager_pawn_selected
extends Node

enum GameState { PLAYING, GOAL_PAUSE }
enum ActionMode { NONE, SHOOT, PASS, HIT }

var game_state: GameState = GameState.PLAYING
var action_mode: ActionMode = ActionMode.NONE

@onready var ActionManager = $"../ActionManager"

const max_action_counter: int = 4
const PAWN_SCENE := preload("res://scene/pawn.tscn")
const GOALIE_SCENE := preload("res://scene/goalie.tscn")
const RIGHT_NET_POSITION = Vector2i(7, 0)
const LEFT_NET_POSITION = Vector2i(-3, 0)


const SPENT_ENERGY_AMOUNT_TEMPO = 1
const HIT_ENERGY_COST = 1


var _active_team_action_counter: int = 0
var active_team_action_counter:
	get:
		return _active_team_action_counter
	set(value):

		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"active_team_action_counter: %s  -> : %s" % [
				_active_team_action_counter,
				value
			]
		)	

		_active_team_action_counter = value
		active_team_action_counter_changed.emit(_active_team_action_counter)
		actionCounterLabel.text = "Actions: " + str(_active_team_action_counter) + "/" + str(max_action_counter)

		if _active_team_action_counter >= max_action_counter:
			_end_turn()

var _active_team: int = 1
var active_team:
	get:
		return _active_team
	set(value):
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"active_team: %s  -> : %s" % [
				_active_team,
				value
			]
		)	

		_active_team = value
		active_team_changed.emit(_active_team)
		selected_pawn = null
		pawn_selected.emit(selected_pawn)

var _home_team_score := 0
var home_team_score:
	get:
		return _home_team_score
	set(value):

		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"home_team_score: %s  -> : %s" % [
				_home_team_score,
				value
			]
		)	


		_home_team_score = value
		home_team_score_changed.emit(_home_team_score)

var _away_team_score := 0
var away_team_score:
	get:
		return _away_team_score
	set(value):

	
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"away_team_score: %s  -> : %s" % [
				_away_team_score,
				value
			]
		)	

		_away_team_score = value
		away_team_score_changed.emit(_away_team_score)


var _selected_pawn: Node2D = null

var selected_pawn: Node2D:
	get:
		return _selected_pawn
	set(value):
		if _selected_pawn == value:
			return

		_selected_pawn = value

		if is_node_ready():
			_update_current_team_card_display()

		pawn_selected.emit(_selected_pawn)

@onready var activeTeamLabel: Label = $"../ActiveTeamLabel"
@onready var homeTeamScoreLabel: Label = $"../HomeTeamScoreLabel"
@onready var awayTeamScoreLabel: Label = $"../AwayTeamScoreLabel"
@onready var IceMapLayer = $"../IceMapLayer"
@onready var puck := $"../Puck"
@onready var GoalOverlay = $"../GoalOverlay"
@onready var actionCounterLabel = $"../ActionCounterLabel"
@onready var AiController = $"../AiController"

@onready var shoot_button = $"../ActionButtonOverlay/ShootButton"
@onready var pass_button = $"../ActionButtonOverlay/PassButton"
@onready var hit_button = $"../ActionButtonOverlay/HitButton"
@onready var cancel_button = $"../ActionButtonOverlay/CancelButton"
@onready var players_container: Node = $"../PlayersContainer"
@onready var pause_menu: Node = $"../PauseMenuOverlay/PauseMenu"
@onready var current_team_card_display = $"../PlayerCardOverlay/Current_Team_Player_Card_Display"
@onready var opposing_team_card_display = $"../PlayerCardOverlay/Opposing_Team_Player_Card_Display"


var action_pawn: Node2D = null
var hovered_pawn: Node2D = null
var action_origin_cell: Vector2i = Vector2i.ZERO

signal active_team_changed(active_team_id: int)
signal pawn_selected(pawn)
signal home_team_score_changed(home_team_score: int)
signal away_team_score_changed(away_team_score: int)
signal active_team_action_counter_changed(active_team_action_counter: int)

func _ready() -> void:


	DebugLogger.log(
		DebugLogger.DebugType.GAME_MANAGER,
		"Joueurs de l'équipe humaine : %s" % [
			GameData.player_team_selected_players
		]
	)	


	spawn_teams_from_draft()


	active_team_changed.connect(regenActionEconomy)
	active_team_changed.emit(_active_team)
	puck.goal_scored.connect(_on_goal_scored)
	
	# Connexions des boutons UI
	shoot_button.pressed.connect(_start_action_shoot)
	pass_button.pressed.connect(_start_action_pass)
	hit_button.pressed.connect(_start_action_hit)
	cancel_button.pressed.connect(_cancel_action_mode)

	# Labels initiaux
	activeTeamLabel.text = str(_active_team)
	homeTeamScoreLabel.text = str(_home_team_score)
	awayTeamScoreLabel.text = str(_away_team_score)
	actionCounterLabel.text = "Actions: " + str(_active_team_action_counter) + "/" + str(max_action_counter)

	_refresh_action_buttons()

func _on_end_turn_button_pressed() -> void:
	if active_team == 1:
		active_team = 2
	else:
		active_team = 1


	if active_team == 2:

		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"L'équipe active est maintenant : %s" % active_team
		)

		ai_turn()

	activeTeamLabel.text = str(active_team)
	active_team_action_counter = 0


func ai_turn() -> void:
	if active_team == 1:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"ai_turn() annulé : l'équipe active est l'équipe humaine."
		)
		return

	

		
	AiController.turn_inside_ai()




func _cancel_action_mode() -> void:

	if action_pawn != null:
		action_pawn.play_idle_animation()

	action_mode = ActionMode.NONE
	action_pawn = null

	IceMapLayer.clear_highlight()
	IceMapLayer.clear_shot_preview()
	IceMapLayer.clear_pass_preview()



	_refresh_action_buttons()

func _refresh_action_buttons() -> void:

	shoot_button.disabled = true
	pass_button.disabled = true
	hit_button.disabled = true
	cancel_button.disabled = true

	if game_state != GameState.PLAYING:
		return

	if action_mode != ActionMode.NONE:
		cancel_button.disabled = false
		_update_action_buttons_visual()
		return

	if selected_pawn == null:
		_update_action_buttons_visual()
		return

	cancel_button.disabled = false

	if selected_pawn.hasPuck:
		shoot_button.disabled = false
		pass_button.disabled = false
	else:
		hit_button.disabled = false

	_update_action_buttons_visual()




func _start_action_shoot() -> void:
	DebugLogger.log(
		DebugLogger.DebugType.GAME_MANAGER,
		"Début de l'action SHOOT | Pawn sélectionné : %s" % selected_pawn
	)

	if selected_pawn == null:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Shoot refusé : aucun pawn sélectionné."
		)
		return

	if not selected_pawn.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Shoot refusé : le pawn sélectionné n'a pas la rondelle."
		)
		return

	IceMapLayer.clear_shot_preview()
	action_mode = ActionMode.SHOOT
	action_pawn = selected_pawn
	action_origin_cell = selected_pawn.current_cell

	_refresh_action_buttons()

	DebugLogger.log(
		DebugLogger.DebugType.GAME_MANAGER,
		"Calcul des cibles de tir | Origine : %s | Pawn : %s" % [
			action_origin_cell,
			action_pawn
		]
	)

	ActionManager.start_shoot(action_pawn)
	IceMapLayer.highlight_shoot_targets(action_origin_cell, action_pawn, ActionManager.SHOOT_RANGE)

func _start_action_pass() -> void:
	if selected_pawn == null:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Pass refusée : aucun pawn sélectionné."
		)
		return

	if not selected_pawn.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Pass refusée : le pawn sélectionné n'a pas la rondelle."
		)
		return

	action_mode = ActionMode.PASS
	action_pawn = selected_pawn
	action_origin_cell = selected_pawn.current_cell

	IceMapLayer.clear_pass_preview()
	_refresh_action_buttons()
	ActionManager.start_pass(action_pawn)
	IceMapLayer.highlight_pass_targets(action_origin_cell, action_pawn, ActionManager.PASS_RANGE)


func _start_action_hit() -> void:
	if selected_pawn == null:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Hit refusé : aucun pawn sélectionné."
		)
		return

	if selected_pawn.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Hit refusé : le pawn sélectionné a la rondelle."
		)
		return

	action_mode = ActionMode.HIT
	action_pawn = selected_pawn
	action_origin_cell = selected_pawn.current_cell

	_refresh_action_buttons()
	ActionManager.start_hit(action_pawn)
	IceMapLayer.highlight_hit_targets(action_origin_cell, action_pawn)


func _do_shoot(target_cell: Vector2i) -> void:

	if action_pawn == null:
		_cancel_action_mode()
		return


	var shoot_successful: bool = \
		await ActionManager.attempt_shoot(
			action_pawn,
			target_cell
		)


	if not shoot_successful:
		return


	selected_pawn = null

	_cancel_action_mode()

func _do_pass(target_cell: Vector2i) -> void:

	if action_pawn == null:
		_cancel_action_mode()
		return


	var pass_target: Node2D = \
		IceMapLayer.get_pawn_on_cell(target_cell)


	var pass_successful: bool = \
		await ActionManager.attempt_pass(
			action_pawn,
			pass_target
		)


	if not pass_successful:
		return


	selected_pawn = null

	_cancel_action_mode()

func _do_hit(target_cell: Vector2i) -> void:

	if action_pawn == null:
		_cancel_action_mode()
		return


	var hit_target: Node2D = \
		IceMapLayer.get_pawn_on_cell(target_cell)


	var hit_successful: bool = \
		await ActionManager.attempt_hit(
			action_pawn,
			hit_target
		)


	if not hit_successful:
		return


	selected_pawn = null

	_cancel_action_mode()


func _update_action_buttons_visual() -> void:
	shoot_button.update_visual()
	pass_button.update_visual()
	hit_button.update_visual()


func _resolve_shot_against_goalie(
	shooter: Node2D,
	goalie: Goalie
) -> bool:
	DebugLogger.log(
		DebugLogger.DebugType.GAME_MANAGER,
		"%s tire sur %s" % [
			shooter.pawn_name,
			goalie.goalie_name
		]
	)

	shooter.hasPuck = false

	var save_successful: bool = goalie.attempt_save(
		shooter.reflex
	)

	if save_successful:
		_rebound_puck_around_goalie(goalie)
		return false

	_score_goal_against_goalie(goalie)
	return true



func _score_goal_against_goalie(goalie: Goalie) -> void:
	if goalie.team_id == 1:
		# Le filet de l'équipe humaine a été atteint.
		_on_goal_scored("home")
	else:
		# Le filet de l'équipe AI a été atteint.
		_on_goal_scored("away")


func _rebound_puck_around_goalie(goalie: Goalie) -> void:
	# Actualiser les cases occupées avant de choisir le rebond.
	IceMapLayer.update_occupancy()

	var empty_cells: Array[Vector2i] = (
		IceMapLayer.get_usable_surrounding_cells(
			goalie.current_cell
		)
	)

	if empty_cells.is_empty():
		DebugLogger.log(
			DebugLogger.DebugType.GAME_MANAGER,
			"Aucune case vide autour du goalie pour le rebond."
		)
		return

	var rebound_cell: Vector2i = empty_cells.pick_random()

	DebugLogger.log(
		DebugLogger.DebugType.GAME_MANAGER,
		"%s effectue l'arrêt | Rebond de la puck vers : %s" % [
			goalie.goalie_name,
			rebound_cell
		]
	)

	puck.rebound_to_cell(rebound_cell)

	IceMapLayer.update_occupancy()



func spawn_teams_from_draft() -> void:
	for child in players_container.get_children():
		child.queue_free()



	#REVOIR POSITION 	

	var home_start_cells: Array[Vector2i] = [
		Vector2i(3, 0),
		Vector2i(3, -1),
		Vector2i(3, 1),
		Vector2i(4, -1),
		Vector2i(4, 1),
		
	]

	var away_start_cells: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, -1),
		Vector2i(-1, 1),
		
	]

	for i in range(GameData.player_team_selected_players.size()):
		var player_data: Dictionary = GameData.player_team_selected_players[i]
		var pawn = PAWN_SCENE.instantiate()

		var start_cell: Vector2i = home_start_cells[i]

		# Donne d'abord les données au Pawn.
		pawn.setup(player_data, 1, start_cell)

		# Ensuite, le Pawn entre dans l'arbre et exécute _ready().
		players_container.add_child(pawn)

		pawn.hovering_pawn.connect(_on_pawn_hovered)

		IceMapLayer.place_pawn_on_cell(pawn, start_cell)

	for i in range(GameData.opposing_team_selected_players.size()):


		var player_data: Dictionary = GameData.opposing_team_selected_players[i]
		var pawn = PAWN_SCENE.instantiate()

		var start_cell: Vector2i = away_start_cells[i]

		pawn.setup(player_data, 2, start_cell)

		players_container.add_child(pawn)

		pawn.hovering_pawn.connect(_on_pawn_hovered)

		IceMapLayer.place_pawn_on_cell(pawn, start_cell)


	spawn_goalie(
		GameData.player_team_goalie,
		1,
		Vector2i(RIGHT_NET_POSITION)
	)

	spawn_goalie(
		GameData.opposing_team_goalie,
		2,
		Vector2i(LEFT_NET_POSITION)
	)	


func spawn_goalie(
	goalie_data: Dictionary,
	team_id: int,
	start_cell: Vector2i
) -> void:
	var goalie: Goalie = GOALIE_SCENE.instantiate()

	# Le goalie entre d'abord dans l'arbre.
	players_container.add_child(goalie)

	# Les variables @onready sont maintenant disponibles.
	goalie.setup(goalie_data, team_id, start_cell)

	IceMapLayer.place_pawn_on_cell(goalie, start_cell)

func reset_board():
	
	active_team_action_counter = 0

	for pawn in players_container.get_children():
		if pawn.has_method("reset_board"):
			pawn.reset_board()

	puck.reset_board()		

func update_action_counter(action_cost: int):
	active_team_action_counter += action_cost
	
func _end_turn():
	action_mode = ActionMode.NONE
	action_pawn = null
	selected_pawn = null
	active_team_action_counter = 0
	IceMapLayer.clear_highlight()

	_on_end_turn_button_pressed()

	_refresh_action_buttons()

func _on_goal_scored(goal_type):
	DebugLogger.log(
		DebugLogger.DebugType.GAME_MANAGER,
		"But marqué dans le filet de : %s" % goal_type
	)

	if goal_type == "away":
		home_team_score += 1
	elif goal_type == "home":
		away_team_score += 1

	homeTeamScoreLabel.text = str(home_team_score)
	awayTeamScoreLabel.text = str(away_team_score)

	game_state = GameState.GOAL_PAUSE
	GoalOverlay.show()
	_refresh_al_player_energy()
	_refresh_action_buttons()

func _on_continue_button_pressed() -> void:
	GoalOverlay.hide()
	reset_board()
	game_state = GameState.PLAYING
	_refresh_action_buttons()


func _pause_game() -> void:
	get_tree().paused = true


func _on_pawn_hovered(pawn: Node2D) -> void:
	hovered_pawn = pawn

	if hovered_pawn == null:
		opposing_team_card_display.visible = false
		return
	if hovered_pawn.team_id == active_team:
		opposing_team_card_display.visible = false
		return


	_update_opposing_team_card_display(hovered_pawn)


func _update_current_team_card_display() -> void:
	if selected_pawn == null:
		current_team_card_display.visible = false
		current_team_card_display.pawn_name_label.text = ""
		current_team_card_display.pawn_image.texture = null
		return

	current_team_card_display.visible = true

	current_team_card_display.pawn_name_label.text = selected_pawn.pawn_name
	current_team_card_display.pawn_image.texture = selected_pawn.bubbleHeadTexture

	current_team_card_display.pawn_move_range_label.text = \
		"Speed: " + str(selected_pawn.move_range)

	current_team_card_display.pawn_strength_label.text = \
		"Strength: " + str(selected_pawn.strength)

	current_team_card_display.pawn_reflex_label.text = \
		"Reflex: " + str(selected_pawn.reflex)

	current_team_card_display.pawn_health_label.text = \
		"Health: " + str(selected_pawn.health)


func _update_opposing_team_card_display(hovered_pawn: Node2D) -> void:
	
	opposing_team_card_display.visible = true

	opposing_team_card_display.pawn_name_label.text = hovered_pawn.pawn_name
	opposing_team_card_display.pawn_image.texture = hovered_pawn.bubbleHeadTexture

	opposing_team_card_display.pawn_move_range_label.text = \
		"Speed: " + str(hovered_pawn.move_range)

	opposing_team_card_display.pawn_strength_label.text = \
		"Strength: " + str(hovered_pawn.strength)

	opposing_team_card_display.pawn_reflex_label.text = \
		"Reflex: " + str(hovered_pawn.reflex)

	opposing_team_card_display.pawn_health_label.text = \
		"Health: " + str(hovered_pawn.health)		


func regenActionEconomy(current_active_team: int) -> void:
	for player in players_container.get_children():

		if player.team_id != current_active_team:
			continue

		if not player.has_method("regenEnergy"):
			continue

		player.regenEnergy()

func _refresh_al_player_energy() -> void:

	for player in players_container.get_children():

		
		if not player.has_method("regenAllEnergy"):
			continue

		player.regenAllEnergy()
