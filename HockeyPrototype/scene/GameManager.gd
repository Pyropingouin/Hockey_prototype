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
const DRAG_THRESHOLD_PX := 12.0

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

@onready var activeTeamLabel: Label = $"../ActiveTeamLabel"
@onready var homeTeamScoreLabel: Label = $"../HomeTeamScoreLabel"
@onready var awayTeamScoreLabel: Label = $"../AwayTeamScoreLabel"
@onready var IceMapLayer = $"../IceMapLayer"
@onready var puck := $"../Puck"
@onready var GoalOverlay = $"../GoalOverlay"
@onready var actionCounterLabel = $"../ActionCounterLabel"

@onready var shoot_button = $"../ActionButtonOverlay/ShootButton"
@onready var pass_button = $"../ActionButtonOverlay/PassButton"
@onready var hit_button = $"../ActionButtonOverlay/HitButton"
@onready var cancel_button = $"../ActionButtonOverlay/CancelButton"

var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cell: Vector2i = Vector2i.ZERO
var drag_candidate: Node2D = null
var active_pawn: Node2D = null
var is_dragging := false

var target_pawn: Node2D = null
var action_pawn: Node2D = null
var selected_pawn: Node2D = null
var action_origin_cell: Vector2i = Vector2i.ZERO

signal active_team_changed(active_team_id: int)
signal pawn_selected(pawn)
signal home_team_score_changed(home_team_score: int)
signal away_team_score_changed(away_team_score: int)
signal active_team_action_counter_changed(active_team_action_counter: int)

func _ready() -> void:
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

func _process(delta: float) -> void:
	pass

func _on_end_turn_button_pressed() -> void:
	if active_team == 1:
		active_team = 2
	else:
		active_team = 1

	activeTeamLabel.text = str(active_team)

func _unhandled_input(event: InputEvent) -> void:
	if game_state != GameState.PLAYING:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_left_mouse_down(event.position)
		else:
			_on_left_mouse_up(event.position)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_on_right_mouse_down(event.position)
		else:
			_on_right_mouse_up(event.position)

	if event.is_action_pressed("ui_cancel") and action_mode != ActionMode.NONE:
		_cancel_action_mode()
		return

	if event is InputEventMouseMotion and drag_candidate:
		_on_mouse_drag(event.position)

func _on_left_mouse_down(global_pos: Vector2) -> void:
	if action_mode != ActionMode.NONE:
		_handle_action_click(global_pos)
		return

	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	

	active_pawn = null
	drag_candidate = IceMapLayer.pawn_at_cell(cell)

	if drag_candidate == null:
		selected_pawn = null
		print("_on_left_mouse_down if drag_candidate")
		emit_signal("pawn_selected", selected_pawn)
		_refresh_action_buttons()
		return

	if drag_candidate.team_id != active_team:
		drag_candidate = null
		_refresh_action_buttons()
		return

	active_pawn = drag_candidate
	selected_pawn = drag_candidate

	
	print("_on_left_mouse_down")	
	emit_signal("pawn_selected", selected_pawn)
	drag_start_cell = active_pawn.current_cell
	drag_start_mouse_pos = global_pos
	is_dragging = false

	_refresh_action_buttons()

func _on_left_mouse_up(global_pos: Vector2) -> void:
	if active_pawn == null:
		drag_candidate = null
		_refresh_action_buttons()
		return

	if not is_dragging:
		
		# selected_pawn = active_pawn
		
		print("_on_left_mouse_UP if not dragging")
		# emit_signal("pawn_selected", selected_pawn)
		


		#Faire une variable selected_Pawn
		#l'envoyer au pawn pour lui dire qu'il est sélectionner
			#faire tourner le ring dans le pawn si selected
		#l'envoyer au card display aussu	
		#Tant qu'il est selected, on change pas
		#Si PLUS selected, 
			#dire au selected Pawn qu'il n'est plus selected
		#Selected_pawn = null
			#dire au card display que selected pawn = null
			
		#Qu'est-ce qui trigger la fin du selected pawn?
		#1) Selecté un autre pawn
		#2) juste cancel le présent pawn (Click à coté??)
		
			
		
			
			
			
		
		
		_refresh_action_buttons()
		_cleanup_drag()
		return

	is_dragging = false

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if IceMapLayer.can_move_pawn_to(active_pawn, drag_start_cell, target_cell):
		IceMapLayer.apply_move(active_pawn, drag_start_cell, target_cell)
	else:
		IceMapLayer.reset_move(active_pawn, drag_start_cell)

	update_action_counter(1)
	IceMapLayer.clear_highlight()
	_cleanup_drag()
	_refresh_action_buttons()

func _on_right_mouse_down(global_pos: Vector2) -> void:
	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if action_mode != ActionMode.NONE:
		_cancel_action_mode()
	

	target_pawn = null
	target_pawn = IceMapLayer.pawn_at_cell(cell)

	if (target_pawn == null):
		selected_pawn = null
		print("_on_right_mouse_down if target_pawn = null")
		emit_signal("pawn_selected", selected_pawn)

	print("Target_Pawn = ", target_pawn)
	

func _on_right_mouse_up(global_pos: Vector2) -> void:
	print("left up")
	print(global_pos)

func _on_mouse_drag(global_pos: Vector2) -> void:
	if active_pawn == null:
		return

	if not is_dragging:
		var dist := drag_start_mouse_pos.distance_to(global_pos)
		if dist < DRAG_THRESHOLD_PX:
			return

		is_dragging = true
		IceMapLayer.highlight_unreachable_from(drag_start_cell, active_pawn.move_range)
		print("_on_mouse_drag")
		emit_signal("pawn_selected", selected_pawn)
		_refresh_action_buttons()

	active_pawn.global_position = global_pos

func _cleanup_drag() -> void:
	drag_candidate = null

func _handle_action_click(global_pos: Vector2) -> void:
	print("handle action click")

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if IceMapLayer.get_ice_map_layer_cell_id(target_cell) == -1:
		_cancel_action_mode()
		return

	match action_mode:
		ActionMode.SHOOT:
			_do_shoot(target_cell)
		ActionMode.PASS:
			_do_pass(target_cell)
		ActionMode.HIT:
			_do_hit(target_cell)

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
	if active_pawn == null:
		return

	# Joueur sélectionné, mode normal
	cancel_button.disabled = false

	if active_pawn.hasPuck:
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

	if active_pawn == null or not active_pawn.hasPuck:
		return

	action_mode = ActionMode.SHOOT
	action_pawn = active_pawn
	action_origin_cell = active_pawn.current_cell

	_refresh_action_buttons()

	print("pre eligible", action_origin_cell, action_pawn)
	IceMapLayer.highlight_shoot_targets(action_origin_cell, action_pawn)


func _start_action_pass() -> void:
	if active_pawn == null or not active_pawn.hasPuck:
		return

	action_mode = ActionMode.PASS
	action_pawn = active_pawn
	action_origin_cell = active_pawn.current_cell

	_refresh_action_buttons()

	IceMapLayer.highlight_pass_targets(action_origin_cell, action_pawn)


func _start_action_hit() -> void:
	if active_pawn == null or active_pawn.hasPuck:
		return

	action_mode = ActionMode.HIT
	action_pawn = active_pawn
	action_origin_cell = active_pawn.current_cell

	_refresh_action_buttons()

	IceMapLayer.highlight_hit_targets(action_origin_cell, action_pawn)


func _do_shoot(target_cell: Vector2i) -> void:
	print("do_shoot")

	if action_pawn == null or not action_pawn.hasPuck:
		_cancel_action_mode()
		return

	action_origin_cell = active_pawn.current_cell

	if not _is_in_shoot_range(action_origin_cell, target_cell, action_pawn):
		print("Shoot target oustide of range")
		_cancel_action_mode()
		return

	if IceMapLayer.get_pawn_on_cell(target_cell) != null:
		print("Shoot refusé: case occupée par un pawn.")
		return

	if action_pawn.has_method("_shoot"):
		action_pawn._shoot(target_cell)
		selected_pawn = null	


		

	emit_signal("pawn_selected", selected_pawn)
	
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

func _is_in_shoot_range(orgin_cell, target_cell, recieved_pawn):
	var _range: int = recieved_pawn.move_range * 2
	var dist: int = abs(target_cell.x - orgin_cell.x) + abs(target_cell.y - orgin_cell.y)

	if dist == 0 or dist > _range:
		return false
	else:
		return true

func reset_board():
	puck.reset_board()

func update_action_counter(action_cost: int):
	active_team_action_counter += action_cost

func _end_turn():
	# Nettoyage de l'état de tour
	action_mode = ActionMode.NONE
	action_pawn = null
	active_pawn = null
	target_pawn = null
	drag_candidate = null
	is_dragging = false
	IceMapLayer.clear_highlight()

	_on_end_turn_button_pressed()
	active_team_action_counter = 0
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
