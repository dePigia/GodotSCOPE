@tool
extends PanelContainer


signal config_changed


const HISTORY_STORE: Script = preload("res://addons/GodotSCOPE/editor/history_store.gd")
const ALARM_DIALOG: PackedScene = preload("res://addons/GodotSCOPE/editor/alarm/alarm_dialog.tscn")

const PROPERTY_TYPES: PackedInt32Array = [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR]
const SETTING_SECTION: String = "debugger_plugin"
const SETTING_SPLIT: String = "split_offset"


var watches: Array[Dictionary] = []
var rules: Array[Dictionary] = []
var store: HISTORY_STORE = HISTORY_STORE.new()


var _check_every_n: int = 2
var _picked_path: String = ""
var _picked_class: String = "Node"

var _running: bool = false
var _paused: bool = false
var _live: bool = true
var _cursor_index: int = -1

var _alarm_dialog: ConfirmationDialog


@onready var history_label: Label = $VBoxContainer/HBoxContainer2/HistoryLabel
@onready var history_button: Button = $VBoxContainer/HBoxContainer2/HistoryButton
@onready var add_property_button: Button = $VBoxContainer/HSplitContainer/VBoxContainer/HBoxContainer/AddPropertyButton
@onready var add_alarm_button: Button = $VBoxContainer/HSplitContainer/VBoxContainer/HBoxContainer/AddAlarmButton
@onready var tree: Tree = $VBoxContainer/HSplitContainer/VBoxContainer/PropertyTree
@onready var split: HSplitContainer = $VBoxContainer/HSplitContainer
@onready var graph: VBoxContainer = $VBoxContainer/HSplitContainer/GraphArea


func _ready() -> void:
	add_property_button.text = "Add Property"
	history_button.text = "Back To Live"
	_update_label()

	add_property_button.pressed.connect(_pick_node)
	add_alarm_button.pressed.connect(_on_add_alarm_button_pressed)

	history_button.pressed.connect(_go_live)

	tree.watch_toggled.connect(_on_watch_toggled)
	tree.watch_removed.connect(_on_watch_removed)
	graph.cursor_changed.connect(_on_cursor_changed)

	var settings: EditorSettings = EditorInterface.get_editor_settings()
	split.split_offset = int(settings.get_project_metadata(SETTING_SECTION, SETTING_SPLIT, 0))
	split.drag_ended.connect(_on_split_drag_ended)


func begin_run() -> void:
	_running = true
	_paused = false
	_live = true

	_rebuild_graph()
	_refresh_tree.call_deferred()
	_update_label()


func end_run() -> void:
	_running = false

	_update_label()


func on_breaked() -> void:
	_paused = true
	_live = false

	var last: int = store.count() - 1
	if last >= 0:
		_cursor_index = last
		graph.show_cursor_at(last)

		_update_tree_values()
	
	_update_label()


func on_continued() -> void:
	_paused = false

	_go_live()


func build_config() -> Array:
	var w: Array = []
	for i in watches:
		w.append([i.path, i.prop])

	var r: Array = []
	for i in rules.size():
		r.append([i, rules[i].series, rules[i].op, rules[i].value, rules[i].action])
	
	return [_check_every_n, w, r]


func add_rule(series: int, op: String, value: float, action: String = "pause") -> void:
	rules.append({"series": series, "op": op, "value": value, "action": action})
	
	config_changed.emit()


func add_batch(start_frame: int, step: int, n_series: int, flat: PackedFloat32Array) -> void:
	store.append_batch(start_frame, step, n_series, flat)
	graph.refresh()

	_update_tree_values()


func add_alarm(_rule_id: int, frame: int) -> void:
	store.alarms.append(frame)

	graph.refresh()


func clear_rules() -> void:
	rules.clear()
	
	config_changed.emit()


func _pick_node() -> void:
	EditorInterface.popup_node_selector(_on_node_picked)


func _on_node_picked(path) -> void:
	var node_path: NodePath = NodePath(path)
	if node_path.is_empty():
		return
	
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return
	
	var node := root.get_node_or_null(node_path)
	if node == null:
		return
	
	_picked_path = str(root.get_path_to(node))
	_picked_class = node.get_class()

	EditorInterface.popup_property_selector(node, _on_prop_picked, PROPERTY_TYPES)


func _on_prop_picked(prop) -> void:
	var prop_path: String = str(NodePath(prop)).trim_prefix(":")
	if prop_path.is_empty():
		return
	
	var root: Node = EditorInterface.get_edited_scene_root()
	var node: Node = root.get_node_or_null(_picked_path) if root else null

	var added: bool = false

	for i in _split_components(node, prop_path):
		if _has_swatch(_picked_path, i):
			continue
		
		watches.append({"path": _picked_path, "prop": i, "class": _picked_class, "enabled": true})
		added = true
	
	if added:
		_on_watches_changed()


func _split_components(node: Node, prop_path: String) -> Array[String]:
	if node == null:
		return [prop_path]
	
	match typeof(node.get_indexed(prop_path)):
		TYPE_VECTOR2:
			return [prop_path + ":x", prop_path + ":y"]
		TYPE_VECTOR3:
			return [prop_path + ":x", prop_path + ":y", prop_path + ":z"]
		TYPE_COLOR:
			return [prop_path + ":r", prop_path + ":g", prop_path + ":b", prop_path + ":a"]

	return [prop_path]


func _has_swatch(path: String, prop: String) -> bool:
	for i in watches:
		if i.path == path and i.prop == prop:
			return true

	return false


func _on_watches_changed() -> void:
	_rebuild_graph()
	_refresh_tree.call_deferred()

	config_changed.emit()


func _on_watch_toggled(index: int, enabled: bool) -> void:
	if index < 0 or index >= watches.size():
		return
	
	watches[index]["enabled"] = enabled
	graph.set_lane_visible(index, enabled)


func _on_watch_removed(index: int) -> void:
	if index < 0 or index >= watches.size():
		return
	
	watches.remove_at(index)

	var kept: Array[Dictionary] = []
	for i in rules:
		if i.series == index:
			continue
		if i.series > index:
			i.series -= 1
		
		kept.append(i)
	
	rules = kept
	_on_watches_changed()


func _refresh_tree() -> void:
	tree.set_watches(watches)

	_update_tree_values()


func _on_split_drag_ended() -> void:
	EditorInterface.get_editor_settings().set_project_metadata(SETTING_SECTION, SETTING_SPLIT, split.split_offset)


func _rebuild_graph() -> void:
	store.reset(watches.size())
	_cursor_index = -1

	var names: Array = watches.map(func(w): return "%s.%s" % [w.path, w.prop])
	graph.set_watches(store, names)

	for i in watches.size():
		graph.set_lane_visible(i, watches[i].get("enabled", true))


func _update_tree_values() -> void:
	var count: int = store.count()
	if count == 0:
		return
	
	var index: int = count - 1 if _cursor_index < 0 else mini(_cursor_index, count - 1)
	for i in mini(watches.size(), store.series.size()):
		var value: float = store.series[i][index]
		tree.set_value(i, "-" if is_nan(value) else str(snappedf(value, 0.01)))


func _go_live() -> void:
	graph.go_live()


func _on_cursor_changed(index: int) -> void:
	_cursor_index = index
	_live = index < 0

	_update_tree_values()
	_update_label()


func _update_label() -> void:
	if not _running:
		history_label.text = "STOPPED"
	elif _paused:
		history_label.text = "PAUSED"
	elif _live:
		history_label.text = "LIVE"
	else:
		history_label.text = "HISTORY"
	
	history_button.visible = not _live


func _on_add_alarm_button_pressed() -> void:
	if watches.is_empty():
		EditorInterface.get_editor_toaster().push_toast("Add a property first.", EditorToaster.SEVERITY_WARNING)
		return
	
	if _alarm_dialog == null:
		_alarm_dialog = ALARM_DIALOG.instantiate()
		add_child(_alarm_dialog)

		_alarm_dialog.rule_confirmed.connect(add_rule)
	
	_alarm_dialog.open(_watch_names())
	

func _watch_names() -> Array:
	return watches.map(func(w) -> String: return "%s.%s" % [w.path, w.prop])
