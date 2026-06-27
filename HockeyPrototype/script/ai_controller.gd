extends Control


@onready var GameManager = $"../GameManager"

func _ready() -> void:
   pass

func turn_inside_ai() -> void:
    print("Ai controller")
    GameManager.active_team_action_counter += 1
    return   