extends Node2D


const DRAFT_CARD_SCENE := preload("res://scene/draft_card.tscn")

@onready var card_container: HBoxContainer  = $CardContainer



var players := [
	{
		"id": 1,
		"pawn_name": "Aaron White",
		"image": preload("res://assets/Bubble_head/AaronWhite_Bubblehead.png"),
		"stats": {
			"move_range": 4,
			"strength": 4,
			"reflex": 5,
			"health": 6
		}
	},
	{
		"id": 2,
		"pawn_name": "Carlo Monferato",
		"image": preload("res://assets/Bubble_head/CarloMonferato_Bubblehead.png"),
		"stats": {
			"move_range": 3,
			"strength": 6,
			"reflex": 4,
			"health": 5
		}
	},
	{
		"id": 3,
		"pawn_name": "Dan Demers",
		"image": preload("res://assets/Bubble_head/DanDemers_BubbleaHead.png"),
		"stats": {
			"move_range": 5,
			"strength": 3,
			"reflex": 6,
			"health": 4
		}
	}
]







# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	

	for player in players:
		var card = DRAFT_CARD_SCENE.instantiate()
		card_container.add_child(card)
		card.setup(player)
		card.card_clicked.connect(_on_card_clicked)




func _on_card_clicked(clicked_card_id: int) -> void:
	print("Carte cliquée :", clicked_card_id)
