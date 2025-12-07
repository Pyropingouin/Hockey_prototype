extends Node2D

@onready var sprite: Sprite2D = $CardDisplaySprite


func _ready():
		
	pass


func _on_ice_map_layer_pawn_selected(pawn: Variant) -> void:
	print("Pawn Recu", pawn)
	sprite.texture = pawn.fullBodyTexture
	
