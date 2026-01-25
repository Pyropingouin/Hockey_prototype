extends TileMapLayer

enum ActionMode { NONE, SHOOT, PASS, TACKLE }
var action_mode: ActionMode = ActionMode.NONE
var action_pawn: Node2D = null
var action_origin_cell: Vector2i = Vector2i.ZERO


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
signal puck_is_picked_up(pawn)


#OnReady
@onready var players_container := $"../PlayersContainer"
@onready var puck := $"../Puck"
@onready var ts: TileSet = tile_set
@onready var cost_overlay: Node2D = $CostOverlay
@onready var action_menu = $"../CanvasLayer/PopupMenu"




func _ready() -> void:
	action_menu.id_pressed.connect(_on_action_menu_pressed)

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


#  maintenant la fonction prend le pawn en paramètre
func _place_pawn_on_cell(pawn: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	pawn.global_position = to_global(local_pos)
	
	
func _place_puck_on_cell(puck_node: Node2D, cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	puck_node.global_position = to_global(local_pos)
		



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
			_on_left_mouse_down(event.position)
		else:
			_on_left_mouse_up(event.position)		
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_on_right_mouse_down(event.position)
		else: 
			_on_right_mouse_up(event.position)	
			
	if event.is_action_pressed("ui_cancel") and action_mode != ActionMode.NONE:
		_cancel_action_mode()
		return
				

	# 2) Mouvement pendant drag
	if event is InputEventMouseMotion and is_dragging:
		_on_mouse_drag(event.position)


func _on_left_mouse_down(global_pos: Vector2) -> void:
	var mouse_local := to_local(global_pos)
	var cell := local_to_map(mouse_local)
	
	if action_mode != ActionMode.NONE:
		_handle_action_click(global_pos)
		return

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


func _on_left_mouse_up(global_pos: Vector2) -> void:
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


	_check_for_puck_on_ice(target_cell, active_pawn)
	_clear_highlight()
	active_pawn = null
	
	update_occupancy()
	
	
func _on_right_mouse_down(global_pos: Vector2) -> void:
	var mouse_local := to_local(global_pos)
	var cell := local_to_map(mouse_local)

	active_pawn = null

	# On cherche s'il y a un pion sur cette case
	for p in pawns:
		if p.current_cell == cell:
			active_pawn = p
			break
			
			
	print (active_pawn)
	_open_context_menu(global_pos)
	

func _on_right_mouse_up(global_pos: Vector2) -> void:
	print ("left up")
	print (global_pos)		
	
func _on_mouse_drag(global_pos: Vector2) -> void:
	# Le pion sélectionné suit la souris
	if active_pawn != null:
		active_pawn.global_position = global_pos
	
	
func _open_context_menu(screen_pos: Vector2) -> void:
	action_menu.clear()

	action_menu.add_item("Plaquer", 0)
	action_menu.add_item("Passer", 1)
	action_menu.add_item("Shoot", 2)
	
	if !active_pawn.hasPuck:
		action_menu.set_item_disabled(2, true)

		

	action_menu.position = screen_pos
	action_menu.popup()
	
func _on_action_menu_pressed(id: int) -> void:
	match id:
		0:
			print("Plaquage")
		1:
			print("Passe")
		2:
				## SHOOT HERE
			print("Shoot")	
			_start_action_shoot()
	
	
	
	
func _start_action_shoot() -> void:
	if active_pawn == null or not active_pawn.hasPuck:
		return

	action_mode = ActionMode.SHOOT
	action_pawn = active_pawn
	action_origin_cell = active_pawn.current_cell

	# Optionnel: highlight les cases visables / portées de tir
	# _highlight_shoot_targets(action_origin_cell)

	# Ferme le menu
	action_menu.hide()
	
	
func _handle_action_click(global_pos: Vector2) -> void:
	var mouse_local := to_local(global_pos)
	var target_cell := local_to_map(mouse_local)

	# 1) la cellule doit exister
	if get_cell_source_id(target_cell) == -1:
		_cancel_action_mode()
		return

	# 2) selon le mode
	match action_mode:
		ActionMode.SHOOT:
			_do_shoot(target_cell)
		ActionMode.PASS:
			pass
			#_do_pass(target_cell)
		ActionMode.TACKLE:
			pass
			#_do_tackle(target_cell)

func _do_shoot(target_cell: Vector2i) -> void:
	if action_pawn == null or not action_pawn.hasPuck:
		_cancel_action_mode()
		return

	# Optionnel: valider une portée de tir (ex: move_range * 2)
	# if not _is_in_shoot_range(action_origin_cell, target_cell):
	#     return

	
	if action_pawn.has_method("_shoot"):
		action_pawn._shoot(target_cell)
	#else:
		## fallback si tu gardes ton signal direct
		#action_pawn.emit_signal("shooting_puck", target_cell)
		#action_pawn.hasPuck = false

	update_occupancy()
	_cancel_action_mode()
			
	
func _cancel_action_mode() -> void:
	action_mode = ActionMode.NONE
	action_pawn = null
	_clear_highlight() # si tu highlights des cibles	
	
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
	var reachable := _compute_reachable_cells(origin, active_pawn.move_range)

	for cell in map_data.keys():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		if reachable.has(cell):
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		else:
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)

	_show_costs(reachable)


func _clear_highlight() -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		set_cell(cell, src_id, atlas_coords, ALT_NORMAL)
		
	_clear_cost_overlay()
	
		
		
		
## Algo Breadth-First Search (BFS)
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

###DEBUG
func print_map_data():
	print("=== MAP DATA DUMP ===")
	print("Cell count:", map_data.size())

	for cell in map_data.keys():
		var state: CellState = map_data[cell]
		print(cell, "=>", state)	
		
