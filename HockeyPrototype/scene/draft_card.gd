extends PanelContainer


@export var card_id: int = 99
@export var pawn_name: String = "Jack Monoloy"
@export var move_range: int = 2
@export var strength: int = 2
@export var reflex: int = 3
@export var health: int = 98
@export var bubbleHeadTexture: Texture2D
@export var fullBodyTexture: Texture2D

@onready var pawn_name_label: Label = $MarginContainer/VBoxContainer/pawnNameLabel
@onready var pawn_move_range_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/moveRangeLabel
@onready var pawn_strength_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/strengthLabel
@onready var pawn_reflex_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/reflexLabel
@onready var pawn_health_label: Label = $MarginContainer/VBoxContainer/StatsPanel/StatsArea/healthLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

	#Pawn image = pass from something
	

	pawn_name_label.text = pawn_name
	pawn_move_range_label.text = "Speed: " + str(move_range)
	pawn_strength_label.text = "Strength: " + str(strength)
	pawn_reflex_label.text = "Reflex: " + str(reflex)
	pawn_health_label.text = "Health: " + str(health)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_click_card_button_pressed() -> void:
	print("Card Draft Clicked")
