extends TileMapLayer

var cell_info: Dictionary = {}



func _ready() -> void:
	#Retourne une liste de toute les cellules ou j'ai peint une tuile. 
	for cell in get_used_cells():
		#Assigne des propriété à ces tuile dans le dictionnaire
		cell_info[cell] = {
			"type" :"ice",
			"cost": 1,
			"blocked": false,
		}	

func _process(delta: float) -> void:
	var mouse_local = to_local(get_global_mouse_position())
	var cell = local_to_map(mouse_local)

	if cell_info.has(cell):
		var data = cell_info[cell]
		print("Cell", cell, "type:", data["type"], "cost:", data["cost"])
