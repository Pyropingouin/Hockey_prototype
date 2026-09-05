extends Node

@onready var GameManager = $"../GameManager"
@onready var IceMapLayer = $"../IceMapLayer"




const MOVE_ENERGY_COST: int = 1
const HIT_ENERGY_COST: int = 1
const SHOOT_RANGE: int = 3
const PASS_RANGE: int = 5


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

	if not pawn.canSpendEnergy(MOVE_ENERGY_COST):
		IceMapLayer.reset_move(pawn, starting_cell)
		return

	if not IceMapLayer.can_move_pawn_to(pawn, starting_cell, destination_cell):
		IceMapLayer.reset_move(pawn, starting_cell)
		return



	IceMapLayer.apply_move(pawn, starting_cell, destination_cell)
	pawn.spendEnergy(MOVE_ENERGY_COST)
	GameManager.update_action_counter(1)




func attempt_shoot(shooter: Node2D, target_cell: Vector2i) -> bool:
	

	DebugLogger.log(
		DebugLogger.DebugType.ACTION_MANAGER,
		"attempt_shoot | shooter: %s | target: %s" % [
			shooter,
			target_cell
		]
	)

	
	if shooter == null:
		return false

	if not shooter.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Tir refusé : le joueur ne possède pas la puck."
		)
		return false


	var origin_cell: Vector2i = shooter.current_cell


	if not is_in_shoot_range(
		origin_cell,
		target_cell
	):
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Tir refusé : cible hors de portée."
		)
		return false


	if not IceMapLayer.is_path_clear(
		origin_cell,
		target_cell
	):
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Tir refusé : trajectoire bloquée."
		)
		return false


	var target_character: Node2D = \
		IceMapLayer.get_pawn_on_cell(target_cell)


	#
	# GOALIE
	#
	if target_character is Goalie:

		var target_goalie: Goalie = target_character

		if target_goalie.team_id == shooter.team_id:
			DebugLogger.log(
				DebugLogger.DebugType.ACTION_MANAGER,
				"Tir refusé : impossible de tirer sur son propre goalie."
			)
			return false


		var goal_scored: bool = \
			GameManager._resolve_shot_against_goalie(
				shooter,
				target_goalie
			)


		# Si arrêt du goalie, l'action compte normalement.
		if not goal_scored:
			GameManager.update_action_counter(1)


		IceMapLayer.update_occupancy()

		return true


	#
	# AUTRE JOUEUR
	#
	if target_character != null:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Tir refusé : case occupée par %s." \
			% target_character
		)

		return false


	#
	# TIR NORMAL
	#
	if not shooter.has_method("_shoot"):
		return false

	shooter.play_second_shoot_animation()
	shooter._shoot(target_cell)
	

	GameManager.update_action_counter(1)

	IceMapLayer.update_occupancy()

	return true



func attempt_pass(
	passer: Node2D,
	pass_target: Node2D
) -> bool:

	DebugLogger.log(
		DebugLogger.DebugType.ACTION_MANAGER,
		"attempt_pass | passer: %s | target: %s" % [
			passer,
			pass_target
		]
	)


	if passer == null:
		return false


	if pass_target == null:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : aucune cible."
		)
		return false


	if passer == pass_target:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : impossible de se passer à soi-même."
		)
		return false


	if not passer.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : le joueur ne possède pas la puck."
		)
		return false


	# Empêcher une passe à l'adversaire.
	if passer.team_id != pass_target.team_id:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : la cible appartient à l'autre équipe."
		)
		return false

	if pass_target is Goalie:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : impossible de passer au goalie."
		)
		return false	


	if not is_in_pass_range(
		passer.current_cell,
		pass_target.current_cell
	):
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : cible hors de portée."
		)
		return false


	if not IceMapLayer.is_path_clear(
		passer.current_cell,
		pass_target.current_cell
	):
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Passe refusée : trajectoire bloquée."
		)
		return false


	if not passer.has_method("_pass"):
		return false


	passer._pass(pass_target.current_cell)
	passer.play_pass_animation()

	GameManager.update_action_counter(1)

	IceMapLayer.update_occupancy()

	return true	



func attempt_hit(
	hitter: Node2D,
	hit_target: Node2D
) -> bool:

	DebugLogger.log(
		DebugLogger.DebugType.ACTION_MANAGER,
		"attempt_hit | hitter: %s | target: %s" % [
			hitter,
			hit_target
		]
	)


	if hitter == null:
		return false


	if hitter.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Plaquage refusé : le joueur possède la puck."
		)
		return false


	if hit_target == null:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Plaquage refusé : aucune cible."
		)
		return false


	if hit_target == hitter:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Plaquage refusé : impossible de se plaquer soi-même."
		)
		return false


	if hitter.team_id == hit_target.team_id:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Plaquage refusé : impossible de plaquer un coéquipier."
		)
		return false


	if IceMapLayer.get_hex_distance(
		hitter.current_cell,
		hit_target.current_cell
	) > 1:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Plaquage refusé : cible trop loin."
		)
		return false


	if not hitter.canSpendEnergy(HIT_ENERGY_COST):
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Plaquage refusé : énergie insuffisante."
		)
		return false


	if not hitter.has_method("_hit"):
		return false


	hitter._hit(hit_target.current_cell)

	hitter.spendEnergy(HIT_ENERGY_COST)

	GameManager.update_action_counter(1)

	IceMapLayer.update_occupancy()

	return true	





####
###
## HELPERS
###
####

func is_in_shoot_range(
	origin_cell: Vector2i,
	target_cell: Vector2i
) -> bool:

	var distance: int = IceMapLayer.get_hex_distance(
		origin_cell,
		target_cell
	)

	return distance > 0 and distance <= SHOOT_RANGE


func is_in_pass_range(
	origin_cell: Vector2i,
	target_cell: Vector2i
) -> bool:

	var distance: int = IceMapLayer.get_hex_distance(
		origin_cell,
		target_cell
	)

	return distance > 0 and distance <= PASS_RANGE






func start_shoot(shooter: Node2D) -> bool:

	if shooter == null:
		return false

	if not shooter.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Impossible de préparer le tir : le joueur n'a pas la puck."
		)
		return false

	shooter.play_first_shoot_animation()

	return true


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

	if not chosen_ai_pawn.canSpendEnergy(MOVE_ENERGY_COST):
		IceMapLayer.reset_move(chosen_ai_pawn, starting_cell)
		return false

	IceMapLayer.apply_move(chosen_ai_pawn, starting_cell, destination_cell)
	chosen_ai_pawn.spendEnergy(MOVE_ENERGY_COST)
	GameManager.update_action_counter(1)

	return true


func ai_attempt_shoot(
	target_cell: Vector2i,
	chosen_ai_pawn: Node2D
) -> bool:

	return attempt_shoot(
		chosen_ai_pawn,
		target_cell
	)


func ai_attempt_pass(
	chosen_ai_pawn: Node2D,
	pass_target: Node2D
) -> bool:

	return attempt_pass(
		chosen_ai_pawn,
		pass_target
	)


func ai_attempt_hit(
	chosen_ai_pawn: Node2D,
	target_cell: Vector2i
) -> bool:

	var hit_target: Node2D = \
		IceMapLayer.get_pawn_on_cell(target_cell)


	return attempt_hit(
		chosen_ai_pawn,
		hit_target
	)