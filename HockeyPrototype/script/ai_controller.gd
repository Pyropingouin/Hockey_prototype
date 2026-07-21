extends Node

@onready var GameManager = $"../GameManager"
@onready var ActionManager = $"../ActionManager"
@onready var IceMapLayer = $"../IceMapLayer"
@onready var players_container: Node = $"../PlayersContainer"
@onready var puck := $"../Puck"

var ai_player_pawn_list: Array = []
var human_player_pawn_list: Array = []
var chosen_ai_pawn = null

const RIGHT_NET_POSITION = Vector2i(7, 0)
const LEFT_NET_POSITION = Vector2i(-3, 0)
const AGGRESSIVITY_LEVEL: int = 2


func turn_inside_ai() -> void:
	# Évite d'ajouter les mêmes joueurs plusieurs fois si la fonction est rappelée.
	ai_player_pawn_list.clear()
	human_player_pawn_list.clear()

	# Connaître tous les pawns alliés et ennemis.
	for pawn in players_container.get_children():

		if pawn is Goalie:
			continue

		if pawn.team_id == 2:
			ai_player_pawn_list.append(pawn)
		elif pawn.team_id == 1:
			human_player_pawn_list.append(pawn)

	while GameManager.active_team == 2 and GameManager.active_team_action_counter < GameManager.max_action_counter and GameManager.game_state != GameManager.GameState.GOAL_PAUSE:
		await get_tree().create_timer(1.0).timeout

		var puck_position = puck.current_cell
		var is_puck_held = puck.isPickedUp

		# Si la puck est libre, on fonce dessus.
		if not is_puck_held:
			move_ai_toward_free_puck(puck_position)
			continue

		var ai_pawn_puck_carrier = null
		var human_pawn_puck_carrier = null

		for ai_pawn in ai_player_pawn_list:
			if ai_pawn.hasPuck:
				ai_pawn_puck_carrier = ai_pawn
				break

		for human_pawn in human_player_pawn_list:
			if human_pawn.hasPuck:
				human_pawn_puck_carrier = human_pawn
				break

		# Si la puck est détenue par un joueur AI.
		if ai_pawn_puck_carrier != null:


			DebugLogger.log(
				DebugLogger.DebugType.AI,
				"L'IA a la puck: %s" % ai_pawn_puck_carrier.pawn_name
			)
		

			var is_shoot_successful: bool = ActionManager.ai_attempt_shoot(RIGHT_NET_POSITION, ai_pawn_puck_carrier)

			# Le tir a réussi : on recommence la boucle pour la prochaine action.
			if is_shoot_successful:
				continue

			var failed_pass_targets: Array = []
			var is_pass_successful: bool = false

			for _i in range(ai_player_pawn_list.size() - 1):
				var pass_target_pawn = choosing_pass_target(ai_pawn_puck_carrier, failed_pass_targets)




				DebugLogger.log(
					DebugLogger.DebugType.AI,
					"Pass target sélectionnée par AI: %s" % pass_target_pawn
				)


				

				# Il ne reste aucune cible disponible.
				if pass_target_pawn == null:
					break

				is_pass_successful = ActionManager.ai_attempt_pass(ai_pawn_puck_carrier, pass_target_pawn, ai_player_pawn_list)

				if is_pass_successful:
					break

				failed_pass_targets.append(pass_target_pawn)

			# Une passe a réussi : poursuivre le tour de l'IA.
			if is_pass_successful:
				continue

			# Le tir et toutes les passes ont échoué.
			move_ai_toward_target(ai_player_pawn_list.pick_random(),RIGHT_NET_POSITION)
			continue

		# Si la puck est détenue par un joueur humain.
		if human_pawn_puck_carrier != null:



			DebugLogger.log(
					DebugLogger.DebugType.AI,
					"Le joueur humain a la puck: %s" % human_pawn_puck_carrier.pawn_name
				)
		

			chosen_ai_pawn = calculate_distance(human_pawn_puck_carrier.current_cell)

			if chosen_ai_pawn == null:
				DebugLogger.log(
					DebugLogger.DebugType.AI,
					"Aucun joueur AI disponible"
				)

				move_ai_random()
				continue


				DebugLogger.log(
						DebugLogger.DebugType.AI,
						"Chosen AI pawn to hit: %s" % chosen_ai_pawn
					)	

			var temporary_distance_to_target: int = IceMapLayer.get_hex_distance(chosen_ai_pawn.current_cell, human_pawn_puck_carrier.current_cell)

			DebugLogger.log(
						DebugLogger.DebugType.AI,
						"temporary_distance_to_target: %s" % str(temporary_distance_to_target)
					)	
		

			# Le joueur AI est adjacent au porteur de la puck.
			if temporary_distance_to_target == 1:
				DebugLogger.log(
						DebugLogger.DebugType.AI,
						"Tente une frappe"
					)	
				

				var is_hit_successful: bool = ActionManager.ai_attempt_hit(chosen_ai_pawn, human_pawn_puck_carrier.current_cell)

				if not is_hit_successful:

					DebugLogger.log(
						DebugLogger.DebugType.AI,
						"Échec sur frappe"
					)	
					

					move_ai_random()

			elif temporary_distance_to_target <= AGGRESSIVITY_LEVEL:
				move_ai_toward_target(chosen_ai_pawn, human_pawn_puck_carrier.current_cell)

			else:
				move_ai_closer_target(chosen_ai_pawn, human_pawn_puck_carrier.current_cell, chosen_ai_pawn.move_range)

			continue

		# La puck dit qu'elle est détenue, mais aucun joueur ne possède hasPuck.
		push_warning("La puck est indiquée comme détenue, mais aucun porteur n'a été trouvé.")
		break


# Move a random pawn in a random tile
func move_ai_random() -> void:

	DebugLogger.log(
					DebugLogger.DebugType.AI,
					"AI move at random"
					)	

	var destination_cell = Vector2i(randi_range(0, 5), randi_range(0, 5))

	var selected_ai_pawn = ai_player_pawn_list[randi_range(0, ai_player_pawn_list.size() - 1)]


	DebugLogger.log(
	DebugLogger.DebugType.AI,
	"Selected AI pawn: %s | From : %s | To : %s" % [
		selected_ai_pawn.pawn_name,
		selected_ai_pawn.current_cell,
		destination_cell
	]
)					


	ActionManager.ai_attempt_move(selected_ai_pawn, selected_ai_pawn.current_cell, destination_cell)


func move_ai_toward_free_puck(puck_position) -> void:

	DebugLogger.log(
					DebugLogger.DebugType.AI,
					"move toward puck at position %s" % puck_position
					)	
	

	chosen_ai_pawn = calculate_distance(puck_position)

	#faire bouger le joueur
	var is_move_successful = ActionManager.ai_attempt_move(chosen_ai_pawn, chosen_ai_pawn.current_cell, puck_position)

	if (is_move_successful == false):
		move_ai_random()


func move_ai_toward_target(ai_pawn: Node2D, target_cell: Vector2i) -> void:

	DebugLogger.log(
					DebugLogger.DebugType.AI,
					"move_ai_TOWARD_target"
					)	

	var usable_cells: Array = IceMapLayer.get_usable_surrounding_cells(target_cell)

	DebugLogger.log(
		DebugLogger.DebugType.AI,
		"Usable cells around target: " + str(usable_cells)
	)

	
	

	var best_cell: Vector2i
	var best_distance: int = 999999


	for cell in usable_cells:
		if not IceMapLayer.can_move_pawn_to(ai_pawn, ai_pawn.current_cell, cell):
			continue

		var pawn_distance_with_target: int = IceMapLayer.get_hex_distance(ai_pawn.current_cell, cell)

		if pawn_distance_with_target == -1:
			continue

		if pawn_distance_with_target < best_distance:
			best_distance = best_distance
			best_cell = cell


	DebugLogger.log(
	DebugLogger.DebugType.AI,
	"Final best_cell: %s | Final best_distance : %s" % [
		best_cell,
		best_distance
		
	]
)					
		




	if best_cell == ai_pawn.current_cell:

		DebugLogger.log(
					DebugLogger.DebugType.AI,
					"Aucune case valide trouvée autour de la cible"
					)	

		move_ai_random()
		return

	
	var is_move_successful = ActionManager.ai_attempt_move(ai_pawn, ai_pawn.current_cell, best_cell)

	if (is_move_successful == false):
		move_ai_random()


func move_ai_closer_target(
	ai_pawn: Node2D,
	target_cell: Vector2i,
	ai_pawn_move_range: int
) -> void:
	var start_cell: Vector2i = ai_pawn.current_cell

	var usable_cells: Array[Vector2i] = IceMapLayer.get_usable_surrounding_cells(target_cell)

	if usable_cells.is_empty():

		DebugLogger.log(
						DebugLogger.DebugType.AI,
						"Aucune case libre autour du target"
						)		

		return

	var best_path: Array[Vector2i] = []

	for cell in usable_cells:
		var path: Array[Vector2i] = IceMapLayer.find_path(start_cell, cell, false)

		if path.is_empty():
			continue

		if best_path.is_empty() or path.size() < best_path.size():
			best_path = path

	if best_path.is_empty():

		DebugLogger.log(
						DebugLogger.DebugType.AI,
						"Aucun chemin trouvé vers une case autour du target"
						)		

		return

	# best_path[0] = position actuelle
	# best_path[1] = première case de déplacement
	# best_path[-1] = case libre autour du target
	var destination_index: int = min(ai_pawn_move_range, best_path.size() - 1)
	var destination_cell: Vector2i = best_path[destination_index]


	DebugLogger.log(
	DebugLogger.DebugType.AI,
	"Best path vers target: %s | Destination choisie : %s" % [
		best_path,
		destination_cell		
	]
	)


	var is_move_successful = ActionManager.ai_attempt_move(ai_pawn, start_cell, destination_cell)

	if (is_move_successful == false):
		move_ai_random()


func calculate_distance(target_position):
	var shortest_distance = 999
	var closest_pawn: Node2D = null

	for pawn in ai_player_pawn_list:
		#    # trouver la distance entre la puck et le joueur
		var pawn_distance_with_target: int = IceMapLayer.get_hex_distance(pawn.current_cell, target_position)

		if pawn_distance_with_target < shortest_distance:
			shortest_distance = pawn_distance_with_target
			closest_pawn = pawn

	return closest_pawn


func choosing_pass_target(ai_pawn_puck_carrier: Node2D, removable_pawn_array: Array = []):
	var best_dist: int = IceMapLayer.get_hex_distance(ai_pawn_puck_carrier.current_cell, RIGHT_NET_POSITION)
	var best_pawn: Node2D = null


	DebugLogger.log(
	DebugLogger.DebugType.AI,
	"DANS CHOOSING PASS TARGET \nPuck carrier: %s | Removable pawn array : %s" % [
		ai_pawn_puck_carrier,
		removable_pawn_array		
	]
	)

	


	#Check tout tes allié et garde leur distance face au but dans un array
	for ai_pawn in ai_player_pawn_list:
		if ai_pawn == ai_pawn_puck_carrier:
			continue
		if removable_pawn_array.has(ai_pawn):
			continue

		var current_dist: int = IceMapLayer.get_hex_distance(ai_pawn.current_cell, RIGHT_NET_POSITION)

		if current_dist < best_dist:
			best_dist = current_dist
			best_pawn = ai_pawn

		return best_pawn
