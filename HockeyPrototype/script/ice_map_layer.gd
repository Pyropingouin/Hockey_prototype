extends TileMapLayer

var action_pawn: Node2D = null

class CellState extends RefCounted:
	var blocked: bool = false
	var is_occupied: bool = false
	var is_puck_here: bool = false
	var occupied_player_team: int = -1
	var base_alt_id: int = 0
	var is_behind_goal: bool = false
	var goal_type: String = ""
	
	
	func _to_string() -> String:
		return "CellState(blocked=%s, is_occupied=%s, puck=%s, team=%d, is_behind_goal=%s, goal_type=%s)" % [
			str(blocked),
			str(is_occupied),
			str(is_puck_here),
			occupied_player_team,
			str(is_behind_goal),
			goal_type
	]

var pawns: Array = []
var map_data: Dictionary = {} # Dictionary<Vector2i, CellState>
var current_shoot_targets: Array[Vector2i] = []


const ALT_NORMAL := 0
const ALT_BLOCKED := 1
const ALT_PASS_TARGET := 2
const FLIP_H := 4096
const FLIP_V := 8192
const LAYER_TYPE := 0
const LAYER_COST := 1
const LAYER_BLOCKED := 2


#Signal
signal puck_is_picked_up(pawn)

#OnReady
@onready var players_container := $"../PlayersContainer"
@onready var puck := $"../Puck"
@onready var ts: TileSet = tile_set
@onready var cost_overlay: Node2D = $CostOverlay
@onready var GameManager = $"../GameManager"
@onready var shot_preview: Line2D = $ShotPreview
@onready var shot_arrow_head: Polygon2D = $ShotPreview/ShotArrowHead
@onready var pass_preview: Line2D = $PassPreview
@onready var pass_arrow_head: Polygon2D = $PassPreview/PassArrowHead


func _ready() -> void:
	
	for cell in get_used_cells():
		var state := CellState.new()
		
		var tile_data := get_cell_tile_data(cell)
		if tile_data:
			state.blocked = bool(
				tile_data.get_custom_data("blocked")
			)

			state.is_behind_goal = bool(
				tile_data.get_custom_data("is_behind_goal")
			)

			state.goal_type = str(
				tile_data.get_custom_data("goal_type")
			)

			state.is_occupied = false
			state.occupied_player_team = -1
			state.base_alt_id = get_cell_alternative_tile(cell)
	
		map_data[cell] = state

	# Initialiser les pawns
	for p in players_container.get_children():
		pawns.append(p)
		
		DebugLogger.log(
			DebugLogger.DebugType.ICE_MAP_LAYER,
			"Initialisation de %s | Current cell: %s | Start cell: %s" % [
				p.name,
				p.current_cell,
				p.start_cell
			]
		)
		
		# Connexion dynamique
		if p.has_method("pick_up_puck"):
			connect("puck_is_picked_up", Callable(p, "pick_up_puck"))
			
		_place_pawn_on_cell(p, p.current_cell)
		
	place_puck_on_cell(puck, puck.current_cell)
	
	update_occupancy()
	print_map_data()	


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
	return get_pawn_on_cell(cell)

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
	for character in players_container.get_children():
		if not character.has_method("get_current_cell"):
			continue

		if character.get_current_cell() == cell:
			return character

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

func get_goal_type(cell: Vector2i) -> String:
	if not map_data.has(cell):
		return ""

	return map_data[cell].goal_type

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
			DebugLogger.log(
				DebugLogger.DebugType.ICE_MAP_LAYER,
				"Puck trouvée sur la case %s par %s" % [
					cell_to_check,
					pawn.name
				]
			)
			emit_signal("puck_is_picked_up", pawn)
			map_data[cell_to_check].is_puck_here = false
			

func highlight_shoot_targets(
	origin: Vector2i,
	received_pawn: Node2D,
	range: int
) -> void:
	var shoot_range: int = range

	current_shoot_targets = _compute_shoot_targets(
		origin,
		shoot_range,
		received_pawn
	)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		var is_target := current_shoot_targets.has(cell)

		set_cell(
			cell,
			src_id,
			atlas_coords,
			_get_highlight_alt(
				map_data[cell].base_alt_id,
				not is_target
			)
		)
			
func _compute_shoot_targets(
	origin: Vector2i,
	max_range: int,
	shooting_pawn: Node2D
) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []

	for cell in map_data.keys():
		if cell == origin:
			continue

		if map_data[cell].blocked:
			continue

		var distance: int = get_hex_distance(origin, cell)

		if distance == -1:
			continue

		if distance > max_range:
			continue

		if not is_path_clear(origin, cell):
			continue

		var character_on_target: Node2D = get_pawn_on_cell(cell)

		# Case vide
		if character_on_target == null:
			targets.append(cell)
			continue

		# Gardien adverse
		var is_enemy_goalie: bool = (
			character_on_target is Goalie
			and character_on_target.team_id != shooting_pawn.team_id
		)

		if is_enemy_goalie:
			targets.append(cell)

	return targets
	

func _compute_pass_range(
	origin: Vector2i,
	max_range: int
) -> Array[Vector2i]:

	var range_cells: Array[Vector2i] = []

	for cell in map_data.keys():

		if cell == origin:
			continue

		if map_data[cell].blocked:
			continue

		var distance: int = get_hex_distance(
			origin,
			cell
		)

		if distance == -1:
			continue

		if distance > max_range:
			continue

		# La trajectoire doit être libre
		if not is_path_clear(
			origin,
			cell
		):
			continue

		range_cells.append(cell)

	return range_cells

func highlight_pass_targets(
	origin: Vector2i,
	received_pawn: Node2D,
	range: int
) -> void:

	var pass_range: int = range

	# Toutes les cases où une passe peut théoriquement aller
	var range_cells := _compute_pass_range(
		origin,
		pass_range
	)

	# Seulement les vrais receveurs possibles
	var targets := _compute_pass_targets(
		origin,
		pass_range,
		received_pawn
	)

	for cell in map_data.keys():

		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		var is_in_range := range_cells.has(cell)
		var is_target := targets.has(cell)

		set_cell(
			cell,
			src_id,
			atlas_coords,
			_get_pass_highlight_alt(
				map_data[cell].base_alt_id,
				is_in_range,
				is_target
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

		# Un goalie ne peut jamais recevoir une passe
		if pawn is Goalie:
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

		if not is_path_clear(
			origin,
			pawn.current_cell
		):
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

func get_usable_surrounding_cells(origin: Vector2i) -> Array[Vector2i]:
	var usable_cells: Array[Vector2i] = []

	for cell in get_surrounding_cells(origin):
		if not map_data.has(cell):
			continue

		if map_data[cell].blocked:
			continue

		if map_data[cell].is_occupied:
			continue

		usable_cells.append(cell)

	return usable_cells

func show_shot_preview(
	origin_cell: Vector2i,
	target_cell: Vector2i,
	max_range: int,
	shooting_pawn: Node2D
) -> void:

	if not current_shoot_targets.has(target_cell):
		clear_shot_preview()
		return

	_draw_shot_trajectory_preview(
		origin_cell,
		target_cell
	)

func clear_shot_preview() -> void:
	shot_preview.clear_points()
	shot_preview.visible = false
	shot_arrow_head.visible = false


func clear_pass_preview() -> void:
	pass_preview.clear_points()
	pass_preview.visible = false
	pass_arrow_head.visible = false	


func show_pass_preview(
	origin_cell: Vector2i,
	target_cell: Vector2i,
	max_range: int,
	passing_pawn: Node2D
) -> void:
	var valid_targets := _compute_pass_targets(
		origin_cell,
		max_range,
		passing_pawn
	)

	if not valid_targets.has(target_cell):
		clear_pass_preview()
		return

	_draw_pass_trajectory_preview(
		origin_cell,
		target_cell
	)	


func _draw_shot_trajectory_preview(
	origin_cell: Vector2i,
	target_cell: Vector2i
) -> void:
	var origin_pos: Vector2 = map_to_local(origin_cell)
	var target_pos: Vector2 = map_to_local(target_cell)

	var direction: Vector2 = (
		target_pos - origin_pos
	).normalized()

	var arrow_length := 18.0

	var line_end: Vector2 = (
		target_pos
		- direction * arrow_length
	)

	shot_preview.clear_points()
	shot_preview.add_point(origin_pos)
	shot_preview.add_point(line_end)

	shot_arrow_head.position = target_pos
	shot_arrow_head.rotation = direction.angle()

	shot_preview.visible = true
	shot_arrow_head.visible = true	


func _draw_pass_trajectory_preview(
	origin_cell: Vector2i,
	target_cell: Vector2i
) -> void:
	var origin_pos: Vector2 = map_to_local(origin_cell)
	var target_pos: Vector2 = map_to_local(target_cell)

	var direction: Vector2 = (
		target_pos - origin_pos
	).normalized()

	var arrow_length := 18.0

	var line_end: Vector2 = (
		target_pos
		- direction * arrow_length
	)

	pass_preview.clear_points()
	pass_preview.add_point(origin_pos)
	pass_preview.add_point(line_end)

	pass_arrow_head.position = target_pos
	pass_arrow_head.rotation = direction.angle()

	pass_preview.visible = true
	pass_arrow_head.visible = true		


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


func find_path(
	origin: Vector2i,
	target: Vector2i,
	ignore_occupied_target: bool = true
) -> Array[Vector2i]:
	var came_from: Dictionary = {}
	var queue: Array[Vector2i] = []

	came_from[origin] = null
	queue.append(origin)

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()

		if current == target:
			break

		for next_cell in get_surrounding_cells(current):
			if not map_data.has(next_cell):
				continue

			if came_from.has(next_cell):
				continue

			var state: CellState = map_data[next_cell]

			if state.blocked:
				continue

			# On bloque les cases occupées,
			# sauf si c'est la target finale et qu'on l'autorise.
			if state.is_occupied:
				if not (ignore_occupied_target and next_cell == target):
					continue

			came_from[next_cell] = current
			queue.append(next_cell)

	if not came_from.has(target):
		return []

	var path: Array[Vector2i] = []
	var current = target

	while current != null:
		path.push_front(current)
		current = came_from[current]

	return path


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


func _is_behind_goal(cell: Vector2i) -> bool:
	if not map_data.has(cell):
		return false

	return map_data[cell].is_behind_goal



func _is_goal_cell(cell: Vector2i) -> bool:
	if not map_data.has(cell):
		return false

	return map_data[cell].goal_type != ""	
	


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


func is_path_clear(
	origin: Vector2i,
	target: Vector2i
) -> bool:

	# Depuis derrière le but, impossible de viser directement
	# une case appartenant au but.
	if _is_behind_goal(origin) and _is_goal_cell(target):
		return false

	var cells_on_line := get_cells_on_line(origin, target)

	for cell in cells_on_line:
		if cell == origin:
			continue

		if cell == target:
			continue

		# Le filet bloque la trajectoire.
		if _is_goal_cell(cell):
			return false

		# Les obstacles bloquent la trajectoire.
		if map_data.has(cell) and map_data[cell].blocked:
			return false

		# Les personnages bloquent aussi la trajectoire.
		if get_pawn_on_cell(cell) != null:
			return false

	return true


func _get_pass_highlight_alt(
	base_alt: int,
	is_in_range: bool,
	is_target: bool
) -> int:

	var flip_flags := base_alt & (FLIP_H | FLIP_V)

	if is_target:
		return ALT_PASS_TARGET | flip_flags

	if is_in_range:
		return ALT_NORMAL | flip_flags

	return ALT_BLOCKED | flip_flags	


### DEBUG
func print_map_data() -> void:
	DebugLogger.log(
		DebugLogger.DebugType.ICE_MAP_LAYER,
		"=== MAP DATA DUMP === | Cell count: %s" % map_data.size()
	)

	for cell in map_data.keys():
		var state: CellState = map_data[cell]

		DebugLogger.log(
			DebugLogger.DebugType.ICE_MAP_LAYER,
			"Cell %s => %s" % [cell, state]
		)
