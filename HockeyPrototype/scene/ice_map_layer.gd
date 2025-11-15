extends TileMapLayer

var cell_info: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for cell in get_used_cells():
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
