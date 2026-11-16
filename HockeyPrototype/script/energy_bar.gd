extends PanelContainer

@onready var energy_circles: Array[Panel] = [
	$VBoxContainer/Energy1,
	$VBoxContainer/Energy2,
	$VBoxContainer/Energy3
]

const ACTIVE_COLOR: Color = Color("#53d886")
const EMPTY_COLOR: Color = Color("#ed1920")


func update_energy(current_energy: int) -> void:
	for i in range(energy_circles.size()):
		var style := energy_circles[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.bg_color = ACTIVE_COLOR if i < current_energy else EMPTY_COLOR
		energy_circles[i].add_theme_stylebox_override("panel", style)