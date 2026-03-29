extends TextureButton


func _on_mouse_entered():
	modulate = Color(0.8, 0.8, 0.8, 1.0)

func _on_mouse_exited():
	modulate = Color(1.0, 1.0, 1.0, 1.0)