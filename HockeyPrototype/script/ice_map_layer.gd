extends TileMapLayer

var action_pawn: Node2D = null

class CellState extends RefCounted:
	var blocked:bool = false
	var is_occupied: bool = false
	var is_puck_here: bool = false
	var occupied_player_team: int = -1
	var base_alt_id: int = 0
	
	
	func _to_string() -> String:
		return "CellState(blocked=%s, is_occupied=%s, puck=%s, team=%d)" % [
			str(blocked),
			str(is_occupied),
			str(is_puck_here),
			occupied_player_team
		]

var pawns: Array = []
var map_data: Dictionary = {} # Dictionary<Vector2i, CellState>


const ALT_NORMAL  := 0
const ALT_BLOCKED := 1
const FLIP_H      := 4096
const FLIP_V      := 8192
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
@onready var GameManager = $"../GameManager"


func _ready() -> void:

	for cell in get_used_cells():
		var state := CellState.new()
		
		var tile_data := get_cell_tile_data(cell)
		if tile_data:
			state.blocked = tile_data.get_custom_data("blocked")
			state.is_occupied = false
			state.occupied_player_team = -1
		state.base_alt_id = get_cell_alternative_tile(cell)
	
		map_data[cell] = state	

	# Initialiser les pawns
	for p in players_container.get_children():
		pawns.append(p)
		
		print(p.name, p.current_cell, p.start_cell)
		
		# Connexion dynamique
		if p.has_method("pick_up_puck"):
			connect("puck_is_picked_up", Callable(p, "pick_up_puck"))
			
		_place_pawn_on_cell(p, p.current_cell)
		
	place_puck_on_cell(puck, puck.current_cell)	
	
	update_occupancy()
	# print_map_data()	


# Retourne l'alt_id correct en préservant les flags de flip
func _get_highlight_alt(base_alt: int, blocked: bool) -> int:
	var flip_flags := base_alt & (FLIP_H | FLIP_V)
	var base := ALT_BLOCKED if blocked else ALT_NORMAL
	return base | flip_flags


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

func is_in_move_range(
	pawn: Node2D,
	origin: Vector2i,
	target: Vector2i
) -> bool:
	var reachable := _compute_reachable_cells(
		origin,
		pawn.move_range
	)

	return reachable.has(target)

func can_move_pawn_to(
	pawn: Node2D,
	origin: Vector2i,
	target: Vector2i
) -> bool:
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


func can_push_pawn_to(pawn: Node2D, target: Vector2i) -> bool:
	if pawn == null:
		return false
	if not cell_exists(target):
		return false
	if is_cell_blocked(target):
		return false
	if is_cell_occupied(target, pawn):
		return false
	return true

func place_pawn_on_cell(pawn: Node2D, cell: Vector2i) -> void:
	var local_pos := map_to_local(cell)
	pawn.global_position = to_global(local_pos)

func apply_move(pawn: Node2D, origin: Vector2i, target: Vector2i) -> void:
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
		var is_reachable := reachable.has(cell)
		set_cell(cell, src_id, atlas_coords, _get_highlight_alt(map_data[cell].base_alt_id, !is_reachable))

	_show_costs(reachable)


func _place_pawn_on_cell(pawn: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	pawn.global_position = to_global(local_pos)
	update_occupancy()
	
	
func place_puck_on_cell(puck_node: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	puck_node.global_position = to_global(local_pos)
	
	var pawn_on_cell := get_pawn_on_cell(cell)
	if pawn_on_cell != null and puck.isPickedUp == false:
		emit_signal("puck_is_picked_up", pawn_on_cell)
		puck.isPickedUp = true
		if map_data.has(cell):
			map_data[cell].is_puck_here = false
		

func get_pawn_on_cell(cell: Vector2i) -> Node2D:
	for p in pawns:
		if p.current_cell == cell:
			return p
	return null

func highlight_unreachable_from(origin: Vector2i, max_range: int) -> void:
	var reachable := _compute_reachable_cells(origin, max_range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		var is_reachable := reachable.has(cell)
		set_cell(cell, src_id, atlas_coords, _get_highlight_alt(map_data[cell].base_alt_id, !is_reachable))

	_show_costs(reachable)


func clear_highlight() -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		set_cell(cell, src_id, atlas_coords, map_data[cell].base_alt_id)
		
	_clear_cost_overlay()
	
	
func _clear_cost_overlay() -> void:
	for child in cost_overlay.get_children():
		child.queue_free()

func _show_costs(reachable: Dictionary) -> void:
	_clear_cost_overlay()

	for cell in reachable.keys():
		var dist: int = int(reachable[cell])
		if dist == 0:
			continue

		var label := Label.new()
		label.text = str(dist)

		var tile_center: Vector2 = map_to_local(cell)
		var label_size: Vector2 = label.get_minimum_size()

		label.position = tile_center - label_size * 0.5

		cost_overlay.add_child(label)
		
	
func _get_custom(cell: Vector2i, layer_name: String):
	var tile_data = get_cell_tile_data(cell)
	if tile_data == null:
		return null
	return tile_data.get_custom_data(layer_name)


func _get_type(cell: Vector2i) -> String:
	return str(_get_custom(cell, "type"))

func _get_goal_type(cell: Vector2i) -> String:
	return str(_get_custom(cell, "goal_type"))	

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

	# Pawn
	for pawn in players_container.get_children():
		if not pawn.has_method("get_current_cell"):
			continue

		var cell: Vector2i = pawn.get_current_cell()

		if not map_data.has(cell):
			continue

		var state: CellState = map_data[cell]
		state.is_occupied = true
		state.occupied_player_team = pawn.team_id
		
	# Puck
	if puck != null and puck.has_method("get_current_cell"):
		var puck_cell: Vector2i = puck.get_current_cell()
		if map_data.has(puck_cell):
			map_data[puck_cell].is_puck_here = true
	

func _check_for_puck_on_ice(cell_to_check: Vector2i, pawn: Node2D):
	if not map_data.has(cell_to_check):
		return
	
	if puck.isPickedUp == false:
		if map_data[cell_to_check].is_puck_here:
			print("puck here")
			emit_signal("puck_is_picked_up", pawn)
			map_data[cell_to_check].is_puck_here = false
			

func highlight_shoot_targets(origin: Vector2i, recieved_pawn: Node2D) -> void:
	var _range: int = recieved_pawn.move_range * 2
	var targets := _compute_shoot_targets(origin, _range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		var is_target := targets.has(cell)
		set_cell(cell, src_id, atlas_coords, _get_highlight_alt(map_data[cell].base_alt_id, !is_target))
			
			
func _compute_shoot_targets(
	origin: Vector2i,
	max_range: int
) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	for cell in map_data.keys():
		if cell == origin:
			continue

		if map_data[cell].blocked:
			continue

		var distance := get_hex_distance(origin, cell)

		if distance == -1:
			continue

		if distance > max_range:
			continue

		if not is_shot_path_clear(origin, cell):
			continue

		targets.append(cell)

	return targets	
	

func highlight_pass_targets(
	origin: Vector2i,
	received_pawn: Node2D
) -> void:
	var pass_range: int = received_pawn.move_range * 2

	var targets := _compute_pass_targets(
		origin,
		pass_range,
		received_pawn
	)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		var is_target := targets.has(cell)

		set_cell(
			cell,
			src_id,
			atlas_coords,
			_get_highlight_alt(
				map_data[cell].base_alt_id,
				not is_target
			)
		)
			
			
func _compute_pass_targets(
	origin: Vector2i,
	max_range: int,
	passing_pawn: Node2D
) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	for pawn in pawns:
		if not is_instance_valid(pawn):
			continue

		if pawn == passing_pawn:
			continue

		if pawn.team_id != passing_pawn.team_id:
			continue

		var distance := get_hex_distance(
			origin,
			pawn.current_cell
		)

		if distance == -1:
			continue

		if distance > max_range:
			continue

		targets.append(pawn.current_cell)

	return targets
			

func highlight_hit_targets(origin: Vector2i, recieved_pawn: Node2D) -> void:
	var targets := _compute_hit_targets(origin, recieved_pawn)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		var is_target := targets.has(cell)
		set_cell(cell, src_id, atlas_coords, _get_highlight_alt(map_data[cell].base_alt_id, !is_target))


func _compute_hit_targets(
	origin: Vector2i,
	received_pawn: Node2D
) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	for cell in get_surrounding_cells(origin):
		if not map_data.has(cell):
			continue

		if map_data[cell].blocked:
			continue

		var target_pawn := get_pawn_on_cell(cell)

		if target_pawn == null:
			continue

		if target_pawn == received_pawn:
			continue

		targets.append(cell)

	return targets



func show_shot_preview(origin_cell, target_cell, max_range):
	pass

func clear_shot_preview():
	pass		

func _compute_shot_path(origin_cell, target_cell, max_range):
	pass


### Algo Breadth-First Search (BFS)
func _compute_reachable_cells(
	origin: Vector2i,
	max_range: int
) -> Dictionary:
	var reachable: Dictionary = {}
	var queue: Array[Vector2i] = []

	reachable[origin] = 0
	queue.append(origin)

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var current_dist: int = reachable[current]

		for next_cell in get_surrounding_cells(current):
			if not map_data.has(next_cell):
				continue

			var state: CellState = map_data[next_cell]

			if state.blocked:
				continue

			if state.is_occupied:
				continue

			var next_dist: int = current_dist + 1

			if next_dist > max_range:
				continue

			if reachable.has(next_cell):
				continue

			reachable[next_cell] = next_dist
			queue.append(next_cell)

	return reachable


func get_hex_distance(
	origin: Vector2i,
	target: Vector2i
) -> int:
	if origin == target:
		return 0

	var visited: Dictionary = {}
	var queue: Array[Vector2i] = []

	visited[origin] = 0
	queue.append(origin)

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		var current_distance: int = visited[current]

		for neighbor in get_surrounding_cells(current):
			if not map_data.has(neighbor):
				continue

			if visited.has(neighbor):
				continue

			var distance: int = current_distance + 1

			if neighbor == target:
				return distance

			visited[neighbor] = distance
			queue.append(neighbor)

	return -1	


func get_cells_on_line(
	origin: Vector2i,
	target: Vector2i
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	var origin_position: Vector2 = map_to_local(origin)
	var target_position: Vector2 = map_to_local(target)

	var hex_distance: int = get_hex_distance(origin, target)

	if hex_distance <= 0:
		return [origin]

	# Plusieurs échantillons par hexagone pour éviter de sauter une cellule.
	var sample_count: int = hex_distance * 12

	for i in range(sample_count + 1):
		var weight: float = float(i) / float(sample_count)

		var sampled_position: Vector2 = origin_position.lerp(
			target_position,
			weight
		)

		var sampled_cell: Vector2i = local_to_map(sampled_position)

		if not cells.has(sampled_cell):
			cells.append(sampled_cell)

	return cells


func is_shot_path_clear(
	origin: Vector2i,
	target: Vector2i
) -> bool:
	var cells_on_line := get_cells_on_line(origin, target)

	for cell in cells_on_line:
		# Le tireur ne bloque pas son propre tir.
		if cell == origin:
			continue

		# La cible finale est gérée séparément par le GameManager.
		if cell == target:
			continue

		if get_pawn_on_cell(cell) != null:
			return false

	return true


### DEBUG
func print_map_data():
	print("=== MAP DATA DUMP ===")
	print("Cell count:", map_data.size())

	for cell in map_data.keys():
		var state: CellState = map_data[cell]
		print(cell, "=>", state)
