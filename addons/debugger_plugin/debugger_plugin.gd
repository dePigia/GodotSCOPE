@tool
extends EditorPlugin


const AUTOLOAD_NAME: String = "Debug"
const AUTOLOAD_SCRIPT: String = "res://addons/debugger_plugin/scripts/autoload/debugger.gd"
const TOOL_PANEL: PackedScene = preload("res://addons/debugger_plugin/scenes/ToolPanel.tscn")
const BRIDGE: Script = preload("res://addons/debugger_plugin/scripts/bridge/debugger_bridge.gd")


var _panel_instance: Control
var _debugger_bridge: EditorDebuggerPlugin


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SCRIPT)


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _enter_tree() -> void:
	_panel_instance = TOOL_PANEL.instantiate()
	EditorInterface.get_editor_main_screen().add_child(_panel_instance)
	_make_visible(false)

	_debugger_bridge = BRIDGE.new(_panel_instance)
	add_debugger_plugin(_debugger_bridge)


func _exit_tree() -> void:
	if _panel_instance:
		_panel_instance.queue_free()
		_panel_instance = null
	if _debugger_bridge:
		remove_debugger_plugin(_debugger_bridge)
		_debugger_bridge = null


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _panel_instance:
		_panel_instance.visible = visible


func _get_plugin_name() -> String:
	return "Debugger"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Terminal", "EditorIcons")
