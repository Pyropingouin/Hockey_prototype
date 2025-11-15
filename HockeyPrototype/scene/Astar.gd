extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var astargrid = AStarGrid2D.new()
	astargrid.size = Vector2i(32,32)
	astargrid.cell_size = Vector2i(16,16)
	astargrid.update()
	
	astargrid.set_point_solid(Vector2i(1,1), true)
