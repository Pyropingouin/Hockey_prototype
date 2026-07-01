extends Control


func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_resume_button_pressed() -> void:
	print("Resume")
	visible = false
	get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
	print("MAIN")
	get_tree().change_scene_to_file("res://scene/MainMenu_Scene.tscn")


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	print("QUIT")
	get_tree().quit()
