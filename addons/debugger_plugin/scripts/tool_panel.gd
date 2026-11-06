@tool
extends PanelContainer


signal config_changed


var watches: Array[Dictionary] = []
var rules: Array[Dictionary] = []


var _check_every_n: int = 2
var _live: bool = true
var _picked_path: String = "" 


@onready var hystory_label: Label = $VBoxContainer/HBoxContainer2/HystoryLabel
@onready var hystory_button: Button = $VBoxContainer/HBoxContainer2/HystoryButton
@onready var add_property_button: Button = $VBoxContainer/HBoxContainer/VBoxContainer/AddPropertyButton


func _ready() -> void:
	add_property_button.text = "Add Property"
	hystory_label.text = "LIVE"
	hystory_button.text = "Back To Live"

	add_property_button.pressed.connect(_pick_node)


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


	EditorInterface.popup_property_selector(node, _on_prop_picked)


func _on_prop_picked(prop) -> void:
	var prop_path: String = str(NodePath(prop)).trim_prefix(":")
	if prop_path.is_empty():
		return
	
	watches.append({"path": _picked_path, "prop": prop_path})
	config_changed.emit()


func build_config() -> Array:
	var w: Array = []
	for i in watches:
		w.append([i.path, i.props])


	var r: Array = []
	for i in rules.size():
		r.append([i, rules[i].series, rules[i].op, rules[i].value, rules[i].action])
	
	return [_check_every_n, w, r]
	
