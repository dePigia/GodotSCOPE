@tool

class_name Debugger
extends EditorPlugin


const TOOL_PANEL: PackedScene = preload("res://addons/debugger_plugin/scenes/ToolPanel.tscn")


var panel_instance: Control


func _enter_tree() -> void:
	panel_instance = TOOL_PANEL.instantiate()

	EditorInterface.get_editor_main_screen().add_child(panel_instance)

	_make_visible(false)


func _exit_tree() -> void:
	if panel_instance:
		panel_instance.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if panel_instance:
		panel_instance.visible = visible


func _get_plugin_name() -> String:
	return "Prova"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Terminal", "EditorIcons")
