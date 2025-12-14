extends TileMapLayer


class CellState extends RefCounted:
	var blocked:bool = false
	var is_occupied: bool = false
	var is_puck_here: bool = false
	var occupied_player_team: int = 1
	
	
	func _to_string() -> String:
		return "CellState(blocked=%s, is_occupied=%s, puck=%s, team=%d)" % [
			str(blocked),
			str(is_occupied),
			str(is_puck_here),
			occupied_player_team
		]

var is_dragging := false
var drag_start_cell: Vector2i

var pawns: Array = []
var active_pawn: Node2D = null


var map_data: Dictionary = {} # Dictionary<Vector2i, CellState>


const ALT_NORMAL := 0
const ALT_BLOCKED := 1
const LAYER_TYPE   := 0
const LAYER_COST   := 1
const LAYER_BLOCKED := 2


#Signal
signal pawn_selected(pawn)

#OnReady
@onready var players_container := $"../PlayersContainer"
@onready var ts: TileSet = tile_set


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
		_place_pawn_on_cell(p, p.current_cell)
		
		
	
	update_occupancy()
	print_map_data()	


#  maintenant la fonction prend le pawn en paramètre
func _place_pawn_on_cell(pawn: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	pawn.global_position = to_global(local_pos)



func _is_in_range(a: Vector2i, b: Vector2i) -> bool:
	if active_pawn == null:
		return false

	var delta: Vector2i = b - a
	var dist: int = abs(delta.x) + abs(delta.y)  # distance "Manhattan"
	return dist <= active_pawn.move_range
	

func _unhandled_input(event: InputEvent) -> void:
	# 1) Clic / relâche
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_mouse_down(event.position)
		else:
			_on_mouse_up(event.position)

	# 2) Mouvement pendant drag
	if event is InputEventMouseMotion and is_dragging:
		_on_mouse_drag(event.position)


func _on_mouse_down(global_pos: Vector2) -> void:
	var mouse_local := to_local(global_pos)
	var cell := local_to_map(mouse_local)
	
	
	

	active_pawn = null

	# On cherche s'il y a un pion sur cette case
	for p in pawns:
		if p.current_cell == cell:
			active_pawn = p
			break

	if active_pawn != null:
		is_dragging = true
		drag_start_cell = active_pawn.current_cell
		_highlight_unreachable_from(drag_start_cell)
		
		emit_signal("pawn_selected", active_pawn)

		
		
		


func _on_mouse_drag(global_pos: Vector2) -> void:
	# Le pion sélectionné suit la souris
	if active_pawn != null:
		active_pawn.global_position = global_pos


func _on_mouse_up(global_pos: Vector2) -> void:
	if not is_dragging or active_pawn == null:
		return

	is_dragging = false

	var mouse_local := to_local(global_pos)
	var target_cell := local_to_map(mouse_local)

	# On vérifie que la case est dans la grille connue
	if get_cell_source_id(target_cell) == -1:
		# en dehors de la zone → retour à la case de départ
		_place_pawn_on_cell(active_pawn, drag_start_cell)
		_clear_highlight()
		active_pawn = null
		return

	# On vérifie la portée et le blocage
	if _is_in_range(drag_start_cell, target_cell) and not _is_blocked(target_cell) and not _is_cell_occupied(target_cell, active_pawn):
		active_pawn.current_cell = target_cell
		_place_pawn_on_cell(active_pawn, active_pawn.current_cell)
	else:
		# trop loin / bloqué / occupé → retour à la case de départ
		_place_pawn_on_cell(active_pawn, drag_start_cell)


	_clear_highlight()
	active_pawn = null
	
	update_occupancy()
	
	
func _is_cell_occupied(cell: Vector2i, ignore_pawn: Node2D = null) -> bool:
	
	if not map_data.has(cell):
		return false

	# Cas simple : aucune exception
	if ignore_pawn == null:
		return map_data[cell].is_occupied

	if ignore_pawn.current_cell == cell:
		return false
	

	return map_data[cell].is_occupied


func _highlight_unreachable_from(origin: Vector2i) -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		## 1) Si la case n'est pas dans cell_info, on la considère comme non accessible
		#if not cell_info.has(cell):
			#set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
			#continue

		# 2) Case bloquée dans ta logique → alternative
		if _is_blocked(cell):
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
			continue

		# 3) Case hors portée → alternative
		if not _is_in_range(origin, cell):
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
		else:
			# Case accessible : rester en normal
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)


func _clear_highlight() -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		
		
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
		
		
		
func update_occupancy():
	clear_occupancy()

	for pawn in players_container.get_children():
		if not pawn.has_method("get_current_cell"):
			continue

		var cell: Vector2i = pawn.get_current_cell()

		if not map_data.has(cell):
			continue

		var state: CellState = map_data[cell]
		state.is_occupied = true
		state.occupied_player_team = pawn.team_id
		
	
###DEBUG
func print_map_data():
	print("=== MAP DATA DUMP ===")
	print("Cell count:", map_data.size())

	for cell in map_data.keys():
		var state: CellState = map_data[cell]
		print(cell, "=>", state)	
