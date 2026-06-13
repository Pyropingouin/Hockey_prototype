extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_resume_button_pressed() -> void:
	print("resume")
	visible = false
	get_tree().paused = false


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/MainMenu_Scene.tscn")
	

func _on_settings_button_pressed() -> void:
	print("pause menu setting button pressed")

	
func _on_quit_button_pressed() -> void:
	print("Quit")
	get_tree().quit()

