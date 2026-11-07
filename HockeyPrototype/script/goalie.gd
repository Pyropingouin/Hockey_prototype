class_name Goalie
extends CharacterBody2D

var goalie_name: String
var team_id: int
var save_power: int


# var _hasPuck: bool = false
var flash_tween: Tween

# var hasPuck: bool:
# 	get:
# 		return _hasPuck
# 	set(value):
# 		if _hasPuck == value:
# 			return

# 		_hasPuck = value

# 		if not is_node_ready():
# 			return

# 		if _hasPuck:
# 			start_red_flash()
# 		else:
# 			stop_red_flash()

var current_cell: Vector2i
var move_range: int = 1


var fullBodyTexture: Texture2D
var bubbleHeadTexture: Texture2D
var goalie_textures: Dictionary = {}


var net_position: Vector2i
var front_position: Vector2i
var up_position: Vector2i
var down_position: Vector2i

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# if hasPuck:
	# 	start_red_flash()

	pass


func setup(goalie_data: Dictionary, new_team_id: int, new_start_cell: Vector2i) -> void:
	goalie_name = goalie_data["goalie_name"]
	team_id = new_team_id
	current_cell = new_start_cell
	save_power = goalie_data["save_power"]


	var sprite_paths: Dictionary = goalie_data.get("goalie_sprites", {})

	for key in sprite_paths:
		goalie_textures[key] = load(sprite_paths[key])

	sprite = get_node("Sprite2D") as Sprite2D
	update_goalie_sprite("MID")



# func pick_up_puck(pawn: Node2D) -> void:
# 	if pawn != self:
# 		return

# 	hasPuck = true

# 	DebugLogger.log(
# 		DebugLogger.DebugType.GOALIE,
# 		"%s récupère la puck" % goalie_name
# 	)	


func attempt_save(shooter_reflex: int) -> bool:
	var save_difference: int = save_power - shooter_reflex


	
	DebugLogger.log(
	DebugLogger.DebugType.GOALIE,
	"%s tente un arrêt. Save Power:  %s |  Reflex du tireur:  %s | Différence: %s  " % [
		goalie_name,
		save_power,
		shooter_reflex,
		save_difference
	]
)		

	# Le goalie n'a aucune chance si son save_power
	# n'est pas supérieur au reflex du tireur.
	if save_difference < 1:
		return false

	var save_chance: float = min(
		float(save_difference) * 0.20,
		0.90
	)

	var random_roll: float = randf()
	var save_successful: bool = random_roll < save_chance


	DebugLogger.log(
	DebugLogger.DebugType.GOALIE,
	"Chance d'arrêt: %s%% | Jet:  %s  | Réussite:  %s" % [
		save_chance * 100.0,
		random_roll,
		save_successful
		]
	)		


	return save_successful


func set_goalie_positions(positions: Dictionary) -> void:
	net_position = positions["net"]
	front_position = positions["front"]
	up_position = positions["up"]
	down_position = positions["down"]


func reset_board() -> void:
	current_cell = front_position

	var ice_map_layer = get_node("../../IceMapLayer")
	ice_map_layer.place_pawn_on_cell(self, current_cell)

func get_current_cell() -> Vector2i:
	return current_cell



func move_goalie_prototype(puck_cell) -> void:
	var roll = randi_range(1,3)
	var target_cell: Vector2i
	var ice_map_layer = get_node("../../IceMapLayer")
	var puck_zone = ice_map_layer.get_iceRink_zone(puck_cell)

	print("PUCK ZONE", puck_zone)
	

	print(goalie_name, "roll: ", roll)

	
	if puck_zone == "MID":
		target_cell = front_position

	elif puck_zone == "TOP":
		target_cell = up_position

	elif puck_zone == "BOT":
		target_cell = down_position

	else:
		target_cell = current_cell


	if current_cell == target_cell:
		return

	if ice_map_layer.can_move_pawn_to(self, current_cell, target_cell):
		ice_map_layer.apply_move(self, current_cell, target_cell)
		update_goalie_sprite(puck_zone)

	

func update_goalie_sprite(zone: String) -> void:
	var side: String = "home" if team_id == 1 else "away"
	var texture_key: String = side + "_" + zone.to_lower()

	if not goalie_textures.has(texture_key):
		push_warning("Texture de gardien introuvable : " + texture_key)
		return

	sprite.texture = goalie_textures[texture_key]
	sprite.flip_h = team_id == 1		

	

# #### TEMPORAIRE

# func start_red_flash() -> void:
# 	if flash_tween:
# 		flash_tween.kill()

# 	sprite.modulate = Color.WHITE

# 	flash_tween = create_tween()
# 	flash_tween.set_loops()

# 	flash_tween.tween_property(
# 		sprite,
# 		"modulate",
# 		Color.RED,
# 		0.35
# 	)

# 	flash_tween.tween_property(
# 		sprite,
# 		"modulate",
# 		Color.WHITE,
# 		0.35
# 	)


# func stop_red_flash() -> void:
# 	if flash_tween:
# 		flash_tween.kill()

# 	sprite.modulate = Color.WHITE
