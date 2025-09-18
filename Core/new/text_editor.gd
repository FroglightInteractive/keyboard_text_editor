extends Control

@onready var editor: TextEdit = $VBoxContainer/TextEdit
@onready var mode_indicator: Label = $VBoxContainer/HBoxContainer/ModeIndicator
@onready var command_bar: LineEdit = $VBoxContainer/CommandBar
@onready var caret_pos: Label = $VBoxContainer/HBoxContainer/CaretPos
@onready var current_file_label: Label = $VBoxContainer/HBoxContainer/CurrentFileLabel
@onready var help_screen: RichTextLabel = $VBoxContainer/HelpScreen
@onready var error_label: Label = $VBoxContainer/HBoxContainer/ErrorLabel

enum EditorMode {
	NORMAL,
	INSERT,
	COMMAND,
}
var mode: EditorMode = EditorMode.NORMAL

var in_help: bool = false


func _ready() -> void:
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
						_show_help()
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
	
	match cmd:
		"q":
			get_tree().quit()
		"w":
			_save(args)
		"o":
			_open(args)
		"help":
			_show_help()
		_:
			mark_error("Invalid Command", 2)
	
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
		current_file_label.text = save_path
	else:
		save_path = current_file_label.text.strip_edges()
		if save_path == "":
			return
		
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(editor.text)
		file.close()
	else:
		mark_error("Could not save to '%s'" % save_path, 2)


func _open(args: Array) -> void:
	if args:
		var path = path_to_os(args[0])
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var file_text = file.get_as_text()
			editor.text = file_text
			current_file_label.text = path
		else:
			mark_error("File '%s' not found" % path, 2)
	else:
		mark_error("Command 'open' needs a file name", 2)


func _hide_help() -> void:
	in_help = false
	help_screen.hide()
	editor.show()
	editor.grab_focus()


func _show_help() -> void:
	in_help = true
	help_screen.show()
	editor.hide()


func mark_error(error_text: String, time: float = 0.0) -> void:
	error_label.text = error_text
	
	if time > 0.0:
		await get_tree().create_timer(time).timeout
		error_label.text = ""
