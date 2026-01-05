extends Node2D

@onready var sprite: Sprite2D = $CardDisplaySprite


func _ready():
		
	pass


func _on_ice_map_layer_pawn_selected(pawn: Variant) -> void:
	print("Pawn Recu", pawn)
	sprite.texture = pawn.fullBodyTexture
	$Move.text = "SPEED: " + str(pawn.move_range)

	$Strength.text = "STRENGTH: " +str(pawn.strength)
	$Reflex.text = "REFLEX: " +str(pawn.reflex)
