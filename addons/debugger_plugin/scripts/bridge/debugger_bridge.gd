@tool
extends EditorDebuggerPlugin


const CHANNEL: String = "debugger_pl"
const MSG_HELLO: String = "debugger_pl:hello"
const MSG_BATCH: String = "debugger_pl:batch"
const MSG_ALARM: String = "debugger_pl:alarm"
const MSG_CONFIG: String = "debugger_pl:config"


var _panel_instance: Control


func _init(panel: Control) -> void:
    _panel_instance = panel
    _panel_instance.config_changed.connect(_send_config_to_all)


func _has_capture(prefix: String) -> bool:
    return prefix == CHANNEL


func _send_config(session_id: int) -> void:
    var session: EditorDebuggerSession = get_session(session_id)
    if session.is_active():
        session.send_message(MSG_CONFIG, _panel_instance.build_config())


func _send_config_to_all() -> void:
    for i in get_sessions():
        if i.is_active(): 
            i.send_message(MSG_CONFIG, _panel_instance.build_config())