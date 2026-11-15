extends CanvasLayer

@onready var log_text: RichTextLabel = $Control/LogPanel/MarginContainer/VBoxContainer/LogText


const MAX_LOGS: int = 50

var logs: Array[Dictionary] = []

func _ready() -> void:
	EventBus.event_logged.connect(add_log)

func add_log(message: String, color: Color = Color.WHITE) -> void:
	logs.append({
		"message": message,
		"color": color
	})

	if logs.size() > MAX_LOGS:
		logs.pop_front()

	_refresh_log_display()

func _refresh_log_display() -> void:
	log_text.clear()

	for entry in logs:
		var message: String = entry["message"]
		var color: Color = entry["color"]
		var color_html: String = color.to_html(false)

		log_text.append_text("[color=#%s]%s[/color]\n" % [color_html, message])

func clear_logs() -> void:
	logs.clear()
	log_text.clear()
