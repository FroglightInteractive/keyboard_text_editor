extends Control

@onready var editor: CodeEdit = $MarginContainer/VBoxContainer/TextEdit
@onready var mode_indicator: Label = $MarginContainer/VBoxContainer/HBoxContainer/ModeIndicator
@onready var command_bar: LineEdit = $MarginContainer/VBoxContainer/CommandBar
@onready var caret_pos: Label = $MarginContainer/VBoxContainer/HBoxContainer/CaretPos
@onready var current_file_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CurrentFileLabel
@onready var help_screen: RichTextLabel = $MarginContainer/VBoxContainer/HelpScreen
@onready var error_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/ErrorLabel

const ALIAS_SAVE_PATH: String = "user://settings/aliases.json"

enum EditorMode {
	NORMAL,
	INSERT,
	COMMAND,
}
var mode: EditorMode = EditorMode.NORMAL

var commands: Dictionary[String, Callable] = {
	"help": _show_help,
	"q": _quit,
	"q!": _force_quit,
	"w": _save,
	"wq": _save_and_quit,
	"o": _open,
	"alias": _make_alias,
}

var command_aliases: Dictionary[String, String] = {
	"quit": "q",
	"write": "w",
	"open": "o",
	"h": "help",
}

var in_help: bool = false
var filename: String = ""
var is_dirty: bool = false


func _ready() -> void:
	if not DirAccess.dir_exists_absolute("user://settings/"):
		DirAccess.make_dir_absolute("user://settings/")

	set_filename("")

	load_aliases()

	update_ui()
	editor.grab_focus()
	command_bar.hide()
	help_screen.hide()


func _unhandled_input(event: InputEvent) -> void:
	if in_help:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			_hide_help()
			accept_event()
		return

	if event is InputEventKey and event.pressed:
		match mode:
			EditorMode.NORMAL:
				match event.keycode:
					KEY_I:
						mode = EditorMode.INSERT
						update_ui()
					KEY_SEMICOLON:
						if event.shift_pressed:
							mode = EditorMode.COMMAND
							command_bar.text = ""
							command_bar.show()
							command_bar.grab_focus()
							update_ui()
					KEY_H:
						editor.set_caret_column(editor.get_caret_column() - 1)
					KEY_L:
						editor.set_caret_column(editor.get_caret_column() + 1)
					KEY_J:
						editor.set_caret_line(editor.get_caret_line() + 1)
					KEY_K:
						editor.set_caret_line(editor.get_caret_line() - 1)
					KEY_F1:
						_show_help([])
			EditorMode.INSERT:
				match event.keycode:
					KEY_ESCAPE:
						mode = EditorMode.NORMAL
						update_ui()
			EditorMode.COMMAND:
				match event.keycode:
					KEY_ESCAPE:
						mode = EditorMode.NORMAL
						command_bar.hide()
						editor.grab_focus()
						update_ui()
	accept_event()


func update_ui() -> void:
	match mode:
		EditorMode.NORMAL:
			mode_indicator.text = "NORMAL"
			editor.editable = false
		EditorMode.INSERT:
			mode_indicator.text = "INSERT"
			editor.editable = true
		EditorMode.COMMAND:
			mode_indicator.text = "COMMAND"
			editor.editable = false


func _on_command_bar_text_submitted(new_text: String) -> void:
	new_text = new_text.strip_edges()
	var args = new_text.split(" ")
	var cmd = args[0]
	args.remove_at(0)

	# aliases
	if command_aliases.has(cmd):
		cmd = command_aliases[cmd]

	if commands.has(cmd):
		commands[cmd].call(args)
	elif cmd == "":
		mark_error("No command given")
	else:
		mark_error("Invalid Command")

	mode = EditorMode.NORMAL
	command_bar.hide()
	editor.grab_focus()
	update_ui()


func _on_command_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				mode = EditorMode.NORMAL
				command_bar.hide()
				editor.grab_focus()
				update_ui()
				accept_event()


func _on_text_edit_caret_changed() -> void:
	caret_pos.text = "Ln " + str(editor.get_caret_line() + 1) + " : Col " + str(editor.get_caret_column() + 1)


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


func _save(args: Array) -> void:
	var save_path: String
	if args.size() > 0:
		# save as
		save_path = path_to_os(args[0])
		set_filename(save_path)
	else:
		save_path = filename.strip_edges()
		if save_path == "":
			mark_error("No file path specified")
			return

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(editor.text)
		file.close()
		is_dirty = false
	else:
		mark_error("Could not save to '%s'" % save_path)


func _open(args: Array) -> void:
	if args:
		var path = path_to_os(args[0])
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var file_text = file.get_as_text()
			editor.text = file_text
			set_filename(path)
			is_dirty = false
		else:
			mark_error("File '%s' not found" % path)
	else:
		mark_error("Command 'open' needs a file name")


func _hide_help() -> void:
	in_help = false
	help_screen.hide()
	editor.show()
	editor.grab_focus()


func _show_help(_args: Array) -> void:
	in_help = true
	help_screen.show()
	editor.hide()


func mark_error(error_text: String, time: float = 2.0) -> void:
	error_label.text = error_text

	if time > 0.0:
		await get_tree().create_timer(time).timeout
		error_label.text = ""


func save_aliases() -> void:
	var file = FileAccess.open(ALIAS_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(command_aliases, "\t")
		file.store_string(json_string)
		file.close()
	else:
		mark_error("Could not save aliases")


func load_aliases() -> void:
	var file = FileAccess.open(ALIAS_SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var aliases = JSON.parse_string(text)

		for key in aliases.keys():
			command_aliases[key] = aliases[key]
	else:
		mark_error("Could not load aliases")


func _make_alias(args: Array) -> void:
	# for list do, alias
	# for remove do, alias -r/-remove aliasname
	# for make, do alias aliasname command

	match args.size():
		0:
			_list_aliases()
		2:
			var alias_name = args[0]
			var real_cmd = args[1]

			if alias_name == "-r" or alias_name == "-remove":
				_remove_alias(real_cmd)

			elif commands.has(real_cmd):
				command_aliases[alias_name] = real_cmd
				save_aliases()
				print("Alias '%s' -> '%s' added" % [alias_name, real_cmd])
			else:
				mark_error("alias: command '%s' not found" % real_cmd)
		_:
			mark_error("Usage: alias <name> <command>")


func _quit(_args: Array) -> void:
	if is_dirty:
		mark_error("No write since last change (add ! to override)")
	else:
		get_tree().quit()


func _force_quit(_args: Array) -> void:
	get_tree().quit()


func _save_and_quit(_args: Array) -> void:
	_save([])
	if not is_dirty:
		get_tree().quit()


func _list_aliases() -> void:
	pass


func _remove_alias(alias: String) -> void:
	if command_aliases.has(alias):
		command_aliases.erase(alias)
		save_aliases()
	else:
		mark_error("alias: cannot remove alias '%s', does not exist" % alias)


func set_filename(file_name: String) -> void:
	filename = file_name
	if file_name == "":
		current_file_label.text = "[no file]"
	else:
		current_file_label.text = file_name


func _on_text_edit_text_changed() -> void:
	is_dirty = true
