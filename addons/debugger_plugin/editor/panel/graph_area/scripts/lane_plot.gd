@tool
extends Control


@export var line_color: Color = Color("378ADD")
@export var line_width: float = 1.5
@export var grid_color: Color = Color(1, 1, 1, 0.08)


var store
var series_index: int = 0


func _get_samples() -> PackedFloat32Array:
    if store == null or series_index >= store.series.size():
        return PackedFloat32Array()
    
    return store.series[series_index]


func _draw() -> void:
    if size.x < 1.0 or size.y < 1.0:
        return
    
    draw_line(Vector2(0.0, size.y * 0.25), Vector2(size.x, size.y * 0.25), grid_color)
    draw_line(Vector2(0.0, size.y * 0.75), Vector2(size.x, size.y * 0.75), grid_color)

    var samples: PackedFloat32Array = _get_samples()
    var count: int = samples.size()
    if count < 2:
        return
    
    var lo: int = INF
    var hi: int = -INF

    for i in samples:
        if is_nan(i):
            continue
        
        lo = minf(lo, i)
        hi = maxf(hi, i)
    
    if lo == INF:
        return
    if is_equal_approx(lo, hi):
        hi = lo + 1.0
    
    var step: int = maxi(1, int(count / size.x))
    var segment: PackedVector2Array = PackedVector2Array()

    for i in range(0, count, step):
        var value: float = samples[i]

        if is_nan(value):
            _draw_segment(segment)
            segment = PackedVector2Array()
            continue
        
        var x: float = float(i) / float(count - 1) * size.x
        var y: float = size.y - 4.0 - (value - lo) / (hi - lo) * (size.y - 8.0)
        segment.append(Vector2(x, y))
    
    _draw_segment(segment)
        

func _draw_segment(segment: PackedVector2Array) -> void:
    if segment.size() > 1:
        draw_polyline(segment, line_color, line_width, true)
    elif segment.size() == 1:
        draw_circle(segment[0], line_width, line_color)
