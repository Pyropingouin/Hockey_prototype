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

const max_action_counter: int = 4
const PAWN_SCENE := preload("res://scene/pawn.tscn")

var _active_team_action_counter: int = 0
var active_team_action_counter:
	get:
		return _active_team_action_counter
	set(value):
		print("active_team_action_counter:", _active_team_action_counter, "->", value)
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
		print("active_team:", _active_team, "->", value)
		_active_team = value
		active_team_changed.emit(_active_team)
		selected_pawn = null
		pawn_selected.emit(selected_pawn)

var _home_team_score := 0
var home_team_score:
	get:
		return _home_team_score
	set(value):
		print("home_team_score:", _home_team_score, "->", value)
		_home_team_score = value
		home_team_score_changed.emit(_home_team_score)

var _away_team_score := 0
var away_team_score:
	get:
		return _away_team_score
	set(value):
		print("away_team_score:", _away_team_score, "->", value)
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

var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cell: Vector2i = Vector2i.ZERO
var drag_candidate: Node2D = null
var active_pawn: Node2D = null
var is_dragging := false


var action_pawn: Node2D = null
var hovered_pawn: Node2D = null
var action_origin_cell: Vector2i = Vector2i.ZERO

signal active_team_changed(active_team_id: int)
signal pawn_selected(pawn)
signal home_team_score_changed(home_team_score: int)
signal away_team_score_changed(away_team_score: int)
signal active_team_action_counter_changed(active_team_action_counter: int)

func _ready() -> void:

	print(GameData.player_team_selected_players)

	spawn_teams_from_draft()


	
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
		print("TEAM 2")
		print("active_team", active_team)
		ai_turn()

	activeTeamLabel.text = str(active_team)


func ai_turn() -> void:
	if active_team == 1:
		print("BUG")
		return

	

		
	AiController.turn_inside_ai()

	print("FIN AI TURN")	




func _cancel_action_mode() -> void:
	# Soit disable le bouton si on est pas dans un action
	# soit permettre de ne plus selectionner le joueurs

	action_mode = ActionMode.NONE
	action_pawn = null
	IceMapLayer.clear_highlight()
	_refresh_action_buttons()

func _refresh_action_buttons() -> void:

	
	shoot_button.disabled = true
	pass_button.disabled = true
	hit_button.disabled = true
	cancel_button.disabled = true

	# Pendant pause but: tout désactivé
	if game_state != GameState.PLAYING:
		return

	# S'il y a un mode d'action actif, seul cancel reste actif
	if action_mode != ActionMode.NONE:
		cancel_button.disabled = false
		return

	# Aucun joueur sélectionné
	if selected_pawn == null:
		return

	# Joueur sélectionné, mode normal
	cancel_button.disabled = false

	if selected_pawn.hasPuck:
		shoot_button.disabled = false
		pass_button.disabled = false
	else:
		hit_button.disabled = false


	shoot_button.update_visual()
	pass_button.update_visual()
	hit_button.update_visual()
	# cancel_button.update_visual()	




func _start_action_shoot() -> void:
	print("start shoot")
	print("selected_pawn = ", selected_pawn)
	print("hasPuck = ", selected_pawn.hasPuck if selected_pawn != null else "NO PAWN")

	if selected_pawn == null or not selected_pawn.hasPuck:
		return

	action_mode = ActionMode.SHOOT
	action_pawn = selected_pawn
	action_origin_cell = selected_pawn.current_cell

	_refresh_action_buttons()

	print("pre eligible", action_origin_cell, action_pawn)
	IceMapLayer.highlight_shoot_targets(action_origin_cell, action_pawn)

func _start_action_pass() -> void:
	if selected_pawn == null or not selected_pawn.hasPuck:
		return

	action_mode = ActionMode.PASS
	action_pawn = selected_pawn
	action_origin_cell = selected_pawn.current_cell

	_refresh_action_buttons()
	IceMapLayer.highlight_pass_targets(action_origin_cell, action_pawn)


func _start_action_hit() -> void:
	if selected_pawn == null or selected_pawn.hasPuck:
		return

	action_mode = ActionMode.HIT
	action_pawn = selected_pawn
	action_origin_cell = selected_pawn.current_cell

	_refresh_action_buttons()
	IceMapLayer.highlight_hit_targets(action_origin_cell, action_pawn)


func _do_shoot(target_cell: Vector2i) -> void:
	print("do_shoot")

	if action_pawn == null or not action_pawn.hasPuck:
		_cancel_action_mode()
		return

	action_origin_cell = action_pawn.current_cell

	if not _is_in_shoot_range(
		action_origin_cell,
		target_cell,
		action_pawn
	):
		print("Tir refusé : cible hors de portée.")
		_cancel_action_mode()
		return

	if not IceMapLayer.is_shot_path_clear(
		action_origin_cell,
		target_cell
	):
		print("Tir refusé : un joueur bloque la trajectoire.")
		return

	if IceMapLayer.get_pawn_on_cell(target_cell) != null:
		print("Tir refusé : la case ciblée est occupée.")
		return

	if action_pawn.has_method("_shoot"):
		action_pawn._shoot(target_cell)
		selected_pawn = null

	update_action_counter(1)
	IceMapLayer.update_occupancy()
	_cancel_action_mode()

func _do_pass(target_cell: Vector2i) -> void:
	if action_pawn == null or not action_pawn.hasPuck:
		_cancel_action_mode()
		return

	action_origin_cell = active_pawn.current_cell

	if not _is_in_shoot_range(action_origin_cell, target_cell, action_pawn):
		print("PASS target oustide of range")
		_cancel_action_mode()
		return

	var receiver: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

	if receiver == null:
		print("Passe refusée: aucun pawn sur la case visée.")
		return

	if receiver == action_pawn:
		print("Passe refusée: tu ne peux pas te passer à toi-même.")
		return

	if action_pawn.has_method("_pass"):
		action_pawn._pass(target_cell)
		selected_pawn = null	

	emit_signal("pawn_selected", selected_pawn)
	update_action_counter(1)
	IceMapLayer.update_occupancy()
	_cancel_action_mode()

func _do_hit(target_cell: Vector2i) -> void:
	if action_pawn == null or action_pawn.hasPuck:
		_cancel_action_mode()
		return

	var hitTarget: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

	if hitTarget == null:
		print("Plaquage refusé: aucun pawn sur la case visée.")
		return

	if hitTarget == action_pawn:
		print("Plaquage: tu ne peux pas te plaquer toi-même.")
		return

	if action_pawn.has_method("_hit"):
		action_pawn._hit(target_cell)

	update_action_counter(1)
	IceMapLayer.update_occupancy()
	_cancel_action_mode()

func _is_in_shoot_range(
	origin_cell: Vector2i,
	target_cell: Vector2i,
	received_pawn: Node2D
) -> bool:
	var shoot_range: int = received_pawn.move_range * 2

	var distance: int = IceMapLayer.get_hex_distance(
		origin_cell,
		target_cell
	)

	return distance > 0 and distance <= shoot_range




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

		players_container.add_child(pawn)

		pawn.hovering_pawn.connect(_on_pawn_hovered)

		var start_cell: Vector2i = home_start_cells[i]
		pawn.setup(player_data, 1, start_cell)
		IceMapLayer.place_pawn_on_cell(pawn, start_cell)

	for i in range(GameData.opposing_team_selected_players.size()):


		var player_data: Dictionary = GameData.opposing_team_selected_players[i]
		var pawn = PAWN_SCENE.instantiate()

		players_container.add_child(pawn)

		pawn.hovering_pawn.connect(_on_pawn_hovered)

		var start_cell: Vector2i = away_start_cells[i]
		pawn.setup(player_data, 2, start_cell)
		IceMapLayer.place_pawn_on_cell(pawn, start_cell)


func reset_board():
	puck.reset_board()
	active_team_action_counter = 0

	

	for pawn in players_container.get_children():
		if pawn.has_method("reset_board"):
			pawn.reset_board()

func update_action_counter(action_cost: int):
	active_team_action_counter += action_cost

func _end_turn():
	# Nettoyage de l'état de tour
	action_mode = ActionMode.NONE
	action_pawn = null
	active_pawn = null
	# target_pawn = null
	drag_candidate = null
	is_dragging = false
	active_team_action_counter = 0
	IceMapLayer.clear_highlight()

	_on_end_turn_button_pressed()

	_refresh_action_buttons()

func _on_goal_scored(goal_type):
	print("But marqué dans le filet de: ", goal_type)

	if goal_type == "away":
		home_team_score += 1
	elif goal_type == "home":
		away_team_score += 1

	homeTeamScoreLabel.text = str(home_team_score)
	awayTeamScoreLabel.text = str(away_team_score)

	game_state = GameState.GOAL_PAUSE
	GoalOverlay.show()
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
	current_team_card_display.pawn_image.texture = selected_pawn.fullBodyTexture

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
	opposing_team_card_display.pawn_image.texture = hovered_pawn.fullBodyTexture

	opposing_team_card_display.pawn_move_range_label.text = \
		"Speed: " + str(hovered_pawn.move_range)

	opposing_team_card_display.pawn_strength_label.text = \
		"Strength: " + str(hovered_pawn.strength)

	opposing_team_card_display.pawn_reflex_label.text = \
		"Reflex: " + str(hovered_pawn.reflex)

	opposing_team_card_display.pawn_health_label.text = \
		"Health: " + str(hovered_pawn.health)		