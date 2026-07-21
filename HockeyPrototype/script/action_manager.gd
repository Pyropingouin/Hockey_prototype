extends Node

@onready var GameManager = $"../GameManager"
@onready var IceMapLayer = $"../IceMapLayer"


####
###
## HUMAN ACTIONS
###
####
func attempt_move(pawn: Node2D, starting_cell: Vector2i, destination_cell: Vector2i) -> void:

	DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"pawn in attempt_move %s" % pawn
					)	



	if starting_cell == destination_cell:
		IceMapLayer.reset_move(pawn, starting_cell)
		return

	if not IceMapLayer.can_move_pawn_to(pawn, starting_cell, destination_cell):
		IceMapLayer.reset_move(pawn, starting_cell)
		return

	IceMapLayer.apply_move(pawn, starting_cell, destination_cell)
	GameManager.update_action_counter(1)




####
###
## AI ACTIONS
###
####
func ai_attempt_move(chosen_ai_pawn: Node2D, starting_cell: Vector2i, destination_cell: Vector2i) -> bool:
	if starting_cell == destination_cell:
		IceMapLayer.reset_move(chosen_ai_pawn, starting_cell)
		return false

	if not IceMapLayer.can_move_pawn_to(chosen_ai_pawn, starting_cell, destination_cell):
		IceMapLayer.reset_move(chosen_ai_pawn, starting_cell)
		return false

	IceMapLayer.apply_move(chosen_ai_pawn, starting_cell, destination_cell)
	GameManager.update_action_counter(1)

	return true


func ai_attempt_shoot(target_cell: Vector2i, chosen_ai_pawn: Node2D) -> bool:

	DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"ai attempt shoot"
					)	

	if chosen_ai_pawn == null:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"chosen_ai_pawn == null"
					)	

		return false

	if not chosen_ai_pawn.hasPuck:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"not chosen_ai_pawn.hasPuck"
					)	
		
		return false

	var action_origin_cell: Vector2i = chosen_ai_pawn.current_cell

	if not GameManager._is_in_shoot_range(action_origin_cell, target_cell, chosen_ai_pawn):

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"AI not in shoot range"
					)	
		
		return false

	var target_character: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

	if target_character is Goalie:
		var target_goalie: Goalie = target_character

		if target_goalie.team_id == chosen_ai_pawn.team_id:

			DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"AI Tir refusé : impossible de tirer sur son propre goalie."
					)	
			return false

		
		var goal_scored: bool = GameManager._resolve_shot_against_goalie(
		chosen_ai_pawn,
		target_goalie
		)

		if not goal_scored:
			GameManager.update_action_counter(1)
			return true	

	if target_character != null:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"AI Tir refusé : la case ciblée est occupée. /n  AI  TARGET CHARACTER FOR SHOOT: %s" % target_character 
					)	

		return false		


	if not IceMapLayer.is_shot_path_clear(action_origin_cell, target_cell):

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"AI not in shoot path clear"
					)	
		return false

	if IceMapLayer.get_pawn_on_cell(target_cell) != null:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"IceMapLayer.get_pawn_on_cell(target_cell) != null"
					)	
		return false

	if not chosen_ai_pawn.has_method("_shoot"):

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"not chosen_ai_pawn.has_method(_shoot)"
					)	
		
		return false

	
		

	chosen_ai_pawn._shoot(target_cell)

	GameManager.update_action_counter(1)
	IceMapLayer.update_occupancy()

	return true


func ai_attempt_pass(chosen_ai_pawn: Node2D, pass_target: Node2D, ai_player_array: Array = []) -> bool:
	if pass_target == null:
		return false
	if pass_target == chosen_ai_pawn:
		return false 	

	if chosen_ai_pawn == null:
		return false

	if not chosen_ai_pawn.hasPuck:
		return false

	if not chosen_ai_pawn.has_method("_pass"):
		return false

	if not GameManager._is_in_shoot_range(chosen_ai_pawn.current_cell, pass_target.current_cell, chosen_ai_pawn):
		return false

	
	if not IceMapLayer.is_shot_path_clear(chosen_ai_pawn.current_cell, pass_target.current_cell):
		return false	
	
	if not ai_player_array.has(pass_target):
		return false




	chosen_ai_pawn._pass(pass_target.current_cell)

	GameManager.update_action_counter(1)
	IceMapLayer.update_occupancy()

	return true	


func ai_attempt_hit(chosen_ai_pawn: Node2D, target_cell: Vector2i) -> bool:
	if chosen_ai_pawn == null:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"pas de chosen ai"
					)	
		return false

	if chosen_ai_pawn.hasPuck:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"Le chosen ai possède la puck"
					)	
		return false

	var hit_target: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

	if hit_target == null:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"hit target == null"
					)	
		return false

	if hit_target == chosen_ai_pawn:

		DebugLogger.log(
					DebugLogger.DebugType.ACTION_MANAGER,
					"hit target == son propre chosen ai"
					)	
		return false

	if IceMapLayer.get_hex_distance(chosen_ai_pawn.current_cell, hit_target.current_cell) > 1:
		return false

	if not chosen_ai_pawn.has_method("_hit"):
		return false

	chosen_ai_pawn._hit(target_cell)

	GameManager.update_action_counter(1)
	IceMapLayer.update_occupancy()

	return true