extends Node

@onready var GameManager = $"../GameManager"
@onready var IceMapLayer = $"../IceMapLayer"



const MOVE_ENERGY_COST: int = 1
const HIT_ENERGY_COST: int = 1
const SHOOT_RANGE: int = 4
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
	var goal_type: String = IceMapLayer.get_goal_type(target_cell)
	var is_goal: bool = goal_type in ["home", "away"]
	var target_character: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)

	var distance: int = get_shot_distance(shooter, target_cell)
	var distance_penalty: float = get_shot_distance_penalty(distance)
	


	if not is_in_shoot_range(
		origin_cell,
		target_cell
	):
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Tir refusé : cible hors de portée."
		)
		return false


	if not IceMapLayer.is_shot_path_clear(origin_cell, target_cell, is_goal):

		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Tir refusé : trajectoire bloquée."
		)

		return false


	
	#
	# INTERCEPTION DU TIR
	#
	var interceptors: Array[Node2D] = IceMapLayer.get_shot_interceptors(origin_cell, target_cell, shooter.team_id)

	for interceptor in interceptors:
		var chance: float = get_interception_chance(shooter, interceptor)
		var roll: float = randf()

		DebugLogger.log(DebugLogger.DebugType.ACTION_MANAGER, "Interception : %s | Chance : %.1f%% | Jet : %.3f" % [interceptor.pawn_name, chance * 100.0, roll])

		if roll < chance:
			await shooter.play_second_shoot_animation_and_wait()
			await GameManager.puck.animate_puck_movement(origin_cell, interceptor.current_cell, 0.15)

			shooter._shoot(interceptor.current_cell)

			IceMapLayer.update_occupancy()
			GameManager.on_shot_intercepted(interceptor, shooter)
			GameManager.update_action_counter(1)

			return true

		DebugLogger.log(DebugLogger.DebugType.ACTION_MANAGER, "%s rate son interception." % interceptor.pawn_name)




	

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


		await shooter.play_second_shoot_animation_and_wait()
		await GameManager.puck.animate_puck_movement(origin_cell, target_goalie.current_cell, 0.15)

	
		GameManager._rebound_puck_around_goalie(target_goalie)
		GameManager.update_action_counter(1)
		IceMapLayer.update_occupancy()
		return true



	
	if goal_type in ["home", "away"]:

	
		var trajectory: Array[Vector2i] = IceMapLayer.get_cells_on_line(origin_cell,target_cell)
		var target_goalie: Goalie = null

		for cell in trajectory:

			var pawn: Node2D = IceMapLayer.get_pawn_on_cell(cell)

			if pawn is Goalie:
				target_goalie = pawn
				break

		var animation_target: Vector2i = target_goalie.current_cell if target_goalie != null else target_cell

	

		await shooter.play_second_shoot_animation_and_wait()



		await GameManager.puck.animate_puck_movement(origin_cell, animation_target, 0.15)

	


		if target_goalie != null:

			GameManager._resolve_shot_against_goalie(shooter, target_goalie, goal_type, distance_penalty)
			GameManager.update_action_counter(1)
			IceMapLayer.update_occupancy()
			return true		

		else:
			GameManager._on_goal_scored(goal_type)
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

	await shooter.play_second_shoot_animation_and_wait()
	await GameManager.puck.animate_puck_movement(origin_cell, target_cell, 0.15)
	

	
	shooter._shoot(target_cell)
	

	GameManager.update_action_counter(1)

	IceMapLayer.update_occupancy()

	return true




func attempt_pass(passer: Node2D, pass_target: Node2D) -> bool:
	if passer == null or pass_target == null:
		return false

	if passer == pass_target:
		return false

	if not passer.hasPuck:
		return false

	if passer.team_id != pass_target.team_id:
		return false

	if pass_target is Goalie:
		return false

	if not is_in_pass_range(passer.current_cell, pass_target.current_cell):
		return false

	if not IceMapLayer.is_pass_path_clear(passer.current_cell, pass_target.current_cell):
		return false

	if not passer.has_method("_pass"):
		return false

	#
	# INTERCEPTION
	#
	var interceptors: Array[Node2D] = IceMapLayer.get_pass_interceptors(passer.current_cell, pass_target.current_cell, passer.team_id)
	var destination_cell: Vector2i = pass_target.current_cell
	var successful_interceptor: Node2D = null

	for interceptor in interceptors:
		var chance: float = get_interception_chance(passer, interceptor)
		var roll: float = randf()

		DebugLogger.log(DebugLogger.DebugType.ACTION_MANAGER, "Interception de passe : %s | Chance : %.1f%% | Jet : %.3f" % [interceptor.pawn_name, chance * 100.0, roll])

		if roll < chance:
			successful_interceptor = interceptor
			destination_cell = interceptor.current_cell
			break

	#
	# EXÉCUTION DE LA PASSE
	#
	DebugLogger.log(DebugLogger.DebugType.ACTION_MANAGER, "AVANT animation passe")

	

	await passer.play_pass_animation_and_wait()



	await GameManager.puck.animate_puck_movement(passer.current_cell, destination_cell)



	passer._pass(destination_cell)



	DebugLogger.log(DebugLogger.DebugType.ACTION_MANAGER, "APRÈS animation passe")

	passer._pass(destination_cell)


	if successful_interceptor != null:
		GameManager.on_pass_intercepted(successful_interceptor, passer)

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

	await hitter.play_second_hit_animation_and_wait()
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


func get_interception_chance(attacker: Node2D, interceptor: Node2D) -> float:
	var difference: int = interceptor.technique - attacker.reflex
	var chance: float = 0.25 + float(difference) * 0.07

	return clampf(chance, 0.05, 0.85)


func get_total_interception_chance(attacker: Node2D, interceptors: Array[Node2D]) -> float:
	var chance_no_interception: float = 1.0

	for interceptor in interceptors:
		var chance: float = get_interception_chance(attacker, interceptor)
		chance_no_interception *= 1.0 - chance

	return 1.0 - chance_no_interception


func get_shot_distance(shooter: Node2D, target_cell: Vector2i) -> int:
	return IceMapLayer.get_hex_distance(shooter.current_cell, target_cell)	


func get_shot_distance_penalty(distance: int) -> float:
	return clampf(float(distance - 2) * 0.10, 0.0, 0.90)	



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


func start_pass(passer: Node2D) -> bool:

	if passer == null:
		return false

	if not passer.hasPuck:
		DebugLogger.log(
			DebugLogger.DebugType.ACTION_MANAGER,
			"Impossible de préparer le tir : le joueur n'a pas la puck."
		)
		return false

	

	return true


func start_hit(hitter: Node2D) -> bool:

	if hitter == null:
		return false

	# if not hitter.hasPuck:
	# 	DebugLogger.log(
	# 		DebugLogger.DebugType.ACTION_MANAGER,
	# 		"Impossible de préparer le tir : le joueur n'a pas la puck."
	# 	)
	# 	return false

	hitter.play_first_hit_animation()

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

	# Calculer la position visuelle de destination
	var destination_global: Vector2 = IceMapLayer.to_global(IceMapLayer.map_to_local(destination_cell))

	# Animer le déplacement
	var tween: Tween = create_tween()
	tween.tween_property(chosen_ai_pawn, "global_position", destination_global, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Attendre que le déplacement soit terminé
	await tween.finished

	# Appliquer le déplacement logique
	IceMapLayer.apply_move(chosen_ai_pawn, starting_cell, destination_cell)
	chosen_ai_pawn.spendEnergy(MOVE_ENERGY_COST)
	GameManager.update_action_counter(1)

	return true


func ai_attempt_shoot(
	target_cell: Vector2i,
	chosen_ai_pawn: Node2D
) -> bool:

	return await attempt_shoot(
		chosen_ai_pawn,
		target_cell
	)


func ai_attempt_pass(chosen_ai_pawn: Node2D, pass_target: Node2D) -> bool:
	var success: bool = await attempt_pass(chosen_ai_pawn, pass_target)

	if success:
		GameManager.update_action_counter(1,"passing")

	return success


func ai_attempt_hit(
	chosen_ai_pawn: Node2D,
	target_cell: Vector2i
) -> bool:

	var hit_target: Node2D = \
		IceMapLayer.get_pawn_on_cell(target_cell)


	return await attempt_hit(
		chosen_ai_pawn,
		hit_target
	)
