

extends TileMapLayer

var cell_info: Dictionary = {}

var is_dragging := false
var drag_start_cell: Vector2i

var pawns: Array = []
var active_pawn: Node2D = null

const ALT_NORMAL := 0
const ALT_BLOCKED := 1


signal pawn_selected(pawn)


@onready var players_container := $"../PlayersContainer"

func _ready() -> void:
	for cell in get_used_cells():
		cell_info[cell] = {
			"type": "ice",
			"cost": 1,
			"blocked": false,
		}

	# Initialiser les pawns
	for p in players_container.get_children():
		pawns.append(p)
		# Pour l’instant tu mets tout le monde à (0,0)
		# Plus tard tu pourras donner une case de départ différente à chaque pion
		p.current_cell = p.start_cell
		_place_pawn_on_cell(p, p.current_cell)


# 👉 maintenant la fonction prend le pawn en paramètre
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
	if not cell_info.has(target_cell):
		# en dehors de la zone → retour à la case de départ
		_place_pawn_on_cell(active_pawn, drag_start_cell)
		_clear_highlight()
		active_pawn = null
		return

	# On vérifie la portée et le blocage
	if _is_in_range(drag_start_cell, target_cell) and not cell_info[target_cell]["blocked"]:
		active_pawn.current_cell = target_cell
		_place_pawn_on_cell(active_pawn, active_pawn.current_cell)
	else:
		# trop loin / non autorisé → retour à la case de départ
		_place_pawn_on_cell(active_pawn, drag_start_cell)

	_clear_highlight()
	active_pawn = null


func _highlight_unreachable_from(origin: Vector2i) -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)

		# 1) Si la case n'est pas dans cell_info, on la considère comme non accessible
		if not cell_info.has(cell):
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
			continue

		# 2) Case bloquée dans ta logique → alternative
		if cell_info[cell]["blocked"]:
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
