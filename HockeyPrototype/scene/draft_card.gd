extends PanelContainer


@export var card_id: int = 99
@export var pawnImage: TextureRect
@export var pawn_name: String = "Jack TEST Monoloy"
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var health: int = 98
# @export var bubbleHeadTexture: Texture2D
# @export var fullBodyTexture: Texture2D

@onready var pawn_image: TextureRect = $MarginContainer/VBoxContainer/pawnImage
@onready var pawn_name_label: Label = $MarginContainer/VBoxContainer/pawnNameLabel
@onready var pawn_move_range_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/moveRangeLabel
@onready var pawn_strength_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/strengthLabel
@onready var pawn_reflex_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/reflexLabel
@onready var pawn_health_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/healthLabel


signal card_clicked(card_id: int)



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func setup(player: Dictionary) -> void:
	card_id = player["id"]
	pawn_name_label.text = player["pawn_name"]


	var stats: Dictionary = player["stats"]
	pawn_image.texture = player["image"]
	pawn_move_range_label.text = "Speed %s" % stats["move_range"]
	pawn_strength_label.text = "Strength %s" % stats["strength"]
	pawn_reflex_label.text = "Reflex %s" % stats["reflex"]
	pawn_health_label.text = "Health %s" % stats["health"]


func _on_click_card_button_pressed() -> void:
	card_clicked.emit(card_id)
	# self.queue_free()
