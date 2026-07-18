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
	#Connaitre tout les pawn, alliés et ennemies
	for pawn in players_container.get_children():
		if pawn.team_id == 2:
			ai_player_pawn_list.append(pawn)
		if pawn.team_id == 1:
			human_player_pawn_list.append(pawn)

	while GameManager.active_team == 2 and GameManager.active_team_action_counter < GameManager.max_action_counter and GameManager.game_state != GameManager.GameState.GOAL_PAUSE:
		#Connaitre la puck
		var puck_position = puck.current_cell
		var is_puck_held = puck.isPickedUp

		await get_tree().create_timer(1.0).timeout

		# Si la puck est libre, on fonce dessus
		if (is_puck_held == false):
			move_ai_toward_free_puck(puck_position)

		# Si la puck n'est pas libre
		elif (is_puck_held == true):
			var ai_pawn_puck_carrier = null
			var human_pawn_puck_carrier = null

			for ai_pawn in ai_player_pawn_list:
				if ai_pawn.hasPuck == true:
					ai_pawn_puck_carrier = ai_pawn

			for human_pawn in human_player_pawn_list:
				if human_pawn.hasPuck == true:
					human_pawn_puck_carrier = human_pawn

			# Si la puck est detenu par un joueur AI, on essaye de shoot
			if ai_pawn_puck_carrier != null:
				print("L'IA a la puck: ", ai_pawn_puck_carrier.pawn_name)

				var is_shoot_successful = ActionManager.ai_attempt_shoot(RIGHT_NET_POSITION, ai_pawn_puck_carrier)

				# Si impossible de tirer, on bouge at random
				if (is_shoot_successful == false):
					# move_ai_random()
					var pass_target_pawn = choosing_pass_target(ai_pawn_puck_carrier)
					print("Pass target selection par AI ", pass_target_pawn)


					##FAIRE ATTEMPT PASS DANS ACTION MANAGER
					##GERER LE PASS DISTANCE DANS GAMEMANAGER
					var is_pass_successfull = ActionManager.ai_attempt_pass(ai_pawn_puck_carrier, pass_target_pawn)

					if is_pass_successfull == false:
						chosen_ai_pawn = choosing_pass_target(ai_pawn_puck_carrier, pass_target_pawn)

						is_pass_successfull = ActionManager.ai_attempt_pass(ai_pawn_puck_carrier, pass_target_pawn)

						if is_pass_successfull == false:
							move_ai_random()


			# Si la puck est detenu par un joueur human
			elif human_pawn_puck_carrier != null:
				print("Le joueur humain a la puck: ", human_pawn_puck_carrier.pawn_name)

				chosen_ai_pawn = calculate_distance(human_pawn_puck_carrier.current_cell)

				print("Chosen_Ai_pawn_to Hit ", chosen_ai_pawn)

				var temporary_distance_to_target: int = IceMapLayer.get_hex_distance(chosen_ai_pawn.current_cell, human_pawn_puck_carrier.current_cell)
				print("temporary_distance_to_target ", temporary_distance_to_target)

				# # Si le joueur AI est adjacent au porteur de puck, on frappe
				if temporary_distance_to_target == 1:
					print("tente une frappe")
					var is_hit_successful = ActionManager.ai_attempt_hit(chosen_ai_pawn, human_pawn_puck_carrier.current_cell)

					# Si la frappe est un échec, move at random
					if (is_hit_successful == false):
						print("échec sur frappe")
						move_ai_random()

				elif temporary_distance_to_target <= AGGRESSIVITY_LEVEL:
					move_ai_toward_target(chosen_ai_pawn, human_pawn_puck_carrier.current_cell)


				#Le joueur le plus proche se rapproche le plus possible du porteur de la rondnell
				elif temporary_distance_to_target > AGGRESSIVITY_LEVEL:
					move_ai_closer_target(chosen_ai_pawn, human_pawn_puck_carrier.current_cell, chosen_ai_pawn.move_range)
					

				#Sinon, move at random
				else:
					print("else1")
					move_ai_random()

		else:
			print("else2")
			move_ai_random()


# Move a random pawn in a random tile
func move_ai_random() -> void:
	print("AI move at random")

	var destination_cell = Vector2i(randi_range(0, 5), randi_range(0, 5))

	var selected_ai_pawn = ai_player_pawn_list[randi_range(0, ai_player_pawn_list.size() - 1)]

	print("Selected AI pawn: ", selected_ai_pawn.pawn_name)
	print("From: ", selected_ai_pawn.current_cell, " To: ", destination_cell)

	ActionManager.ai_attempt_move(selected_ai_pawn, selected_ai_pawn.current_cell, destination_cell)


func move_ai_toward_free_puck(puck_position) -> void:
	print("move toward puck at position ", puck_position)

	chosen_ai_pawn = calculate_distance(puck_position)

	#faire bouger le joueur
	var is_move_successful = ActionManager.ai_attempt_move(chosen_ai_pawn, chosen_ai_pawn.current_cell, puck_position)

	if (is_move_successful == false):
		move_ai_random()


func move_ai_toward_target(ai_pawn: Node2D, target_cell: Vector2i) -> void:
	print("move_ai_TOWARD_target")

	var usable_cells: Array = IceMapLayer.get_usable_surrounding_cells(target_cell)
	print("Usable cells around target: ", usable_cells)

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


	print("Final best_cell: ", best_cell)
	print("Final best_distance: ", best_distance)


	if best_cell == ai_pawn.current_cell:
		print("Aucune case valide trouvée autour de la cible")
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
		print("Aucune case libre autour du target")
		return

	var best_path: Array[Vector2i] = []

	for cell in usable_cells:
		var path: Array[Vector2i] = IceMapLayer.find_path(start_cell, cell, false)

		if path.is_empty():
			continue

		if best_path.is_empty() or path.size() < best_path.size():
			best_path = path

	if best_path.is_empty():
		print("Aucun chemin trouvé vers une case autour du target")
		return

	# best_path[0] = position actuelle
	# best_path[1] = première case de déplacement
	# best_path[-1] = case libre autour du target
	var destination_index: int = min(ai_pawn_move_range, best_path.size() - 1)
	var destination_cell: Vector2i = best_path[destination_index]

	print("Best path vers target: ", best_path)
	print("Destination choisie: ", destination_cell)

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


func choosing_pass_target(ai_pawn_puck_carrier: Node2D, removable_pawn: Node2D = null):
	var best_dist: int = 9999
	var best_pawn: Node2D

	print("DANS CHOOSING PASS TARGET")
	print("puck carrier ", ai_pawn_puck_carrier)
	print("removable pawn ", removable_pawn)


	#Check tout tes allié et garde leur distance face au but dans un array
	for ai_pawn in ai_player_pawn_list:
		if ai_pawn == ai_pawn_puck_carrier:
			continue
		if ai_pawn == removable_pawn:
			continue

		var current_dist: int = IceMapLayer.get_hex_distance(ai_pawn.current_cell, RIGHT_NET_POSITION)

		if current_dist < best_dist:
			best_dist = current_dist
			best_pawn = ai_pawn

		return best_pawn
