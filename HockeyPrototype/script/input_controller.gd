extends Node

@onready var GameManager = $"../GameManager"
@onready var IceMapLayer = $"../IceMapLayer"
@onready var ActionManager = $"../ActionManager"


enum GameState { PLAYING, GOAL_PAUSE }
enum ActionMode { NONE, SHOOT, PASS, HIT }
const DRAG_THRESHOLD_PX := 12.0

var drag_candidate: Node2D = null
var drag_start_cell: Vector2i = Vector2i.ZERO
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var is_dragging := false
var target_pawn: Node2D = null


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.game_state != GameState.PLAYING:
		return

	if event.is_action_pressed("ui_cancel"):
		GameManager._pause_game()
		GameManager.pause_menu.visible = true

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

	if event.is_action_pressed("ui_cancel") and GameManager.action_mode != ActionMode.NONE:
		GameManager._cancel_action_mode()
		return

	if event is InputEventMouseMotion and drag_candidate:
		_on_mouse_drag(event.position)


		

func _on_left_mouse_down(global_pos: Vector2) -> void:
	if GameManager.action_mode != ActionMode.NONE:
		_handle_action_click(global_pos)
		return

	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	
	GameManager.active_pawn = null
	drag_candidate = IceMapLayer.pawn_at_cell(cell)



#Cas ou ça ne marche pas
	if drag_candidate == null:
		GameManager.selected_pawn = null
		GameManager.emit_signal("pawn_selected", GameManager.selected_pawn)
		GameManager._refresh_action_buttons()
		return

	if drag_candidate.team_id != GameManager.active_team:
		drag_candidate = null
		GameManager._refresh_action_buttons()
		return
#Fin cas ou ça ne marche pas		


	GameManager.active_pawn = drag_candidate
	GameManager.selected_pawn = drag_candidate


	GameManager.emit_signal("pawn_selected", GameManager.selected_pawn)
	drag_start_cell = GameManager.active_pawn.current_cell
	drag_start_mouse_pos = global_pos
	is_dragging = false
	

	GameManager._refresh_action_buttons()

func _on_left_mouse_up(global_pos: Vector2) -> void:
	if GameManager.active_pawn == null:
		drag_candidate = null
		GameManager._refresh_action_buttons()
		return

	if not is_dragging:
		
		print("_on_left_mouse_UP if not dragging")
		GameManager._refresh_action_buttons()
		_cleanup_drag()
		return

	is_dragging = false

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	ActionManager.attempt_move(GameManager.active_pawn, drag_start_cell, target_cell)

	IceMapLayer.clear_highlight()
	_cleanup_drag()
	GameManager._refresh_action_buttons()


func _on_right_mouse_down(global_pos: Vector2) -> void:
	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if GameManager.action_mode != ActionMode.NONE:
		GameManager._cancel_action_mode()
	

	target_pawn = null
	target_pawn = IceMapLayer.pawn_at_cell(cell)

	if (target_pawn == null):
		GameManager.selected_pawn = null
		print("_on_right_mouse_down if target_pawn = null")
		emit_signal("pawn_selected", GameManager.selected_pawn)

	print("Target_Pawn = ", target_pawn)
	

func _on_right_mouse_up(global_pos: Vector2) -> void:
	print("left up")
	print(global_pos)

func _on_mouse_drag(global_pos: Vector2) -> void:
	if GameManager.active_pawn == null:
		return

	if not is_dragging:
		var dist := drag_start_mouse_pos.distance_to(global_pos)
		if dist < DRAG_THRESHOLD_PX:
			return

		is_dragging = true
		IceMapLayer.highlight_unreachable_from(drag_start_cell, GameManager.active_pawn.move_range)
		print("_on_mouse_drag")
		emit_signal("pawn_selected", GameManager.selected_pawn)
		GameManager._refresh_action_buttons()

	GameManager.active_pawn.global_position = global_pos

func _cleanup_drag() -> void:
	drag_candidate = null
	GameManager.active_pawn = null
	is_dragging = false

func _handle_action_click(global_pos: Vector2) -> void:
	print("handle action click")

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if IceMapLayer.get_ice_map_layer_cell_id(target_cell) == -1:
		GameManager._cancel_action_mode()
		return

	match GameManager.action_mode:
		ActionMode.SHOOT:
			GameManager._do_shoot(target_cell)
		ActionMode.PASS:
			GameManager._do_pass(target_cell)
		ActionMode.HIT:
			GameManager._do_hit(target_cell)