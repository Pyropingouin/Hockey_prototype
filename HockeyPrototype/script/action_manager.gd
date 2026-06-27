extends Node

@onready var GameManager = $"../GameManager"
@onready var IceMapLayer = $"../IceMapLayer"


func attempt_move(active_pawn, starting_cell, destination_cell):
 

  if IceMapLayer.can_move_pawn_to(GameManager.active_pawn, starting_cell, destination_cell):
    IceMapLayer.apply_move(GameManager.active_pawn, starting_cell, destination_cell)

    #Évite que si on annule le move ou si on drop sur la même case en hésistant
    if (starting_cell != destination_cell):
        GameManager.update_action_counter(1)

	  
  else:
    IceMapLayer.reset_move(GameManager.active_pawn, starting_cell)
