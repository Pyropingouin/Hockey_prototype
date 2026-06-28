extends Node


@onready var GameManager = $"../GameManager"
@onready var ActionManager = $"../ActionManager"
@onready var IceMapLayer = $"../IceMapLayer"
@onready var players_container: Node = $"../PlayersContainer"
@onready var puck := $"../Puck"

var ai_player_pawn_list: Array = []
var human_player_pawn_list: Array = []


func turn_inside_ai() -> void:


   #Connaitre tout les pawn, alliés et ennemies
   for pawn in players_container.get_children():
      if pawn.team_id ==2:
         ai_player_pawn_list.append(pawn)
      if pawn.team_id ==1:
         human_player_pawn_list.append(pawn)   




   

   while GameManager.active_team == 2 and GameManager.active_team_action_counter < GameManager.max_action_counter:

      #Connaitre la puck
      var puck_position = puck.current_cell
      var is_puck_held = puck.isPickedUp


      await get_tree().create_timer(1.0).timeout
     

      


      if(is_puck_held == false):
         move_ai_toward_free_puck(puck_position)




      elif(is_puck_held == true):
         pass
         # Check si c'est qui a la puck


         # if(ally_in_puck_position == true)


      
      # print("puck position ", puck_position) 
      # print("is_puck_held ", is_puck_held)




      else:
       move_ai_random()




      print(ai_player_pawn_list)
      print("Ai controller")

      # return   




# Move a random pawn in a random tile
func move_ai_random() -> void:

      print("AI move at random")
   
      var destination_cell = Vector2i(randi_range(0, 5), randi_range(0, 5))

      var selected_ai_pawn = ai_player_pawn_list[randi_range(0, ai_player_pawn_list.size()-1)]

      print("AI pawns count: ", ai_player_pawn_list.size())
      print("Selected AI pawn: ", selected_ai_pawn.pawn_name)
      print("From: ", selected_ai_pawn.current_cell, " To: ", destination_cell)

      GameManager.active_pawn = selected_ai_pawn


      ActionManager.attempt_move(selected_ai_pawn,selected_ai_pawn.current_cell, destination_cell)
      
func move_ai_toward_free_puck(puck_position) -> void:
   print("move toward puck at position ", puck_position)

   
   var shortest_distance = 999
   var chosen_ai_pawn = null

   for pawn in ai_player_pawn_list:
      # trouver la distance entre la puck et le joueur
      var pawn_distance_with_puck = IceMapLayer.get_hex_distance(pawn.current_cell, puck_position)

      print("Pawn test ",pawn )

      # si le joueur actuelle est plus proche, garder ça distance en mémoire
      if pawn_distance_with_puck < shortest_distance:
         shortest_distance = pawn_distance_with_puck
         chosen_ai_pawn = pawn


   print("chosen pawn ",chosen_ai_pawn)
   print("shortest_distance ", shortest_distance) 

   #faire bouger le joueur

   GameManager.active_pawn = chosen_ai_pawn
   ActionManager.attempt_move(chosen_ai_pawn,chosen_ai_pawn.current_cell, puck_position)



## ATTENTION, peut-être que le pawn ne marchera pas

      

