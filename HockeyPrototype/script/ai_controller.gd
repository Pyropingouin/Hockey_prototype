extends Node


@onready var GameManager = $"../GameManager"
@onready var ActionManager = $"../ActionManager"
@onready var players_container: Node = $"../PlayersContainer"


func turn_inside_ai() -> void:

   var ai_player_pawn_list: Array = []
   var human_player_pawn_list: Array = []

   for pawn in players_container.get_children():
      if pawn.team_id ==2:
         ai_player_pawn_list.append(pawn)
      if pawn.team_id ==1:
         human_player_pawn_list.append(pawn)   

   


   while GameManager.active_team == 2 and GameManager.active_team_action_counter < GameManager.max_action_counter:

      await get_tree().create_timer(1.0).timeout

      var destination_cell = Vector2i(randi_range(0, 5), randi_range(0, 5))

      var selected_ai_pawn = ai_player_pawn_list[randi_range(0, 3)]

      print("AI pawns count: ", ai_player_pawn_list.size())
      print("Selected AI pawn: ", selected_ai_pawn.pawn_name)
      print("From: ", selected_ai_pawn.current_cell, " To: ", destination_cell)

      GameManager.active_pawn = selected_ai_pawn


      ActionManager.attempt_move(selected_ai_pawn,selected_ai_pawn.current_cell, destination_cell)
      
      

      
   



  
	
   print(ai_player_pawn_list)
   print("Ai controller")

   return   
