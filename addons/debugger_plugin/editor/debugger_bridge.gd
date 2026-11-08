@tool
extends EditorDebuggerPlugin


const PROTOCOL: Script = preload("res://addons/debugger_plugin/protocol.gd")


var _panel_instance: Control


func _init(panel: Control) -> void:
    _panel_instance = panel
    _panel_instance.config_changed.connect(_send_config_to_all)


func _has_capture(prefix: String) -> bool:
    return prefix == PROTOCOL.CHANNEL


func _setup_session(session_id: int) -> void:
    var session: EditorDebuggerSession = get_session(session_id)

    session.started.connect(_panel_instance.begin_run)
    session.stopped.connect(_panel_instance.end_run)
    session.breaked.connect(func(_can_debug: bool) -> void: _panel_instance.on_breaked())
    session.continued.connect(_panel_instance.on_continued)


func _capture(message: String, data: Array, session_id: int) -> bool:
    match message:
        PROTOCOL.MSG_INITIALIZE:
            _send_config(session_id)
            return true
        PROTOCOL.MSG_BATCH:
            _panel_instance.add_batch(data[0], data[1], data[2], data[3])
            return true
        PROTOCOL.MSG_ALARM:
            _panel_instance.add_alarm(data[0], data[1])
            return true
    
    return false


func _send_config(session_id: int) -> void:
    var session: EditorDebuggerSession = get_session(session_id)
    if session.is_active():
        session.send_message(PROTOCOL.MSG_CONFIG, _panel_instance.build_config())


func _send_config_to_all() -> void:
    for i in get_sessions():
        if i.is_active(): 
            i.send_message(PROTOCOL.MSG_CONFIG, _panel_instance.build_config())