extends Node2D

@onready var sprite: Sprite2D = $CardDisplaySprite


func _ready():
		
	pass

func _on_game_manager_pawn_selected(pawn: Variant) -> void:
	print("Pion Reçu ", pawn)
	print(pawn.hasPuck)
	
	sprite.texture = pawn.fullBodyTexture
	$Move.text = "SPEED: " + str(pawn.move_range)

	$Strength.text = "STRENGTH: " +str(pawn.strength)
	$Reflex.text = "REFLEX: " +str(pawn.reflex)
