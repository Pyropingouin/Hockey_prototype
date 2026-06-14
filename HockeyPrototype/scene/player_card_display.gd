extends Control

@export var card_id: int = 99
@export var pawnImage: TextureRect
@export var pawn_name: String = "Jack TEST Monoloy"
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var health: int = 98
# @export var bubbleHeadTexture: Texture2D
# @export var fullBodyTexture: Texture2D

@onready var pawn_image: TextureRect = $VBoxCardContainer/TopArea/TextureRectBubbleHead
@onready var pawn_name_label: Label = $VBoxCardContainer/NameArea/NameLabel
@onready var pawn_move_range_label: Label = $VBoxCardContainer/BottomArea/BottomAreaGridContainer/SpeedArea/SpeedLabel
@onready var pawn_strength_label: Label = $VBoxCardContainer/BottomArea/BottomAreaGridContainer/ReflexArea/ReflexLabel
@onready var pawn_reflex_label: Label = $VBoxCardContainer/BottomArea/BottomAreaGridContainer/StrengthArea/StrengthLabel
@onready var pawn_health_label: Label = $VBoxCardContainer/BottomArea/BottomAreaGridContainer/HitArea/HitLabel


func setup(player: Dictionary) -> void:

	card_id = player["id"]
	pawn_name_label.text = player["pawn_name"]


	var stats: Dictionary = player["stats"]
	pawn_image.texture = player["bubblehead"]
	pawn_move_range_label.text = "Speed %s" % stats["move_range"]
	pawn_strength_label.text = "Strength %s" % stats["strength"]
	pawn_reflex_label.text = "Reflex %s" % stats["reflex"]
	pawn_health_label.text = "Health %s" % stats["health"]
