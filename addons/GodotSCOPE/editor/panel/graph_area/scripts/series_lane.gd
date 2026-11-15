@tool
extends PanelContainer

@onready var _swatch: ColorRect = $VBoxContainer/HBoxContainer/Swatch
@onready var _name_label: Label = $VBoxContainer/HBoxContainer/NameLabel
@onready var _value_label: Label = $VBoxContainer/HBoxContainer/ValueLabel
@onready var _plot: Control = $VBoxContainer/Plot


func setup(display_name: String, color: Color, store, index: int) -> void:
    _name_label.text = display_name
    _swatch.color = color
    _plot.line_color = color
    _plot.store = store
    _plot.series_index = index
    _value_label.text = "-"
    _plot.queue_redraw()


func show_value(value: float) -> void:
    _value_label.text = "-" if is_nan(value) else str(snappedf(value, 0.01))


func refresh() -> void:
    _plot.queue_redraw()
