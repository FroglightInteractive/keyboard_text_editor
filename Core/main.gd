extends Control

@onready var editor: CodeEdit = $MarginContainer/VBoxContainer/Editor


func _ready() -> void:
	editor.grab_focus()
