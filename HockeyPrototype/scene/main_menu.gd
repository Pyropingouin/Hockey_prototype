extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Viewport size: ", get_viewport().get_visible_rect().size)
	print("Window size: ", DisplayServer.window_get_size())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Game_Scene.tscn")
	

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_draft_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Draft_Scene.tscn")
