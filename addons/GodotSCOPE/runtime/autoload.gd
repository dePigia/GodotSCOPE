extends Node


const PROTOCOL: Script = preload("res://addons/GodotSCOPE/protocol.gd")
const BATCH_SAMPLES: int = 10


var _check_every_n: int = 2
var _watches: Array[Dictionary] = []
var _rules: Array[Dictionary] = []

var _batch: PackedFloat32Array = PackedFloat32Array()
var _batch_start: int = 0
var _batch_count: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)

	if not EngineDebugger.is_active():
		return
	
	EngineDebugger.register_message_capture(PROTOCOL.CHANNEL, _on_message)
	EngineDebugger.send_message(PROTOCOL.MSG_INITIALIZE, [])


func _physics_process(_delta: float) -> void:
	var frame: int = Engine.get_physics_frames()
	if frame % _check_every_n != 0:
		return
	
	if _batch_count == 0:
		_batch_start = frame
	
	var values: PackedFloat32Array = PackedFloat32Array()
	for i in _watches:
		values.append(_read(i))
	
	_batch.append_array(values)
	_batch_count += 1

	_check_rules(values, frame)

	if _batch_count >= BATCH_SAMPLES:
		_flush()


func _on_message(message: String, data: Array) -> bool:
	if message == PROTOCOL.CONFIG:
		_apply_config(data)
		return true

	return false


func _apply_config(data: Array) -> void:
	_check_every_n = maxi(1, int(data[0]))
	_watches.clear()

	for i in data[1]:
		_watches.append({"path": i[0], "prop": i[1], "node": null})
	_rules.clear()
	
	for i in data[2]:
		_rules.append({"id": i[0], "series": i[1], "op": i[2], "value": i[3], "action": i[4], "active": false})
	
	_batch = PackedFloat32Array()
	_batch_count = 0

	set_physics_process(not _watches.is_empty())


func _read(watches: Dictionary) -> float:
	var node = watches.node
	if not is_instance_valid(node):
		node = _resolve(watches.path)
		watches.node = node
	
	if node == null:
		return NAN
	
	var value = node.get_indexed(watches.prop)
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return float(value)
		TYPE_BOOL:
			return 1.0 if value else 0.0

	return NAN


func _resolve(path: String) -> Node:
	if path.begins_with("/"):
		return get_node_or_null(path)
	
	var scene := get_tree().current_scene
	
	return scene.get_node_or_null(path) if scene else null


func _check_rules(values: PackedFloat32Array, frame: int) -> void:
	for i in _rules:
		var series: int = i.series
		if series >= values.size() or is_nan(values[series]):
			continue
		
		var value: float = values[series]
		var limit: float = i.value
		var hit: bool = PROTOCOL.compare(value, i.op, limit)

		if hit and not i.active:
			EngineDebugger.send_message(PROTOCOL.MSG_ALARM, [i.id, frame])

			if i.action == "pause":
				_flush()
				EngineDebugger.debug()
		
		i.active = hit


func _flush() -> void:
	if _batch_count == 0:
		return
	
	EngineDebugger.send_message(PROTOCOL.MSG_BATCH, [_batch_start, _check_every_n, _watches.size(), _batch])

	_batch = PackedFloat32Array()
	_batch_count = 0
