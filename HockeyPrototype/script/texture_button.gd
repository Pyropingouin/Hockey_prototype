extends TextureButton


func _ready() -> void:
	update_visual()

func _on_mouse_entered() -> void:
	if disabled:
		return
	modulate = Color(0.8, 0.8, 0.8, 1.0)

func _on_mouse_exited() -> void:
	update_visual()

func update_visual() -> void:
	if disabled:
		modulate = Color(0.5, 0.5, 0.5, 1.0) # gris
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
