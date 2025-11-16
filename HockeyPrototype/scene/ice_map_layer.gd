extends TileMapLayer

var cell_info: Dictionary = {}

var current_cell: Vector2i           # position actuelle du pion
var is_dragging := false
var drag_start_cell: Vector2i

const ALT_NORMAL := 0
const ALT_BLOCKED := 1

@onready var pawn := $"../Pawn"      # adapte le chemin si besoin

func _ready() -> void:
	for cell in get_used_cells():
		cell_info[cell] = {
			"type": "ice",
			"cost": 1,
			"blocked": false,
		}

	# Position de départ du pion
	current_cell = Vector2i(0, 0)
	_place_pawn_on_cell(current_cell)


func _place_pawn_on_cell(cell: Vector2i) -> void:
	var local_pos = map_to_local(cell)
	pawn.global_position = to_global(local_pos)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta := b - a
	return abs(delta.x) + abs(delta.y) == 1   # haut / bas / gauche / droite uniquement


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
	# On clique : vérifier si on clique sur la case du pion
	var mouse_local := to_local(global_pos)
	var cell := local_to_map(mouse_local)

	if cell == current_cell:
		is_dragging = true
		drag_start_cell = current_cell
		# (optionnel) tu peux mettre un petit offset visuel ou animation ici
		
	_highlight_unreachable_from(drag_start_cell)	


func _on_mouse_drag(global_pos: Vector2) -> void:
	# Le pion suit simplement la souris
	pawn.global_position = global_pos


func _on_mouse_up(global_pos: Vector2) -> void:
	if not is_dragging:
		return

	is_dragging = false

	var mouse_local := to_local(global_pos)
	var target_cell := local_to_map(mouse_local)

	# On vérifie que la case est dans la grille connue
	if not cell_info.has(target_cell):
		# en dehors de la zone → retour à la case de départ
		_place_pawn_on_cell(drag_start_cell)
		return

	# On vérifie l'adjacence
	if _is_adjacent(drag_start_cell, target_cell):
		current_cell = target_cell
		_place_pawn_on_cell(current_cell)
	else:
		# trop loin / diagonale → retour à la case de départ
		_place_pawn_on_cell(drag_start_cell)
		
	_clear_highlight()
	
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

		# 3) Case non adjacente → alternative
		if not _is_adjacent(origin, cell):
			set_cell(cell, src_id, atlas_coords, ALT_BLOCKED)
		else:
			# Case accessible : rester en normal
			set_cell(cell, src_id, atlas_coords, ALT_NORMAL)		
		
		
func _clear_highlight() -> void:
	for cell in get_used_cells():
		var src_id := get_cell_source_id(cell)
		var atlas_coords := get_cell_atlas_coords(cell)
		set_cell(cell, src_id, atlas_coords, ALT_NORMAL)		
