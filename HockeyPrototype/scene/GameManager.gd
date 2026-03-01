extends Node

var _active_team: int = 1
var active_team:
	get:
		return _active_team
	set(value):
		print("active_team:", _active_team, "->", value)
		_active_team = value
		#Signal émit à chaque changement
		active_team_changed.emit(_active_team)

var _home_team_score = 0
var home_team_score:
	get:
		return _home_team_score
	set(value):
		print("home_team_score:", home_team_score, "->", value)
		home_team_score = value
		#Signal émit à chaque changement
		home_team_score_changed.emit(home_team_score)

var _away_team_score = 0
var away_team_score:
	get:
		return _away_team_score
	set(value):
		print("away_team_score:", _away_team_score, "->", value)
		_away_team_score = value
		#Signal émit à chaque changement
		away_team_score_changed.emit(_away_team_score)		




@onready var activeTeamLabel: Label = $"../ActiveTeamLabel"
@onready var IceMapLayer = $"../IceMapLayer"
@onready var action_menu = $"../CanvasLayer/PopupMenu"
@onready var puck := $"../Puck"

const DRAG_THRESHOLD_PX := 12.0
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cell: Vector2i = Vector2i.ZERO
var drag_candidate: Node2D = null
var active_pawn: Node2D = null
var is_dragging := false


var target_pawn: Node2D = null
var action_pawn: Node2D = null
var action_origin_cell: Vector2i = Vector2i.ZERO


var action_mode: ActionMode = ActionMode.NONE


enum ActionMode { NONE, SHOOT, PASS, HIT }

signal active_team_changed(active_team_id: int)
signal pawn_selected(pawn)
signal home_team_score_changed(home_team_score: int)
signal away_team_score_changed(away_team_score: int)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_team_changed.emit(_active_team)
	action_menu.id_pressed.connect(_on_action_menu_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_end_turn_button_pressed() -> void:
	if(active_team) == 1:
		active_team = 2
	else:
		active_team = 1		
		
	activeTeamLabel.text = str(active_team)		
	

func _unhandled_input(event: InputEvent) -> void:
	# 1) Clic / relâche
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
		# _cancel_action_mode()
		return
				

	# 2) Mouvement pendant drag
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
		return
	if drag_candidate.team_id != active_team:
		return	

	active_pawn = drag_candidate
	drag_start_cell = active_pawn.current_cell
	drag_start_mouse_pos = global_pos
	is_dragging = false  # IMPORTANT: pas encore en drag



func _on_left_mouse_up(global_pos: Vector2) -> void:
	if active_pawn == null:
		drag_candidate = null
		return

	# Clic sans drag
	if not is_dragging:
		emit_signal("pawn_selected", active_pawn)
		_cleanup_drag()
		return

	is_dragging = false

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if IceMapLayer.can_move_pawn_to(active_pawn, drag_start_cell, target_cell):
		IceMapLayer.apply_move(active_pawn, drag_start_cell, target_cell)
	else:
		IceMapLayer.reset_move(active_pawn, drag_start_cell)

	IceMapLayer.clear_highlight() # si tu exposes clear_highlight() public
	_cleanup_drag()


	
	
func _on_right_mouse_down(global_pos: Vector2) -> void:
	
	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	target_pawn = null
	 #On cherche s'il y a un pion sur cette case
	target_pawn = IceMapLayer.pawn_at_cell(cell)
		
			
	print ("Target_Pawn = ",target_pawn)
	_open_context_menu(global_pos)
	

func _on_right_mouse_up(global_pos: Vector2) -> void:
	print ("left up")
	print (global_pos)		
	
func _on_mouse_drag(global_pos: Vector2) -> void:
	if active_pawn == null:
		return

	# Si on n'a pas encore commencé le drag, vérifier le threshold
	if not is_dragging:
		var dist := drag_start_mouse_pos.distance_to(global_pos)
		if dist < DRAG_THRESHOLD_PX:
			return

		# On démarre officiellement le drag ici
		is_dragging = true
		IceMapLayer.highlight_unreachable_from(drag_start_cell, active_pawn.move_range)
		emit_signal("pawn_selected", active_pawn)

	# Drag actif: le pion suit la souris
	active_pawn.global_position = global_pos


func _cleanup_drag() -> void:
	#active_pawn = null
	drag_candidate = null

func _handle_action_click(global_pos: Vector2) -> void:
	print("handle action click")

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

 	# 1) la cellule doit exister
	if IceMapLayer.get_ice_map_layer_cell_id(target_cell) == -1:
		_cancel_action_mode()
		return

 	# 2) selon le mode
	match action_mode:
		
		ActionMode.SHOOT:
			_do_shoot(target_cell)
		ActionMode.PASS:
			_do_pass(target_cell)
		ActionMode.HIT:
			_do_hit(target_cell)

func _cancel_action_mode() -> void:
	action_mode = ActionMode.NONE
	action_pawn = null
	IceMapLayer.clear_highlight() # si tu highlights des cibles	
	

func _open_context_menu(screen_pos: Vector2) -> void:
	
	action_menu.clear()
	
	action_menu.add_item("Plaquer", 0)
	action_menu.add_item("Passer", 1)
	action_menu.add_item("Shoot", 2)
	action_menu.add_item("Annulé", 3)
	
	if !active_pawn:
		print("pas active pawn")
		return
		
	if !active_pawn.	hasPuck:
		action_menu.set_item_disabled(1, true)
		action_menu.set_item_disabled(2, true)
		
#Si le joueur target est null OU même équipe que active, peut pas plaquer		
	if target_pawn == null || target_pawn.team_id == active_pawn.team_id:
		action_menu.set_item_disabled(0, true)
	
	if target_pawn == null || target_pawn.team_id != active_pawn.team_id:
		action_menu.set_item_disabled(1, true)

	action_menu.position = screen_pos
	action_menu.popup()
	
func _on_action_menu_pressed(id: int) -> void:
	print(id)
	
	match id:
		0:
			print("Plaquage")
			_start_action_hit()
		1:
			print("Pass")
			_start_action_pass()	
		2:
			print("Shoot")
			_start_action_shoot()
			
		3:
			print("Menu annulé")
			action_menu.hide()
			_cancel_action_mode()


func _start_action_shoot() -> void:
	print("start shoot")
	
	if active_pawn == null or not active_pawn.hasPuck:
		return
		
	
	action_mode = ActionMode.SHOOT	
 		#
		
	action_pawn = active_pawn	
	action_origin_cell = active_pawn.current_cell


	print("pre eligible", action_origin_cell, action_pawn)
	
 	# Optionnel: highlight les cases visables / portées de tir
	IceMapLayer.highlight_shoot_targets(action_origin_cell, action_pawn)

 	# Ferme le menu
	action_menu.hide()
 
func _start_action_pass():
	if active_pawn == null or not active_pawn.hasPuck:
		return

	
	action_mode = ActionMode.PASS
	action_pawn = active_pawn
	action_origin_cell = active_pawn.current_cell

	IceMapLayer.highlight_pass_targets(action_origin_cell, action_pawn)

	# Ferme le menu
	action_menu.hide()	
	
	
	
func _start_action_hit():
	if active_pawn == null or active_pawn.hasPuck:
		return

	action_mode = ActionMode.HIT
	action_pawn = active_pawn
	action_origin_cell = active_pawn.current_cell

	IceMapLayer.highlight_hit_targets(action_origin_cell, action_pawn)

 	# Ferme le menu
	action_menu.hide()		
	

func _do_shoot(target_cell: Vector2i) -> void:
	print("do_shoot")
	if action_pawn == null or not action_pawn.hasPuck:
		_cancel_action_mode()
		return

	action_origin_cell = active_pawn.current_cell	

# 	# Optionnel: valider une portée de tir (ex: move_range * 2)
	if not _is_in_shoot_range(action_origin_cell, target_cell, action_pawn):
		return

	if IceMapLayer.get_pawn_on_cell(target_cell) != null:
		print("Shoot refusé: case occupée par un pawn.")
		return

	
	if action_pawn.has_method("_shoot"):
		action_pawn._shoot(target_cell)

	IceMapLayer.update_occupancy()
	_cancel_action_mode()
	
func _do_pass(target_cell: Vector2i) -> void:
	if action_pawn == null or not action_pawn.hasPuck:
		_cancel_action_mode()
		return

	action_origin_cell = active_pawn.current_cell	

 	# Optionnel: valider une portée de tir (ex: move_range * 2)
	if not _is_in_shoot_range(action_origin_cell, target_cell, action_pawn):
		return
	
	var receiver: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

 	# Restriction: pass autorisé seulement s'il y a un pawn sur la case visée
	if receiver == null:
		print("Passe refusée: aucun pawn sur la case visée.")
		return

 	# (optionnel) éviter de se passer à soi-même
 
	if receiver == action_pawn:
		print("Passe refusée: tu ne peux pas te passer à toi-même.")
		return

	
	if action_pawn.has_method("_pass"):
		action_pawn._pass(target_cell)

	IceMapLayer.update_occupancy()
	_cancel_action_mode()	
	
	
func _do_hit(target_cell: Vector2i) -> void:
	if action_pawn == null or action_pawn.hasPuck:
		_cancel_action_mode()
		return

 	
	
	var hitTarget: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

 	# Restriction: pass autorisé seulement s'il y a un pawn sur la case visée
	if hitTarget == null:
		print("Passe refusée: aucun pawn sur la case visée.")
		return

 	# (optionnel) éviter de se plaquer à soi-même
	if hitTarget == action_pawn:
		print("Plaquage: tu ne peux pas te plaquer toi-même.")
		return

	
	if action_pawn.has_method("_hit"):
		action_pawn._hit(target_cell)
		
	#TODO ajouter une méthode pour être frapper	
	#if hitTarget.has_method("_being_hit"):
		#hitTarget._being_hit(target_cell)
		

	IceMapLayer.update_occupancy()
	_cancel_action_mode()		


func _is_in_shoot_range(orgin_cell, target_cell, recieved_pawn):
	var _range: int = recieved_pawn.move_range * 2

	var dist:int = abs(target_cell.x - orgin_cell.x) + abs(target_cell.y - orgin_cell.y)
	if dist == 0 or dist > _range:
		return false
	else:
		return true	

func goal_scored(puck_position):
	## Déterminer avec get_type or something si:
	# 1) c'est le but
	# 2) c'est le but de qui pour udpate score
	print(IceMapLayer._get_type(puck_position))
	print("GOAAAAL")
	#Mettre un genre de menu pause
	#Update le score Panel
	#Partir la séquence de reset
	reset_board()
	

func reset_board():
		puck.reset_board()
		#Dire à la puck d'initier le reset
		#Dire au joueurs? ou IcemapLayer de replacer les joueurs
		#Activer le bouton pour starter la game
