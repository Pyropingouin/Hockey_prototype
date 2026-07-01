extends Node

@onready var GameManager = $"../GameManager"
@onready var IceMapLayer = $"../IceMapLayer"

## HUMAN ACTIONS
func attempt_move(pawn: Node2D, starting_cell: Vector2i, destination_cell: Vector2i) -> void:
  print("pawn in attempt_move ", pawn)

  if IceMapLayer.can_move_pawn_to(pawn, starting_cell, destination_cell):
    IceMapLayer.apply_move(pawn, starting_cell, destination_cell)

    if starting_cell != destination_cell:
      GameManager.update_action_counter(1)
  else:
    IceMapLayer.reset_move(pawn, starting_cell)




























## AI ACTIONS
func ai_attempt_move(chosen_ai_pawn: Node2D, starting_cell, destination_cell):
 
  if IceMapLayer.can_move_pawn_to(chosen_ai_pawn, starting_cell, destination_cell):
    IceMapLayer.apply_move(chosen_ai_pawn, starting_cell, destination_cell)

    #Évite que si on annule le move ou si on drop sur la même case en hésistant
    if (starting_cell != destination_cell):
        GameManager.update_action_counter(1)
        return true

	  
  else:
    IceMapLayer.reset_move(chosen_ai_pawn, starting_cell)
    return false  



func ai_attempt_shoot(target_cell: Vector2i, chosen_ai_pawn: Node2D):
  print("ai attempt shoot")

  if chosen_ai_pawn == null or not chosen_ai_pawn.hasPuck:
    return false

  var action_origin_cell = chosen_ai_pawn.current_cell

  if not GameManager._is_in_shoot_range(action_origin_cell, target_cell, chosen_ai_pawn):
    return false

  if not IceMapLayer.is_shot_path_clear(action_origin_cell, target_cell):
    return false

  if IceMapLayer.get_pawn_on_cell(target_cell) != null:
    return false


  if chosen_ai_pawn.has_method("_shoot"):
    chosen_ai_pawn._shoot(target_cell)
    chosen_ai_pawn = null

  GameManager.update_action_counter(1)
  IceMapLayer.update_occupancy()
  return true


func ai_attempt_hit( chosen_ai_pawn: Node2D, target_cell: Vector2i):
  if chosen_ai_pawn == null or chosen_ai_pawn.hasPuck:
    return false

  var hitTarget: Node2D = IceMapLayer.get_pawn_on_cell(target_cell)    

## OU UN ALLIÉ
  if hitTarget == null:
    return false

  if hitTarget == chosen_ai_pawn:
    return false


  if IceMapLayer.get_hex_distance(chosen_ai_pawn.current_cell, hitTarget.current_cell) > 1:
    return false  



  if chosen_ai_pawn.has_method("_hit"):
    chosen_ai_pawn._hit(target_cell)

  GameManager.update_action_counter(1)
  IceMapLayer.update_occupancy()
  return true

