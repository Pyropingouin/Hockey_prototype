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


		


#LEFT MOUSE DOWN		

func _on_left_mouse_down(global_pos: Vector2) -> void:
	if GameManager.action_mode != ActionMode.NONE:
		_handle_action_click(global_pos)
		return

	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)
	drag_candidate = IceMapLayer.pawn_at_cell(cell)

	if drag_candidate == null:
		GameManager.selected_pawn = null
		GameManager._refresh_action_buttons()
		return

	if drag_candidate.team_id != GameManager.active_team:
		drag_candidate = null
		GameManager._refresh_action_buttons()
		return

	GameManager.selected_pawn = drag_candidate

	drag_start_cell = drag_candidate.current_cell
	drag_start_mouse_pos = global_pos
	is_dragging = false

	GameManager._refresh_action_buttons()

#LEFT MOUSE UP

func _on_left_mouse_up(global_pos: Vector2) -> void:
	if drag_candidate == null:
		GameManager._refresh_action_buttons()
		return

	if not is_dragging:
		DebugLogger.log(
					DebugLogger.DebugType.GENERAL,
					"_on_left_mouse_up without dragging"
					)		

		_cleanup_drag()
		GameManager._refresh_action_buttons()
		return

	is_dragging = false

	var target_cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	ActionManager.attempt_move(drag_candidate, drag_start_cell, target_cell)

	IceMapLayer.clear_highlight()
	_cleanup_drag()
	GameManager._refresh_action_buttons()




#RIGHT MOUSE DOWN

func _on_right_mouse_down(global_pos: Vector2) -> void:
	var cell: Vector2i = IceMapLayer.cell_from_global_pos(global_pos)

	if GameManager.action_mode != ActionMode.NONE:
		GameManager._cancel_action_mode()

	target_pawn = IceMapLayer.pawn_at_cell(cell)

	if target_pawn == null:
		GameManager.selected_pawn = null

		DebugLogger.log(
					DebugLogger.DebugType.GENERAL,
					"on_right_mouse_down if target_pawn == null"
					)			

		GameManager._refresh_action_buttons()
		return

	DebugLogger.log(
					DebugLogger.DebugType.GENERAL,
					"Target_Pawn =   %s" % target_pawn
					)			
					



#RIGHT MOUSE UP	

func _on_right_mouse_up(global_pos: Vector2) -> void:
	pass

func _on_mouse_drag(global_pos: Vector2) -> void:
	if drag_candidate == null:
		return

	if not is_dragging:
		var dist := drag_start_mouse_pos.distance_to(global_pos)
		if dist < DRAG_THRESHOLD_PX:
			return

		is_dragging = true
		IceMapLayer.highlight_unreachable_from(drag_start_cell, drag_candidate.move_range)
		DebugLogger.log(
						DebugLogger.DebugType.GENERAL,
						"_on_mouse_drag"
						)	

	
		GameManager._refresh_action_buttons()

	drag_candidate.global_position = global_pos

func _cleanup_drag() -> void:
	drag_candidate = null
	is_dragging = false

func _handle_action_click(global_pos: Vector2) -> void:


	DebugLogger.log(
						DebugLogger.DebugType.GENERAL,
						"handle action click"
						)		

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