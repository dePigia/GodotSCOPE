@tool
extends VBoxContainer


signal cursor_changed(index: int)


const COLORS: Array[Color] = [Color("378ADD"), Color("BA7517"), Color("1D9E75"), Color("D4537E")]


@export var lane_scene: PackedScene = preload("res://addons/GodotSCOPE/editor/panel/graph_area/scenes/series_lane.tscn")


var _store
var _cursor: int = -1


@onready var _lanes: VBoxContainer = $MarginContainer/Lanes
@onready var _overlay: Control = $MarginContainer/Overlay
@onready var _time_axis: Control = $TimeAxis


func _ready() -> void:
    _overlay.scrubbed.connect(_on_scrubbed)
    _time_axis.resized.connect(_layout_axis)

    _layout_axis()


func set_watches(store, names: Array) -> void:
    _store = store

    for i in _lanes.get_children():
        _lanes.remove_child(i)
        i.queue_free()
    
    for i in names.size():
        var lane: Control = lane_scene.instantiate()
        _lanes.add_child(lane)

        lane.setup(str(names[i]), COLORS[i % COLORS.size()], store, i)
        lane.size_flags_vertical = Control.SIZE_EXPAND_FILL
    
    _cursor = -1
    refresh()


func refresh() -> void:
    if _store == null:
        return
    
    for i in _lanes.get_children():
        i.refresh()
    
    var count: int = _store.count()

    var ratios: PackedFloat32Array = PackedFloat32Array()
    var tips: PackedStringArray = PackedStringArray()

    if count > 1:
        for i in _store.alarms:
            var sample: int = _store.sample_of_frame(i)

            ratios.append(clampf(float(sample) / float(count - 1), 0.0, 1.0))
            tips.append("Alarm at frame %d" % i)
    
    _overlay.set_markers(ratios, tips)

    _update_cursor(count)
    _update_axis(count)


func go_live() -> void:
    _cursor = -1

    cursor_changed.emit(-1)
    refresh()


func show_cursor_at(sample_index: int) -> void:
    _cursor = sample_index

    refresh()


func set_lane_visible(index: int, lane_visible: bool) -> void:
    var lanes: Array[Node] = _lanes.get_children()
    if index >= 0 and index < lanes.size():
        lanes[index].visible = lane_visible


func _on_scrubbed(ratio: float) -> void:
    if _store == null:
        return

    var count: int = _store.count() if _store else 0

    if count < 2:
        return
    
    _cursor = int(round(ratio * (count - 1)))
    cursor_changed.emit(_cursor)

    refresh()


func _update_cursor(count: int) -> void:
    if count < 1:
        _overlay.set_cursor(-1.0)

        return
    
    var index: int = count - 1 if _cursor < 0 else mini(_cursor, count - 1)
    _overlay.set_cursor(-1.0 if _cursor < 0 else float(index) / float(maxi(count - 1, 1)))

    var lanes: Array[Node] = _lanes.get_children()
    for i in mini(lanes.size(), _store.series.size()):
        lanes[i].show_value(_store.series[i][index])


func _update_axis(count: int) -> void:
    var ticks: float = ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60)
    var total_seconds: float = count * _store.check_every_n / ticks
    var labels: Array[Node] = _time_axis.get_children()

    for i in labels.size():
        labels[i].text = "%.1f s" % (total_seconds * i / maxf(labels.size() - 1.0, 1.0))
    
    _layout_axis()


func _layout_axis() -> void:
    var labels: Array[Node] = _time_axis.get_children()
    var steps: float = maxf(labels.size() -1.0, 1.0)

    for i: int in labels.size():
        var label: Label = labels[i]
        var tick_x: float = _time_axis.size.x * i / steps
        var width: float = label.get_minimum_size().x

        label.position = Vector2(clampf(tick_x - width * 0.5, 0.0, maxf(_time_axis.size.x - width, 0.0)), 0.0)