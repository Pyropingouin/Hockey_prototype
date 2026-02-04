extends Node

var _active_team: int = 1
var active_team:
	get:
		return _active_team
	set(value):
		print("active_team:", _active_team, "->", value)
		_active_team = value
		#Signal émit à chaque changement
		active_team_changed.emit(_active_team)



@onready var activeTeamLabel: Label = $"../ActiveTeamLabel"

signal active_team_changed(active_team_id: int)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_team_changed.emit(_active_team)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_end_turn_button_pressed() -> void:
	if(active_team) == 1:
		active_team = 2
	else:
		active_team = 1		
		
	activeTeamLabel.text = str(active_team)		
	
