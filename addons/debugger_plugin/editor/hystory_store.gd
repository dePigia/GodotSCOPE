@tool
extends RefCounted


var series: Array[PackedFloat32Array] = []
var first_frame: int = -1
var check_every_n: int = 1
var alarms: Array[int] = []


func count() -> int:
    return 0 if series.is_empty() else series[0].size()


func frame_at(sample_index: int) -> int:
    return first_frame + sample_index * check_every_n


func sample_of_frame(frame: int) -> int:
    return int(round((frame - first_frame) / float(check_every_n)))


func append_batch(start_frame: int, step: int, n_series: int, flat: PackedFloat32Array) -> void:
    if n_series != series.size() or n_series == 0:
        return
    
    if first_frame < 0:
        first_frame = start_frame
        check_every_n = step
    
    var missing: int = sample_of_frame(start_frame) - count()
    for i in maxi(missing, 0):
        for j in n_series:
            series[j].append(NAN)
    
    var rows: int = int(flat.size() / float(n_series))
    for i in rows:
        for j in n_series:
            series[j].append(flat[i * n_series + j])


func reset(n_series: int) -> void:
    series.clear()

    for i in n_series:
        series.append(PackedFloat32Array())
    
    alarms.clear()
    first_frame = -1
