extends PanelContainer

@onready var editor: TextEdit = $"../TextEdit"
@onready var current_file_label: Label = $MarginContainer/HBoxContainer/CurrentFileLabel
@onready var caret_pos_label: Label = $MarginContainer/HBoxContainer/CaretPosLabel


func _process(_delta: float) -> void:
	caret_pos_label.text = "Ln " +\
		str(editor.get_caret_line() + 1) + "/ " +\
		str(editor.get_line_count()) + ": Col " +\
		str(editor.get_caret_column() + 1)
