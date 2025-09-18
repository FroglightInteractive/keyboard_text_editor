extends LineEdit

@onready var editor: TextEdit = $"../Editor"
@onready var error_label: Label = $"../StatusBar/MarginContainer/HBoxContainer/ErrorLabel"
@onready var help_display: RichTextLabel = $"../HelpDisplay"

var in_help: bool = false


func _ready() -> void:
	keep_editing_on_text_submit = true


func _on_command_submitted(command: String) -> void:
	error_label.text = ""
	command = command.strip_edges()
	var args = command.split(" ")
	var cmd = args[0]
	args.remove_at(0)
	match cmd:
		"save", "w":
			_save(args)
		"open", "o":
			_open(args)
		"quit", "q", "exit":
			_quit()
		"help", "h":
			_help()
		_:
			mark_error("Invalid Command!")
	clear()


func _save(args: Array) -> void:
	print(args)


func _open(args: Array) -> void:
	if args:
		var path = path_to_os(args[0])
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var file_text = file.get_as_text()
			editor.text = file_text
		else:
			mark_error("File: '%s' not found!" % path)
	else:
		mark_error("'open' needs a file name!")


func _quit() -> void:
	if in_help:
		help_display.hide()
		editor.show()
		in_help = false
	else:
		get_tree().quit()


func path_to_os(path: String) -> String:
	var os = OS.get_name()
	if os == "Windows" or os == "UWP":
		return path.replace("/", "\\")
	else:
		return path

func path_from_os(path: String) -> String:
	var os = OS.get_name()
	if os == "Windows" or os == "UWP":
		return path.replace("\\", "/")
	else:
		return path


func mark_error(error_text: String, time: float = 0.0) -> void:
	error_label.text = error_text
	
	if time != 0.0:
		await get_tree().create_timer(time).timeout
		error_label.text = ""


func _help() -> void:
	editor.hide()
	help_display.show()
	in_help = true
