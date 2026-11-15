extends Node

signal event_logged(message: String, color: Color)

func send_log(message: String, color: Color = Color.WHITE) -> void:
    event_logged.emit(message, color)