@tool
extends ConfirmationDialog


signal rule_confirmed(series: int, op: String, value: float, action: String)


const PROTOCOL: Script = preload("res://addons/GodotSCOPE/protocol.gd")
const ACTIONS: Array[String] = ["mark", "pause"]


@onready var _property_option: OptionButton = $VBoxContainer/GridContainer/PropertyOption
@onready var _operator_option: OptionButton = $VBoxContainer/GridContainer/OperatorOption
@onready var _value_spin: SpinBox = $VBoxContainer/GridContainer/ValueSpin
@onready var _action_option: OptionButton = $VBoxContainer/GridContainer/ActionOption


func _ready() -> void:
    confirmed.connect(_on_confirmed)

    _operator_option.clear()
    for i in PROTOCOL.OPERATOR_LABELS.size():
        _operator_option.add_item(PROTOCOL.OPERATOR_LABELS[i])


func open(names: Array, preselect: int = -1) -> void:
    _property_option.clear()

    for i in names:
        _property_option.add_item(str(i))

    if names.size() > 0:
        _property_option.select(preselect if preselect >= 0 else names.size() - 1)
    
    popup_centered()


func _on_confirmed() -> void:
    var series: int = _property_option.selected
    if series < 0:
        return
    
    rule_confirmed.emit(series, PROTOCOL.OPERATORS[_operator_option.selected], _value_spin.value, ACTIONS[_action_option.selected])