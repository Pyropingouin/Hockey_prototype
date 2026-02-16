extends TileMapLayer



var action_pawn: Node2D = null

class CellState extends RefCounted:
	var blocked:bool = false
	var is_occupied: bool = false
	var is_puck_here: bool = false
	var occupied_player_team: int = -1
	
	
	func _to_string() -> String:
		return "CellState(blocked=%s, is_occupied=%s, puck=%s, team=%d)" % [
			str(blocked),
			str(is_occupied),
			str(is_puck_here),
			occupied_player_team
		]

var pawns: Array = []
var map_data: Dictionary = {} # Dictionary<Vector2i, CellState>


const ALT_NORMAL := 0
const ALT_BLOCKED := 1
const LAYER_TYPE   := 0
const LAYER_COST   := 1
const LAYER_BLOCKED := 2


#Signal
signal puck_is_picked_up(pawn)



#OnReady
@onready var players_container := $"../PlayersContainer"
@onready var puck := $"../Puck"
@onready var ts: TileSet = tile_set
@onready var cost_overlay: Node2D = $CostOverlay
@onready var action_menu = $"../CanvasLayer/PopupMenu"
@onready var GameManager = $"../GameManager"




func _process(_delta: float) -> void:
	
	pass

func _ready() -> void:
	

	for cell in get_used_cells():
		var state := CellState.new()
		

		
		var tile_data := get_cell_tile_data(cell)
		if tile_data :
			state.blocked = tile_data.get_custom_data("blocked")
			state.is_occupied = false
			state.occupied_player_team = -1
			
		
		map_data[cell] = state	



	# Initialiser les pawns
	for p in players_container.get_children():
		pawns.append(p)
		# Pour l’instant tu mets tout le monde à (0,0)
		# Plus tard tu pourras donner une case de départ différente à chaque pion
		
		print(p.name, p.current_cell, p.start_cell)
		
		# Connexion dynamique
		if p.has_method("pick_up_puck"):
			connect("puck_is_picked_up", Callable(p, "pick_up_puck"))
			
	
		
		_place_pawn_on_cell(p, p.current_cell)
		
	
	_place_puck_on_cell(puck, puck.current_cell)	
	
	update_occupancy()
	print_map_data()	


func cell_from_global_pos(global_pos: Vector2) -> Vector2i:
	var local_pos := to_local(global_pos)
	return local_to_map(local_pos)
	
func get_ice_map_layer_cell_id(cell):
	return get_cell_source_id(cell)
	
	

func pawn_at_cell(cell: Vector2i) -> Node2D:
	for p in pawns:
		if p.current_cell == cell:
			return p
	return null

func cell_exists(cell: Vector2i) -> bool:
	return get_cell_source_id(cell) != -1

func is_cell_blocked(cell: Vector2i) -> bool:
	if not map_data.has(cell):
		return true
	return map_data[cell].blocked

func is_cell_occupied(cell: Vector2i, ignore_pawn: Node2D = null) -> bool:
	if not map_data.has(cell):
		return false
	if ignore_pawn != null and ignore_pawn.current_cell == cell:
		return false
	return map_data[cell].is_occupied

func is_in_move_range(pawn: Node2D, origin: Vector2i, target: Vector2i) -> bool:
	var d := target - origin
	var dist: int = abs(d.x) + abs(d.y)
	return dist <= pawn.move_range

func can_move_pawn_to(pawn: Node2D, origin: Vector2i, target: Vector2i) -> bool:
	if pawn == null:
		return false
	if not cell_exists(target):
		return false
	if is_cell_blocked(target):
		return false
	if is_cell_occupied(target, pawn):
		return false
	if not is_in_move_range(pawn, origin, target):
		return false
	return true

func place_pawn_on_cell(pawn: Node2D, cell: Vector2i) -> void:
	# place visuellement + tu peux garder ton update_occupancy() ici
	var local_pos := map_to_local(cell)
	pawn.global_position = to_global(local_pos)

func apply_move(pawn: Node2D, origin: Vector2i, target: Vector2i) -> void:
	# met à jour la donnée + place visuellement + occupancy + puck
	pawn.current_cell = target
	place_pawn_on_cell(pawn, target)
	update_occupancy()
	_check_for_puck_on_ice(target, pawn)

func reset_move(pawn: Node2D, origin: Vector2i) -> void:
	pawn.current_cell = origin
	place_pawn_on_cell(pawn, origin)
	update_occupancy()

func show_move_reachability(origin: Vector2i, move_range: int) -> void:
	var reachable := _compute_reachable_cells(origin, move_range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		if reachable.has(cell):
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		else:
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)

	_show_costs(reachable)


#   maintenant la fonction prend le pawn en paramètre
func _place_pawn_on_cell(pawn: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	pawn.global_position = to_global(local_pos)
	
	update_occupancy()
	
	
func _place_puck_on_cell(puck_node: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	puck_node.global_position = to_global(local_pos)
	
	var pawn_on_cell := get_pawn_on_cell(cell)
	if pawn_on_cell != null and puck.isPickedUp == false:
		emit_signal("puck_is_picked_up", pawn_on_cell)
		# si tu veux que la puck "disparaisse" du sol immédiatement :
		puck.isPickedUp = true
		if map_data.has(cell):
			map_data[cell].is_puck_here = false
		

func get_pawn_on_cell(cell: Vector2i) -> Node2D:
	# tu peux utiliser pawns (ton array) ou players_container.get_children()
	for p in pawns:
		if p.current_cell == cell:
			return p
	return null

func highlight_unreachable_from(origin: Vector2i, max_range: int) -> void:
	var reachable := _compute_reachable_cells(origin, max_range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		if reachable.has(cell):
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		else:
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)

	_show_costs(reachable)



func clear_highlight() -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		
	_clear_cost_overlay()
	
	
func _clear_cost_overlay() -> void:
	for child in cost_overlay.get_children():
		child.queue_free()

func _show_costs(reachable: Dictionary) -> void:
	_clear_cost_overlay()

	for cell in reachable.keys():
		var dist: int = int(reachable[cell])
		if dist == 0:
			continue # optionnel: ne pas afficher sur la case de départ

		var label := Label.new()
		label.text = str(dist)

		# position au centre de la case
		var local_pos: Vector2 = map_to_local(cell)
		label.position = local_pos - label.size * 0.5  # petit centrage

		cost_overlay.add_child(label)
		
	
func _get_custom(cell: Vector2i, layer_name: String):
	var tile_data = get_cell_tile_data(cell)
	if tile_data == null:
		return null
	return tile_data.get_custom_data(layer_name)


func _get_type(cell: Vector2i) -> String:
	return str(_get_custom(cell, "type"))

func _get_cost(cell: Vector2i) -> int:
	return int(_get_custom(cell, "cost"))

func _is_blocked(cell: Vector2i) -> bool:
	return bool(_get_custom(cell, "blocked"))


func clear_occupancy():
	for state in map_data.values():
		state.is_occupied = false
		state.occupied_player_team = -1
		state.is_puck_here = false
		
		
		
func update_occupancy():
	clear_occupancy()

   #Pawn
	for pawn in players_container.get_children():
		if not pawn.has_method("get_current_cell"):
			continue

		var cell: Vector2i = pawn.get_current_cell()

		if not map_data.has(cell):
			continue

		var state: CellState = map_data[cell]
		state.is_occupied = true
		state.occupied_player_team = pawn.team_id
		
	#Puck
	if puck != null and puck.has_method("get_current_cell"):
		var puck_cell: Vector2i = puck.get_current_cell()
		if map_data.has(puck_cell):
			map_data[puck_cell].is_puck_here = true
	
	

func _check_for_puck_on_ice(cell_to_check: Vector2i, pawn: Node2D):
	if not map_data.has(cell_to_check):
		return
	
	
	if puck.isPickedUp == false :
		if map_data[cell_to_check].is_puck_here:
			print("puck here")
			
			emit_signal("puck_is_picked_up", pawn)
			
			map_data[cell_to_check].is_puck_here = false
			
			

	
	

	
 
func highlight_shoot_targets(origin: Vector2i, action_pawn: Node2D) -> void:
	var range: int = action_pawn.move_range * 2
	
	
	var targets := _compute_shoot_targets(origin, range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		if targets.has(cell):
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		else:
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
			
			
			
			
func _compute_shoot_targets(origin: Vector2i, max_range: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	for cell in map_data.keys():
 		# distance Manhattan
		var dist:int = abs(cell.x - origin.x) + abs(cell.y - origin.y)
		if dist == 0 or dist > max_range:
			continue

 		# mur logique
		if map_data[cell].blocked:
			continue

 		# OK comme cible
		targets.append(cell)

	return targets			
	

func highlight_pass_targets(origin: Vector2i, action_pawn: Node2D) -> void:	
	var range: int = action_pawn.move_range * 2
	var targets := _compute_pass_targets(origin, range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		if targets.has(cell):
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		else:
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
			
			
			
func _compute_pass_targets(origin: Vector2i, max_range: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	for p in pawns:
		if p == action_pawn:
			continue


 		## TODO Remettre pour équipe
 		# règle équipe (ajuste selon ton gameplay)
 		#if p.team_id != action_pawn.team_id:
 			#continue

		var cell: Vector2i = p.current_cell

 		# portée (Manhattan)
		var dist: int = abs(cell.x - origin.x) + abs(cell.y - origin.y)
		if dist > max_range:
			continue

 		# optionnel: pas à travers les murs (si tu veux)
 		# if not _has_line_of_sight(origin, cell):
 		#     continue

		targets.append(cell)

	return targets
			


### Algo Breadth-First Search (BFS)
func _compute_reachable_cells(origin: Vector2i, max_range: int) -> Dictionary:
	# Dictionary<Vector2i, int>  (cell -> distance)
	var reachable: Dictionary = {} # Vector2i -> int
	var queue: Array[Vector2i] = []

	# Initialisation
	reachable[origin] = 0
	queue.append(origin)

	var directions = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]

	while queue.size() > 0:
		var current: Vector2i = queue.pop_front()
		var current_dist: int = reachable[current]

		for dir in directions:
			var next: Vector2i = current + dir

			# 1) La cellule doit exister dans la map
			if not map_data.has(next):
				continue

			var state: CellState = map_data[next]

			# 2) Mur logique = bloqué OU occupé
			if state.blocked or state.is_occupied:
				continue

			# 3) Distance max
			var next_dist := current_dist + 1
			if next_dist > max_range:
				continue

			# 4) Déjà visité avec une meilleure distance
			if reachable.has(next):
				continue

			reachable[next] = next_dist
			queue.append(next)

	return reachable	
###DEBUG
func print_map_data():
	print("=== MAP DATA DUMP ===")
	print("Cell count:", map_data.size())

	for cell in map_data.keys():
		var state: CellState = map_data[cell]
		print(cell, "=>", state)	
		
