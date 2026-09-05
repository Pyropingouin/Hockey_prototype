extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	#Fonctionne UNIQUEMENT si le jeu est en pause
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	





func _on_resume_button_pressed() -> void:

	DebugLogger.log(
					DebugLogger.DebugType.GENERAL,
					"resume " 
					)	

	visible = false
	get_tree().paused = false


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/MainMenu_Scene.tscn")
	

func _on_settings_button_pressed() -> void:

	DebugLogger.log(
				DebugLogger.DebugType.GENERAL,
				"pause menu setting button pressed " 
				)	

	
func _on_quit_button_pressed() -> void:

	DebugLogger.log(
					DebugLogger.DebugType.GENERAL,
					"Quit " 
					)	
	get_tree().quit()

