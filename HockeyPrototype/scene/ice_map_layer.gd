extends TileMapLayer

var cell_info: Dictionary = {}
var current_cell: Vector2i  # position actuelle du pion en coordonnées de grille

@onready var pawn = $"../Pawn"



func _ready() -> void:
	#Retourne une liste de toute les cellules ou j'ai peint une tuile. 
	for cell in get_used_cells():
		#Assigne des propriété à ces tuile dans le dictionnaire
		cell_info[cell] = {
			"type" :"ice",
			"cost": 1,
			"blocked": false,
		}
		
	# Position de départ du pion (par exemple (0,0))
	current_cell = Vector2i(0, 0)

	# On place le pion sur cette cellule
	var local_pos = map_to_local(current_cell)
	pawn.global_position = to_global(local_pos)		

func _process(delta: float) -> void:
	var mouse_local = to_local(get_global_mouse_position())
	var cell = local_to_map(mouse_local)

	if cell_info.has(cell):
		var data = cell_info[cell]
		print("Cell", cell, "type:", data["type"], "cost:", data["cost"])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed:

		# Position de la souris → position locale dans le TileMapLayer
		var mouse_local = to_local(event.position)
		# Position locale → coordonnée de cellule
		var target_cell = local_to_map(mouse_local)

		# On vérifie si la cellule existe dans la grille
		if not cell_info.has(target_cell):
			return

		# Vérifier si la case est adjacente
		if _is_adjacent(current_cell, target_cell):
			_move_pawn_to(target_cell)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta = b - a
	# Différence de 1 sur un axe, 0 sur l'autre → pas de diagonale
	return abs(delta.x) + abs(delta.y) == 1


func _move_pawn_to(cell: Vector2i) -> void:
	current_cell = cell
	var local_pos = map_to_local(cell)
	pawn.global_position = to_global(local_pos)
