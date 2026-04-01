extends Node2D

@onready var sprite: Sprite2D = $CardDisplaySprite

var selected_pawn

func _ready():
		
	pass

func _on_game_manager_pawn_selected(selected_pawn: Variant) -> void:
	print("Pion Reçu ", selected_pawn)
	
	if(selected_pawn != null):
	
		print(selected_pawn.hasPuck)
		
		sprite.texture = selected_pawn.fullBodyTexture
		$Move.text = "SPEED: " + str(selected_pawn.move_range)

		$Strength.text = "STRENGTH: " +str(selected_pawn.strength)
		$Reflex.text = "REFLEX: " +str(selected_pawn.reflex)
		
	else:
		sprite.texture = null
		$Move.text = "SPEED: "
		$Strength.text = "STRENGTH: "
		$Reflex.text ="REFLEX: "
			
