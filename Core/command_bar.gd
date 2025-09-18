extends LineEdit


func _ready() -> void:
	keep_editing_on_text_submit = true


func _on_command_submitted(command: String) -> void:
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
		_:
			print("invalid command")
	clear()


func _save(args: Array) -> void:
	print(args)


func _open(args: Array) -> void:
	print(args)


func _quit() -> void:
	get_tree().quit()
