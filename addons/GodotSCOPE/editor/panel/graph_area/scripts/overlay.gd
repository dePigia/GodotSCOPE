@tool
extends Control


signal scrubbed(ratio: float)


@export var marker_color: Color = Color("E24B4A")


var _cursor_ratio: float = -1.0
var _marker_ratios: PackedFloat32Array = PackedFloat32Array()
var _marker_nodes: Array[ColorRect] = []


@onready var _cursor_line: ColorRect = $CursorLine


func _ready() -> void:
    resized.connect(_layout)
    _layout()


func set_cursor(ratio: float) -> void:
    _cursor_ratio = ratio
    _layout()


func set_markers(ratios: PackedFloat32Array, tips: PackedStringArray) -> void:
    _marker_ratios = ratios

    while _marker_nodes.size() < ratios.size():
        var marker: ColorRect = ColorRect.new()
        marker.color = marker_color

        marker.mouse_filter = Control.MOUSE_FILTER_PASS
        add_child(marker)
        _marker_nodes.append(marker)
    
    while _marker_nodes.size() > ratios.size():
        var extra: ColorRect = _marker_nodes.pop_back()

        remove_child(extra)
        extra.queue_free()
    
    for i in ratios.size():
        _marker_nodes[i].tooltip_text = tips[i] if i < tips.size() else ""
    
    _layout()


func _gui_input(event: InputEvent) -> void:
    var mouse_x: float = -1.0

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        mouse_x = event.position.x
    elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
        mouse_x = event.position.x
    
    if mouse_x < 0.0 or size.x < 1.0:
        return
    
    scrubbed.emit(clampf(mouse_x / size.x, 0.0, 1.0))


func _layout() -> void:
    if _cursor_line == null:
        return
    
    _cursor_line.visible = _cursor_ratio >= 0.0
    _cursor_line.size.y = size.y
    _cursor_line.position = Vector2(_cursor_ratio * size.x - _cursor_line.size.x * 0.5, 0.0)

    for i in _marker_nodes.size():
        _marker_nodes[i].size = Vector2(3.0, size.y)
        _marker_nodes[i].position = Vector2(_marker_ratios[i] * size.x - 1.5, 0.0)