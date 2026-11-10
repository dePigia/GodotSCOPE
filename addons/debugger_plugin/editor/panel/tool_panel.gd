@tool
extends PanelContainer


signal config_changed


const HYSTORY_STORE: Script = preload("res://addons/debugger_plugin/editor/hystory_store.gd")

const PROPERTY_TYPES: PackedInt32Array = [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR]
const SETTING_SECTION: String = "debugger_plugin"
const SETTING_SPLIT: String = "split_offset"


var watches: Array[Dictionary] = []
var rules: Array[Dictionary] = []


var _check_every_n: int = 2
var _live: bool = true
var _picked_path: String = ""


@onready var hystory_label: Label = $VBoxContainer/HBoxContainer2/HystoryLabel
@onready var hystory_button: Button = $VBoxContainer/HBoxContainer2/HystoryButton
@onready var add_property_button: Button = $VBoxContainer/HSplitContainer/VBoxContainer/AddPropertyButton
@onready var tree: Tree = $VBoxContainer/HSplitContainer/VBoxContainer/PropertyTree
@onready var split: HSplitContainer = $VBoxContainer/HSplitContainer
@onready var graph: VBoxContainer = $VBoxContainer/HSplitContainer/GraphArea


func _ready() -> void:
	add_property_button.text = "Add Property"
	hystory_label.text = "LIVE"
	hystory_button.text = "Back To Live"

	add_property_button.pressed.connect(_pick_node)

	tree.watch_toggled.connect(_on_watch_toggled)
	tree.watch_removed.connect(_on_watch_removed)

	var settings: EditorSettings = EditorInterface.get_editor_settings()
	split.split_offset = int(settings.get_project_metadata(SETTING_SECTION, SETTING_SPLIT, 0))
	split.drag_ended.connect(_on_split_drag_ended)


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
		
		watches.append({"path": _picked_path, "prop": i})
		added = true
	
	if added:
		_refresh_tree()
		config_changed.emit()


func build_config() -> Array:
	var w: Array = []
	for i in watches:
		w.append([i.path, i.prop])

	var r: Array = []
	for i in rules.size():
		r.append([i, rules[i].series, rules[i].op, rules[i].value, rules[i].action])
	
	return [_check_every_n, w, r]


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


func _on_watch_toggled(index: int, enabled: bool) -> void:
	if index < 0 or index >= watches.size():
		return
	
	watches[index]["enabled"] = enabled


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
	_refresh_tree.call_deferred()


func _refresh_tree() -> void:
	tree.set_watches(watches)


func _on_split_drag_ended() -> void:
	EditorInterface.get_editor_settings().set_project_metadata(SETTING_SECTION, SETTING_SPLIT, split.split_offset)


func _rebuild_graph() -> void:
	HYSTORY_STORE.reset(watches.size())

	var names: Array = watches.map(func(w): return "%s.%s" % [w.path, w.prop])
	graph.set_watches(HYSTORY_STORE, names)


func add_batch(start_frame: int, step: int, n_series: int, flat: PackedFloat32Array) -> void:
	HYSTORY_STORE.append_batch(start_frame, step, n_series, flat)
	graph.refresh()
